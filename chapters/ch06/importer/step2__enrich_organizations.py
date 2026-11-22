import sys
import json
import os
import time
from collections import Counter
from pathlib import Path
from urllib.parse import quote

import requests

from util.base_importer import BaseImporter
from tenacity import retry, retry_if_exception, wait_exponential, stop_after_attempt


cache_stats = Counter()


def cache_directory(name: str) -> Path:
    return Path(os.environ.get("CH6_CACHE_ROOT", "../../data")) / name


def retryable_wikidata_error(error):
    if isinstance(error, (requests.ConnectionError, requests.Timeout)):
        return True
    return isinstance(error, requests.HTTPError) and error.response is not None and (
        error.response.status_code == 429 or error.response.status_code >= 500
    )


@retry(retry=retry_if_exception(retryable_wikidata_error),
       stop=stop_after_attempt(4), wait=wait_exponential(multiplier=1, max=10),
       reraise=True)
def request_wikidata(query: str):
    try:
        response = requests.get(
            "https://query.wikidata.org/bigdata/namespace/wdq/sparql",
            params={"query": query, "format": "json"},
            headers={"User-Agent": "KGsLLMsChapter6/1.0 (educational graph import)"},
            timeout=30,
        )
        response.raise_for_status()
        return response.json()["results"]["bindings"]
    finally:
        time.sleep(1)


def query_wikidata_entity(query: str, entity: str, cache_folder: Path = None,
                          query_entity: str = None):
    filename = quote(entity.replace(" ", "_").lower(), safe="") + ".json"
    cache_file = cache_folder / filename if cache_folder is not None else None
    if cache_file is not None and cache_file.is_file():
        with cache_file.open(encoding="utf-8") as file:
            results = json.load(file)
        if not isinstance(results, list):
            raise ValueError(f"Invalid Wikidata cache format: {cache_file}")
        cache_stats["hits"] += 1
        if not results:
            cache_stats["empty"] += 1
        return results

    cache_stats["misses"] += 1
    try:
        results = request_wikidata(query % (query_entity if query_entity is not None else entity))
    except (requests.RequestException, ValueError, KeyError) as error:
        cache_stats["failures"] += 1
        raise RuntimeError(f"Wikidata lookup failed for {entity!r}") from error
    if not isinstance(results, list):
        cache_stats["failures"] += 1
        raise ValueError(f"Invalid Wikidata bindings for {entity!r}")
    if cache_file is not None:
        with cache_file.open("w", encoding="utf-8") as file:
            json.dump(results, file)
    if not results:
        cache_stats["empty"] += 1
    return results


class OrgEnricher(BaseImporter):
    def __init__(self, argv):
        super().__init__(command=__file__, argv=argv)
        #self._database = "news"
        self.cachePath = None

        self.QUERY_GET_INPUTS = """
        MATCH (n:Document)-[:MENTIONS_ORGANIZATION]->(e:Organization)
        WITH e, count(*) AS c
        WHERE c > 4
        RETURN id(e) AS id, e.name AS name
        """

        self.QUERY_STORE_RESULTS = """
        MATCH (n)
        WHERE id(n) = $input.id
        SET n.description = $input.description,
        n.wikidata_id = $input.wikidata_id,
        n.wikidata_url = $input.wikidata_url
    
        WITH n 
    
        FOREACH(entity IN $input.subsidiary |
            MERGE (e:Organization {name: entity})
            MERGE (n)-[:HAS_SUBSIDIARY]->(e)
        )
    
        FOREACH(entity IN $input.member_of |
            MERGE (e:Organization {name: entity})
            MERGE (n)-[:MEMBER_OF]->(e)
        )
    
        FOREACH(entity IN $input.industry |
            MERGE (e:Industry {name: entity})
            MERGE (n)-[:IN_INDUSTRY]->(e)
        )
        """

    def get_wikidata(self, entity: str):
        SPARQL = """
        SELECT ?org ?orgLabel ?desc  
               (group_concat(distinct ?subsidiaryLabel;separator=";") as ?subsidiaries)  
               (group_concat(distinct ?member_ofLabel;separator=";") as ?members)  
               (group_concat(distinct ?industryLabel;separator=";") as $industries)
        WHERE {{?org wdt:P31/wdt:P279* wd:Q4830453 .}
         UNION
         {?org     wdt:P31/wdt:P279*  wd:Q43229 .}
         ?org      rdfs:label '%s'@en .
         ?org schema:description ?desc .
         OPTIONAL {?org        wdt:P17 ?country . }
         OPTIONAL {?org        wdt:P355 ?subsidiary . }
         OPTIONAL {?org        wdt:P452 ?industry . }
         OPTIONAL {?org        wdt:P1813 ?short_name . }
         OPTIONAL {?org        wdt:P463 ?member_of . }
         FILTER(LANG(?desc) = "en")
         SERVICE wikibase:label { 
           bd:serviceParam wikibase:language "en".
           ?org rdfs:label ?orgLabel.
           ?subsidiary rdfs:label ?subsidiaryLabel.
           ?industry rdfs:label ?industryLabel.
           ?member_of rdfs:label ?member_ofLabel.
         }
        }
        GROUP BY ?org ?orgLabel ?desc
        """

        escaped = entity.replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n").replace("\r", "\\r")
        results = query_wikidata_entity(SPARQL, entity, self.cachePath, query_entity=escaped)

        final_res = {'name': results[0]['orgLabel']['value'],
                     'wikidata_url': results[0]['org']['value'],
                     'wikidata_id': results[0]['org']['value'].split("/")[-1].strip(),
                     'description': results[0]['desc']['value'],
                     'subsidiary': sorted({x.strip() for x in results[0]['subsidiaries']['value'].split(";") if x.strip()}),
                     'member_of': sorted({x.strip() for x in results[0]['members']['value'].split(";") if x.strip()}),
                     'industry': sorted({x.strip() for x in results[0]['industries']['value'].split(";") if x.strip()}),
                     } if len(results) > 0 else dict()

        return final_res

    def run(self):
        # Run enrichment
        with self._driver.session(database=self._database) as session:
            # Get entities to enrich
            entities = session.run(self.QUERY_GET_INPUTS).data()
            print(f"Retrieved {len(entities)} entities")

            print("Retrieving wikidata info for entity:")
            for en in entities:
                print(en['name'])
                wiki = self.get_wikidata(en['name'])
                # time.sleep(1)  # to avoid exception about too many requests
                if len(wiki) == 0:
                    # print("  Nothing found.")
                    continue
                wiki['id'] = en['id']
                session.run(self.QUERY_STORE_RESULTS, input=wiki)
                print("  STORED!")


if __name__ == "__main__":
    enricher = OrgEnricher(argv=sys.argv[1:])

    # set up a cache folder for wikidata responses
    enricher.cachePath = cache_directory("cache_org")
    enricher.cachePath.mkdir(parents=True, exist_ok=True)

    try:
        enricher.run()
    finally:
        print(f"Wikidata cache: {cache_stats['hits']} hits, {cache_stats['misses']} misses, "
              f"{cache_stats['empty']} empty results, {cache_stats['failures']} failed lookups")
        enricher.close()
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock, patch

IMPORTER_DIR = Path(__file__).resolve().parents[1] / "chapters" / "ch06" / "importer"
sys.path.insert(0, str(IMPORTER_DIR))

import step1__import_bbc as bbc
import step2__enrich_organizations as org
import step3__enrich_by_ownerships as ownership


class Chapter6ImportTests(unittest.TestCase):
    def setUp(self):
        org.cache_stats.clear()

    def test_cached_and_missing_wikidata_results(self):
        with tempfile.TemporaryDirectory() as directory:
            cache = Path(directory)
            (cache / "example.json").write_text('[{"item": 1}]', encoding="utf-8")
            with patch.object(org, "request_wikidata", return_value=[]) as request:
                self.assertEqual(org.query_wikidata_entity("SELECT %s", "Example", cache),
                                 [{"item": 1}])
                self.assertEqual(org.query_wikidata_entity("SELECT %s", "Other", cache), [])
                request.assert_called_once_with("SELECT Other")
            self.assertEqual(json.loads((cache / "other.json").read_text()), [])
            self.assertEqual(org.cache_stats["hits"], 1)
            self.assertEqual(org.cache_stats["misses"], 1)
            self.assertEqual(org.cache_stats["empty"], 1)

    def test_wikidata_failure_is_not_cached(self):
        with tempfile.TemporaryDirectory() as directory:
            cache = Path(directory)
            with patch.object(org, "request_wikidata", side_effect=org.requests.Timeout):
                with self.assertRaisesRegex(RuntimeError, "Wikidata lookup failed"):
                    org.query_wikidata_entity("SELECT %s", "Example", cache)
            self.assertFalse((cache / "example.json").exists())
            self.assertEqual(org.cache_stats["failures"], 1)

    def test_rate_limit_is_retried(self):
        limited = Mock(status_code=429)
        limited.raise_for_status.side_effect = org.requests.HTTPError(response=limited)
        success = Mock(status_code=200)
        success.json.return_value = {"results": {"bindings": []}}
        with patch.object(org.requests, "get", side_effect=[limited, success]) as get, \
                patch.object(org.time, "sleep"), patch.object(org.request_wikidata.retry, "sleep"):
            self.assertEqual(org.request_wikidata("SELECT * {}"), [])
        self.assertEqual(get.call_count, 2)

    def test_organization_name_is_escaped_without_changing_cache_key(self):
        enricher = org.OrgEnricher.__new__(org.OrgEnricher)
        enricher.cachePath = Path("/cache")
        with patch.object(org, "query_wikidata_entity", return_value=[]) as query:
            self.assertEqual(enricher.get_wikidata("O'Reilly"), {})
        self.assertEqual(query.call_args.args[1], "O'Reilly")
        self.assertEqual(query.call_args.kwargs["query_entity"], "O\\'Reilly")

    def test_empty_wikidata_groups_do_not_create_empty_entities(self):
        enricher = org.OrgEnricher.__new__(org.OrgEnricher)
        enricher.cachePath = Path("/cache")
        row = {"orgLabel": {"value": "Acme"}, "org": {"value": "https://www.wikidata.org/entity/Q1"},
               "desc": {"value": "Company"}, "subsidiaries": {"value": ""},
               "members": {"value": "; "}, "industries": {"value": "Retail;;Retail"}}
        with patch.object(org, "query_wikidata_entity", return_value=[row]):
            result = enricher.get_wikidata("Acme")
        self.assertEqual(result["subsidiary"], [])
        self.assertEqual(result["member_of"], [])
        self.assertEqual(result["industry"], ["Retail"])

    def test_owner_types_use_binding_value_and_deduplicate(self):
        rows = [
            {"owned_by": {"value": "http://www.wikidata.org/entity/Q1"},
             "owned_byLabel": {"value": "Alice"},
             "owner_instance_of": {"value": "http://www.wikidata.org/entity/Q5"}},
            {"owned_by": {"value": "http://www.wikidata.org/entity/Q1"},
             "owned_byLabel": {"value": "Alice"},
             "owner_instance_of": {"value": "http://www.wikidata.org/entity/Q123"}},
            {"owned_by": {"value": "http://www.wikidata.org/entity/Q2"},
             "owned_byLabel": {"value": "Acme"},
             "owner_instance_of": {"value": "http://www.wikidata.org/entity/Q4830453"}},
        ]
        enricher = ownership.OwnershipEnricher.__new__(ownership.OwnershipEnricher)
        enricher.cache_folder = None
        with patch.object(ownership, "query_wikidata_entity", return_value=rows):
            result = enricher.get_onwers_with_type({"id": 7, "wikidata_id": "Q42"})
        self.assertEqual(result, {"id": 7, "owned_by_org": ["Acme"], "owned_by_per": ["Alice"]})

    def test_latin1_article_is_imported_with_original_text(self):
        with tempfile.TemporaryDirectory() as directory:
            topic = Path(directory) / "sport"
            topic.mkdir()
            (topic / "199.txt").write_bytes(b"Title\n\nA \xa315 fee\n")
            importer = bbc.BBCImporter.__new__(bbc.BBCImporter)
            importer.enrich_document = lambda document: None
            result = list(importer.get_documents(Path(directory)))
        self.assertEqual(result[0]["text"], "A £15 fee")


if __name__ == "__main__":
    unittest.main()

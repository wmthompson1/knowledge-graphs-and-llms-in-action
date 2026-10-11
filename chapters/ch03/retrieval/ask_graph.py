"""Question -> Cypher -> answer over the manufacturing graph, using GitHub Models (GitHub token auth).

Usage: python retrieval/ask_graph.py "Which suppliers have open major nonconformances?"
Env: GITHUB_TOKEN (falls back to `gh auth token`), GITHUB_MODEL (default openai/gpt-4.1)
"""
import configparser
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request

from neo4j import GraphDatabase

ENDPOINT = "https://models.github.ai/inference/chat/completions"
MODEL = os.environ.get("GITHUB_MODEL", "openai/gpt-4.1")
WRITE_KEYWORDS = re.compile(r"\b(CREATE|MERGE|DELETE|DETACH|SET|REMOVE|DROP|LOAD|FOREACH|CALL)\b", re.I)


def token() -> str:
    t = os.environ.get("GITHUB_TOKEN") or subprocess.run(
        ["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
    if not t:
        sys.exit("No GitHub token: set GITHUB_TOKEN or run `gh auth login`.")
    return t


def chat(messages, tok):
    req = urllib.request.Request(
        ENDPOINT, data=json.dumps({"model": MODEL, "messages": messages, "temperature": 0}).encode(),
        headers={"Authorization": f"Bearer {tok}", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            body = r.read().decode()
        return json.loads(body)["choices"][0]["message"]["content"]
    except urllib.error.HTTPError as e:
        sys.exit(f"GitHub Models HTTP {e.code}: {e.read().decode()[:300]} (token needs the models:read scope)")
    except (json.JSONDecodeError, KeyError):
        sys.exit(f"Unexpected response from GitHub Models: {body[:200]!r}")


def schema(session) -> str:
    rels = session.run(
        "MATCH (a)-[r]->(b) WHERE NOT a:Class AND NOT a:Resource OR a:Resource AND NOT a:Class "
        "WITH [l IN labels(a) WHERE l <> 'Resource'][0] AS a, type(r) AS r, [l IN labels(b) WHERE l <> 'Resource'][0] AS b "
        "RETURN DISTINCT a, r, b ORDER BY a, r").data()
    props = session.run(
        "MATCH (n:Resource) WHERE NOT n:Class AND NOT n:ObjectProperty AND NOT n:DatatypeProperty AND NOT n:Ontology "
        "UNWIND [l IN labels(n) WHERE l <> 'Resource'] AS l UNWIND keys(n) AS k "
        "RETURN l, collect(DISTINCT k) AS keys ORDER BY l").data()
    return ("Relationships:\n" + "\n".join(f"(:{x['a']})-[:{x['r']}]->(:{x['b']})" for x in rels if x['a'] and x['b'])
            + "\nNode properties:\n" + "\n".join(f"{x['l']}: {x['keys']}" for x in props))


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    question = sys.argv[1]
    cfg = configparser.ConfigParser()
    cfg.read(os.path.join(os.path.dirname(__file__), "..", "..", "..", "config.ini"))
    c = cfg["neo4j"]
    tok = token()
    with GraphDatabase.driver(c["uri"], auth=(c["user"], c["password"])).session(database="neo4j") as s:
        sch = schema(s)
        cypher = chat([
            {"role": "system", "content": "You write read-only Neo4j 4.4 Cypher. Use only this schema. "
             "Return ONLY the query, no markdown, no explanation. Always add LIMIT 50.\n" + sch},
            {"role": "user", "content": question}], tok)
        cypher = re.sub(r"^```\w*|```$", "", cypher.strip(), flags=re.M).strip()
        print(f"Cypher:\n{cypher}\n")
        if WRITE_KEYWORDS.search(cypher):
            sys.exit("Refusing to run a query containing write/procedure keywords.")
        rows = s.run(cypher).data()
        print(f"{len(rows)} row(s)")
        print(chat([
            {"role": "system", "content": "Answer the question using only the provided query results. Be concise."},
            {"role": "user", "content": f"Question: {question}\nResults: {json.dumps(rows, default=str)[:12000]}"}], tok))


if __name__ == "__main__":
    main()

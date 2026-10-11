"""Turn a built KB into an agent-ready retrieval pack (agent/kb_pack.json)."""
import argparse
import json
from pathlib import Path


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--kb", type=Path, required=True)
    ap.add_argument("--agent", type=Path, required=True)
    a = ap.parse_args()

    manifest = json.loads((a.kb / "kb_manifest.json").read_text())
    slices = json.loads((a.kb / "semantic_slices.json").read_text())
    pack = {
        "slices": slices,
        "sources": manifest["sources"],
        "notes": "Zero-trust KB pack: ontology structure and synthetic data only.",
    }
    a.agent.mkdir(parents=True, exist_ok=True)
    out = a.agent / "kb_pack.json"
    out.write_text(json.dumps(pack, indent=2))
    print("Agent KB pack written:", out)


if __name__ == "__main__":
    main()

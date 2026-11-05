"""Rebuild the RDF comparison between ontology versions.

Run from anywhere inside the repository (requires rdflib; see requirements.txt):

    python tools/audit/compare_versions.py [output_dir]

Output (default: build/ontology-diffs/, git-ignored):
  metadata.json            triple count and ontology-header metadata per file
  <a>--<b>.md              added/removed entities per consecutive pair
  <a>--<b>.added.nt        added triples        <a>--<b>.removed.nt   removed triples
  README.md                summary table

Blank nodes are compared isomorphically. This is not an OWL equivalence or
consistency check and does not run a reasoner.
"""
import json
import sys
from pathlib import Path

from rdflib import Graph, RDF, OWL, URIRef
from rdflib.compare import graph_diff, to_isomorphic

root = Path(__file__).resolve().parents[2]
files = [p for p in (root / "ontology/archive").iterdir() if p.suffix in (".owl", ".rdf")]
files.append(root / "ontology/ontoiochem.owl")
graphs = {p.name: Graph().parse(p, format="xml") for p in files}

out = Path(sys.argv[1]) if len(sys.argv) > 1 else root / "build/ontology-diffs"
out.mkdir(parents=True, exist_ok=True)

meta = {}
for name, g in graphs.items():
    meta[name] = {
        "triples": len(g),
        "ontology_metadata": {
            str(s): {str(p): sorted(str(o) for o in g.objects(s, p)) for p in set(g.predicates(s))}
            for s in g.subjects(RDF.type, OWL.Ontology)
        },
    }
(out / "metadata.json").write_text(json.dumps(meta, indent=2, ensure_ascii=False))

# Comparison order follows the version numbers in the file names; it is not proof of chronology.
seq = ["onto_iochem_v2.owl", "onto_iochem_v3.owl", "ontoiochem_v4.owl", "ontoiochem_v6.owl",
       "ontoiochem_v8.owl", "ontoiochem_v9.rdf", "ontoiochem_v10.owl", "ontoiochem.owl"]
lines = [
    "# Comparisons between versions\n",
    "See docs/ontology-version-comparison.md for caveats. Differences are observed changes, not necessarily "
    "improvements; they are not proof of OWL equivalence nor reasoner validation.\n",
    "| Comparison | Triples removed | Triples added |",
    "|---|---:|---:|",
]
for a, b in zip(seq, seq[1:]):
    ga, gb = graphs[a], graphs[b]
    _, removed, added = graph_diff(to_isomorphic(ga), to_isomorphic(gb))
    stem = a.rsplit(".", 1)[0] + "--" + b.rsplit(".", 1)[0]
    for label, g in [("removed", removed), ("added", added)]:
        (out / f"{stem}.{label}.nt").write_text("\n".join(sorted(g.serialize(format="nt").splitlines())) + "\n")
    lines.append(f"| {a} -> {b} | {len(removed)} | {len(added)} |")
    detail = [f"# {a} -> {b}\n"]
    for label, typ in [("Classes", OWL.Class), ("Object properties", OWL.ObjectProperty),
                       ("Datatype properties", OWL.DatatypeProperty), ("Individuals", OWL.NamedIndividual)]:
        sa = {str(x) for x in ga.subjects(RDF.type, typ) if isinstance(x, URIRef)}
        sb = {str(x) for x in gb.subjects(RDF.type, typ) if isinstance(x, URIRef)}
        detail += [f"## {label}\n", "Added:\n"] + ["- `" + x + "`" for x in sorted(sb - sa)]
        detail += ["\nRemoved:\n"] + ["- `" + x + "`" for x in sorted(sa - sb)]
    (out / f"{stem}.md").write_text("\n".join(detail))
(out / "README.md").write_text("\n".join(lines) + "\n")
print("\n".join(lines))

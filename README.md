# Ontoiochem

A minimum viable ontology for the semantic layer of [ioChem-BD](https://www.iochem-bd.org/), together with the mapping workbook, concept map and scripts used to build it. The ontology provides a common vocabulary for describing computational chemistry data (composition, methodology, computed quantities, publication metadata) so that calculations can be found by scientific questions.

> **Status:** `ontology/ontoiochem.owl` is v11 (declares `versionInfo` 0.8.0). It is a working starting point, **not a validated release**: it has been parsed as RDF/XML, but no reasoner (e.g. HermiT) has been run and the competency questions have not been executed against a populated graph.

## Repository layout

| Path | Content |
|---|---|
| `ontology/ontoiochem.owl` | Current ontology (v11), RDF/XML |
| `ontology/archive/` | Earlier versions, kept as received; see its [README](ontology/archive/README.md) |
| `docs/manual.md` | Manual: rationale, tag mapping, classes and properties, validation, implementation requirements |
| `docs/sparql-search-questions.md` | Ten scientific search questions with SPARQL templates (not yet executed against ioChem-BD) |
| `docs/ontology-version-comparison.md` | Triple-level comparison v2 → v11 |
| `docs/tag-explorer-audit.md` | Static audit of the tag explorer scripts |
| `docs/provenance/` | What is and is not known about dates and authorship; machine-readable file inventory |
| `docs/design/` | UI redesign brief for the tag explorer |
| `mappings/ontology-mapping-reference.xlsx` | Tag-to-entity mapping workbook (sheets `gaussian_total`, `30 entities`, `Gaussian energies`) |
| `mappings/archive/` | Earlier, smaller version of the workbook |
| `conceptual-map/` | CmapTools concept map (binary, native format) |
| `data/tags/` | Tag lists extracted for Gaussian and ORCA |
| `references/transforms/` | `CML_Gaussian.xsl`, as supplied |
| `tools/tag-extraction/` | Bash scripts to list and search `dictRef` tags in the ioChem-BD converters ([README](tools/tag-extraction/README.md)) |
| `tools/tag-explorer/` | Tkinter tag explorer, versions v2, v4, v5 demo, v5 export fragment ([README](tools/tag-explorer/README.md)) |
| `tools/audit/` | Script that rebuilds the RDF comparison between versions |

Start with [`docs/manual.md`](docs/manual.md), then [`CHANGELOG.md`](CHANGELOG.md) for what was changed when this repository was assembled.

## Reproducing the version comparison

```bash
python -m pip install -r tools/audit/requirements.txt
python tools/audit/compare_versions.py        # writes to build/ontology-diffs/ (git-ignored)
```

The comparison parses each file as RDF/XML and diffs the graphs (blank nodes compared isomorphically). It does not check logical consistency or competency questions.

## Tag tools

- The Bash scripts need Git and `xmllint`. On first run they clone the ioChem-BD repository into `./iochem-bd/` (git-ignored).
- The explorer GUI needs Tkinter, pandas and an Excel engine (usually openpyxl). The scripts were preserved unmodified and expect inputs that are **not** in this repository: `gaussian-tags-file.txt` (tag-to-file index) and `Ontology Mapping Reference 2.xlsx` (the workbook is now `mappings/ontology-mapping-reference.xlsx`), plus the XML tree from ioChem-BD. Paths must be configured before use.
- v2 and v4 are the candidates for recovering the explorer with real data; `v5_demo` uses demonstration data; `v5_export` is an incomplete fragment. See [the audit](docs/tag-explorer-audit.md).
- The files in `data/tags/` start with two stray prompt lines (`Select a format:`, `Select output mode:`) captured from the Bash scripts; strip them before using the lists as data.

## Authorship

Gabriela Dias da Silva. Texts and ontologies were produced with the support of ChatGPT, the tag explorer with Gemini CLI, tag search with Moises Alvarez and Claude, and review and documentation with Claude. Details in [`AUTHORS.md`](AUTHORS.md); citation metadata in [`CITATION.cff`](CITATION.cff).

## Licensing

No single licence has been chosen. The ontology file carries an inherited CC BY 3.0 reference and authorship statements; those were preserved. Confirm the appropriate licence per component (ontology, code, documents, third-party XSL) before any public release.

## Privacy note

`mappings/ontology-mapping-reference.xlsx` embeds a last-modified-by user name in its document properties, and `docs/provenance/inventory.json` records the name shown as "modified by" in OneDrive. Review both before making the repository public.

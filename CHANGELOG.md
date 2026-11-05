# Changelog

## Repository import — 5 November 2026

Assembled from two packages: `OntoIochem_Git_Organizado.zip` (the earlier organised package) and `ontoiochem_v1_0.zip` (a v1.0 bundle). No historical commits were reconstructed; dates in the provenance records come from file metadata and OneDrive screenshots, not from Git.

### Translated to English
- Documentation: README, audit, provenance and version-comparison reports, tag-explorer audit, UI redesign brief (formerly `orientacoes＜-visual.txt`), and the output text of the comparison script.
- Provenance data (`docs/provenance/inventory.json`): date strings, notes and scope.
- `ontology/ontoiochem.owl` and the 10 archived versions that contain it: one annotation (`iochem:meaning` of the electronic-energy entity, line 928) was in Portuguese and is now English. This is the only change to any ontology file; **the SHA-256 therefore differs from the original v11** (`1c61b7a0…` → `2cad6b5e…`). The manual's reference line was updated accordingly.
- `mappings/ontology-mapping-reference.xlsx`: the same electronic-energy description, the group labels "Energia / Trabalho" and "Química (geral) — …", and five cell comments (Spanish/Portuguese) were translated by editing the workbook XML directly, so threaded comments, styles and formulas are untouched. Two cells held the truncated text "Química (geral) — Ma"; they were completed as "Chemistry (general) — Mass" — please confirm.

Already in English and unchanged: the manual (apart from file references), the SPARQL question set, the ontology (apart from the one annotation), scripts and code comments.

### Redundancy removed
| Removed | Reason |
|---|---|
| `ontoiochem_v11.rdf`, `ontology/history/ontoiochem_v11.owl` | Byte-identical to `ontoiochem.owl` (v11) |
| Duplicate manual in the v1.0 bundle | Identical to the one already in the package |
| `cc_conceptual_map/cmap`, `cc_conceptual_map (2)/cmap` | Identical to the payload inside `cc_conceptual_map.cmap` |
| CmapTools `project.idx` files (3) and `.cmapthumbs` thumbnail | Tool-generated index/thumbnail files, rebuilt by CmapTools |
| `docs/history/*.nt`, per-pair `.md` and `metadata.json` | Generated output; `tools/audit/compare_versions.py` recreates it in `build/` |
| Three `tag_explorer_*--*.diff` files | Derivable with `diff -u`, e.g. `diff -u tools/tag-explorer/tag_explorer_v2.py tools/tag-explorer/tag_explorer_v4.py` |
| `docs/onedrive-provenance.json` | Every entry was already embedded in `inventory.json`; merged into one file |
| `docs/REVISION_LOG.md`, `docs/AUDIT.md`, `docs/PROVENANCE.md` | Overlapping prose merged into `docs/provenance/README.md` and this changelog |
| `OntoIochem_v11_Search_Questions_and_SPARQL.docx` | Converted to `docs/sparql-search-questions.md` (diffable); content identical, queries in fenced code blocks |

The SHA-256 of every removed or changed original is kept in `docs/provenance/inventory.json`, with its disposition.

### Renamed / moved
- `ontology/history/` → `ontology/archive/`; names with spaces and parentheses became `onto_iochem_unversioned*.owl` (mapping in the archive README).
- `Ontology Mapping Reference (3).xlsx` → `mappings/ontology-mapping-reference.xlsx`; `Ontology_ref_30.xlsx` → `mappings/archive/ontology_ref_30_earlier.xlsx` (judged earlier by content: 2 sheets, 30 entities, no `OUTPUT` column — the order is not documented).
- `docs/originals/` flattened: `docs/manual.md`, `docs/design/tag-explorer-ui-redesign-brief.md`.

### Authorship
Added `AUTHORS.md`, `CITATION.cff`, short READMEs for `tools/tag-explorer/` and `tools/tag-extraction/`, and an authorship section in the README (author as stated by the project owner).

### Not changed
All scripts, tag lists, the XSL and the concept map are byte-identical to what was received. The archived ontology versions differ from the received files only by the translated annotation; `inventory.json` keeps the original SHA-256 and the new one (`repo_sha256`) for each.

### Open items
1. Confirm v11 as the development base and reconcile its metadata (`versionInfo` 0.8.0, comments mentioning v10) with its content.
2. Confirm the years omitted in the OneDrive captures and the order of versions modified on the same day.
3. Recover the explorer inputs and decide whether v4 is the base for integrating v5 features.
4. Run a reasoner and execute the competency questions / SPARQL templates.
5. Choose a licence and a release process; optionally export the concept map to SVG/PDF from CmapTools.

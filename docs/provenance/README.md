# Provenance and dating

What can and cannot be stated about when and by whom these files were produced. Machine-readable detail (SHA-256 of every received file, where it ended up, why anything was removed, OneDrive fields) is in [`inventory.json`](inventory.json); container timestamps are in [`zip-timestamps.json`](zip-timestamps.json).

## Dates: what can be claimed

- All 26 files in the OneDrive ZIP carry the ZIP timestamp 2026-11-04 23:20:00, and the files in the My_Cmaps ZIP carry 2026-10-20 11:09:00, both without a time zone. These are container timestamps, not proven creation dates.
- The `.cmap` file is itself a ZIP; its `cmap` entry is stamped 2026-08-14 16:58:42 (no time zone). This does not demonstrate when the map was first created either.
- The RDF headers contain declared dates (2015-03-04, 2026-10-06, 2026-10-07) and version comments. Some may be inherited from the base ontology; they must not be treated as the date of each edit.
- The earlier workbook (`mappings/archive/ontology_ref_30_earlier.xlsx`) has no `docProps/core.xml`. The current workbook does: created and last modified 2026-10-14T10:09:05Z (UTC), with a last-modified-by user recorded in its properties. That date is later than the earlier workbook's 14 September OneDrive date, which fits the earlier/current ordering, but it is still a file property, not proof of authorship. There is no OneDrive version history, no original commit history and no complete authorship record.
- Three screenshots of the OneDrive "Modified" column add last-modified dates, a displayed "modified by" name and the source folder (`Meus arquivos / scripts / Scripts para sacar todos los tags / tag-tools`, quoted as displayed). This column is **Modified, not Created**, and the displayed name does not demonstrate original authorship or authorship of each change. Time and time zone are not shown. Only the XSL row shows a year (2025); 2026 on the other rows is inferred from context and not confirmed. The screenshots are not in the repository; their hashes are in `inventory.json`.
- File ↔ screenshot association relies on matching names and sizes (no OneDrive hashes). The manual's name in the screenshot is truncated, so its match is inferred.

## Last-modified dates shown in OneDrive

| Date shown | Year | Files |
|---|---|---|
| 6 May 2025 | 2025 (explicit) | `references/transforms/CML_Gaussian.xsl` |
| 28 May | 2026 (inferred, unconfirmed) | `data/tags/gaussian-tags.txt`, `tools/tag-extraction/getTags.sh`, `tools/tag-extraction/searchTag.sh` |
| 3 June | 2026 (inferred, unconfirmed) | `docs/design/tag-explorer-ui-redesign-brief.md`, `tools/tag-explorer/tag_explorer_v2.py`, `tools/tag-explorer/tag_explorer_v4.py` |
| 4 June | 2026 (inferred, unconfirmed) | `tools/tag-explorer/tag_explorer_v5_demo.py` |
| 6 August | 2026 (inferred, unconfirmed) | `tools/tag-explorer/tag_explorer_v5_export.py` |
| 14 September | 2026 (inferred, unconfirmed) | `data/tags/orca-tags.txt`, `mappings/archive/ontology_ref_30_earlier.xlsx` |
| 6 October | 2026 (inferred, unconfirmed) | `ontology/archive/onto_iochem_unversioned.owl`, `ontology/archive/onto_iochem_unversioned_copy1.owl`, `ontology/archive/onto_iochem_unversioned_copy2.owl`, `ontology/archive/onto_iochem_unversioned_copy3.owl`, `ontology/archive/onto_iochem_unversioned_copy4.owl`, `ontology/archive/onto_iochem_v2.owl`, `ontology/archive/onto_iochem_v3.owl` |
| 7 October | 2026 (inferred, unconfirmed) | `ontology/archive/ontoiochem_v4.owl`, `ontology/archive/ontoiochem_v6.owl`, `ontology/archive/ontoiochem_v8.owl` |
| 8 October | 2026 (inferred, unconfirmed) | `docs/manual.md`, `ontology/archive/ontoiochem_v10.owl`, `ontology/archive/ontoiochem_v9.rdf`, `ontology/ontoiochem.owl` |

Interpretation:
- Ontologies group into 6 October (unversioned files, v2, v3), 7 October (v4, v6, v8) and 8 October (v9, v10, v11, and probably the manual). This supports a day-level chronology, not the order within a day and not derivation relations between files.
- The internal `created` date of 7 October in later ontologies can coexist with a OneDrive modification on 8 October: they are different fields, and neither should be rewritten from the other.
- Tools: 28 May (extraction and search scripts, Gaussian tag list), 3–4 June (explorers), 6 August (export fragment), 14 September (workbook and ORCA list). These are last-modified dates, not evidence of when development started.
- The captures do not cover My_Cmaps; its metadata and uncertainties are unchanged.

## Findings from the analysis of the received files

- All 15 OWL/RDF files parsed as RDF/XML. This does not prove OWL consistency.
- `ontoiochem_v11.owl` and `ontoiochem_v11.rdf` were byte-identical.
- The two expanded Cmap copies and the payload of the `.cmap` were identical; their project indexes differed.
- v5 and v7 of the ontology do not appear under those names; the names with `(1)` to `(4)` do not establish chronology.
- File names, `versionInfo`, `versionIRI` and comments disagree in places (see the [archive README](../../ontology/archive/README.md)).
- Entity- and triple-level differences between versions: [ontology-version-comparison.md](../ontology-version-comparison.md).
- Static findings on the explorer scripts: [tag-explorer-audit.md](../tag-explorer-audit.md).

## Open items

See the end of [`CHANGELOG.md`](../../CHANGELOG.md).

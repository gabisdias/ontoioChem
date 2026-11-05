# Static audit of the tag explorer

No GUI was run. Python syntax was validated with the AST. Missing methods indicate partial versions; nothing was completed automatically. File names and paths must be checked before running any version.

## Methods per version

| Version | Methods defined | Calls to methods not defined in the class |
|---|---|---|
| `tag_explorer_v2.py` | `__init__`, `apply_global_styles`, `filter_tags`, `load_data`, `load_file_content`, `load_summary`, `on_file_selected`, `on_tag_select`, `render_content`, `render_summary`, `setup_bindings`, `setup_ui`, `update_sidebar`, `update_tag_list`, `zoom_in`, `zoom_out` | none |
| `tag_explorer_v4.py` | `__init__`, `_get_link_definitions`, `apply_scale`, `filter_tags`, `load_data`, `load_file_content`, `load_summary`, `on_file_selected`, `on_tag_select`, `refresh_all_data`, `render_content`, `render_summary`, `save_data_to_excel`, `scan_total_occurrences`, `setup_bindings`, `setup_styles`, `setup_ui`, `update_sidebar_analysis`, `update_tag_list`, `zoom_in`, `zoom_out` | none |
| `tag_explorer_v5_demo.py` | `__init__`, `_get_link_definitions`, `apply_scale`, `filter_tags`, `get_tag_status`, `load_demo_data`, `mark_as_dirty`, `on_close`, `on_file_selected`, `on_tag_select`, `on_tag_select_handler`, `on_text_modified`, `render_demo_content`, `render_demo_summary`, `save_data_demo`, `setup_bindings`, `setup_styles`, `setup_ui`, `update_checklist`, `update_sidebar_analysis`, `update_tag_list`, `zoom_in`, `zoom_out` | none |
| `tag_explorer_v5_export.py` | `__init__`, `export_priority_1`, `setup_styles`, `setup_ui` | `apply_scale`, `load_data`, `setup_bindings` |

## Evolution

- **v4 vs v2:** adds functions to save to Excel, refresh data, count occurrences and analyse the sidebar.
- **v5_demo:** introduces demonstration data, change tracking and a checklist. It is not automatically a functional successor, because it uses demo data rather than real data.
- **v5_export:** contains the high-priority export routine but only four methods and a comment asking for the remaining ones to be added. It is not a complete program.

To see the textual differences: `diff -u tools/tag-explorer/tag_explorer_v2.py tools/tag-explorer/tag_explorer_v4.py` (likewise for v4 → v5_demo and v5_demo → v5_export).

## OneDrive dates

v2 and v4: 3 June; v5_demo: 4 June; v5_export: 6 August. The year is not shown (2026 is inferred). These are last-modified dates, not creation dates or proof of derivation. See [provenance](provenance/README.md).

# Tag explorer UI redesign brief

Brief for a full UX/UI review of the Tkinter tag explorer (`tools/tag-explorer/`). Translated from the Portuguese original, which was written as a prompt for an AI assistant and referred to a screenshot (not included). The explorer scripts themselves were not changed.

---

Analyse the current interface of the Tkinter application and carry out a complete UX/UI review. I do not just want larger fonts; I want the interface to look like a professional, modern tool while keeping the current dark theme.

Consider the screenshot and the existing code.

## Main problem

Currently the zoom only enlarges the fonts, not the visual components proportionally.

This causes several problems:

- huge text inside small controls;
- visually squashed buttons;
- disproportionate comboboxes;
- very thin headers;
- inconsistent scrollbar;
- insufficient spacing;
- an overall dated look.

I want to implement a real global UI scaling system.

## 1. True global zoom

The zoom must scale simultaneously:

- fonts;
- padding;
- margins;
- widget heights;
- button widths;
- scrollbars;
- headers;
- comboboxes;
- text areas.

Create a factor:

```python
self.ui_scale = 1.0
```

and use it throughout the interface.

Currently only `self.base_font_size` is changed. That is not enough.

## 2. Top bar

The (+) and (-) buttons are visually small. Even when the font grows, the button area stays tiny.

I want:

- larger buttons;
- a comfortable clickable area;
- padding proportional to the zoom;
- an appearance consistent with the rest of the interface.

## 3. Current View

The section:

```
Current View:
[combobox]
```

looks improvised. Visually turn it into a navigation bar or toolbar.

Goals:

- greater visual prominence;
- better hierarchy;
- more vertical space;
- adequate internal padding.

## 4. Central scrollbar

The current scrollbar is one of the worst visual elements of the interface.

Problems:

- the thumb is almost invisible;
- it looks like just arrows;
- it is hard to perceive the position within the document;
- inconsistent width.

I want a modern scrollbar:

- wider;
- clearly visible thumb;
- adequate contrast;
- fully aligned with the text area.

Use a customised ttk style if necessary.

## 5. Tag list

The list currently uses a `Listbox` and simulates columns with spaces:

```
cc:E2               | 2 | 1
cc:T2               | 2 | 1
```

This does not scale well. Replace it with `ttk.Treeview` with real columns:

- Tag
- Occurrences
- Files

Benefits:

- perfect alignment;
- sorting;
- correct resizing;
- professional appearance.

## 6. Panels

The three main panels:

- Tags
- Current View
- Sidebar

are visually stuck together. Improve:

- visual separation;
- discreet borders;
- internal padding;
- the feeling of independent cards.

The user should immediately identify the three functional areas.

## 7. Headers

Currently the headers:

- Meaning
- Observation
- Gaussian Stages

look like ordinary labels. I want them visually highlighted.

Possibilities:

- coloured side bar;
- stronger background;
- more robust typography;
- spacing above and below.

## 8. Central content area

The XML area is the most important part of the application. Currently everything has the same visual weight. Create a clear visual hierarchy:

- file: accent colour
- line: secondary colour
- selected tag: strong highlight
- XML content: neutral colour

The user should quickly locate what matters.

## 9. Right sidebar

The sidebar is too compact. Improve:

- vertical spacing;
- alignment;
- organisation of the fields;
- separation between Group, Priority, Meaning and Observation.

The interface should "breathe".

## 10. Gaussian Stages

Currently it looks like just a text log. Visually turn it into organised blocks. For example:

- highlighted link title;
- separate description;
- spacing between modules.

It does not need to become a complex component, but it should look like structured information.

## 11. Global spacing

Define a consistent spacing system. For example:

```python
PADDING_SMALL = 6
PADDING_MEDIUM = 12
PADDING_LARGE = 18
```

and apply it throughout the application. Today the spacings look arbitrary.

## 12. Visual goal

The application should resemble modern tools such as:

- VS Code
- PyCharm
- DBeaver
- GitKraken

without changing the functionality.

Prioritise:

- correct proportions;
- consistency;
- readability;
- visual hierarchy;
- zoom scalability.

Provide concrete changes to the existing code, not just conceptual suggestions. I want a practical, complete implementation.

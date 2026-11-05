import os
import tkinter as tk
from tkinter import ttk, messagebox
import threading
import pandas as pd
import io

class TagExplorerV5Demo:
    def __init__(self, root):
        self.root = root
        self.root.title("ioChem-BD Gaussian Tag Explorer - V5 DEMO (Standalone)")
        self.root.geometry("1600x1000")

        # --- Scale and Spacing System ---
        self.ui_scale = 2.0  # High default scale for visibility
        self.base_font_size = 14
        
        # --- Demo Data State ---
        self.tag_to_files = {}
        self.tag_total_counts = {}
        self.all_tags = []
        self.df_excel = None
        self.current_tag = None
        self.current_files = []
        self.context_lines = 3
        
        # Tracking changes
        self.is_dirty = False

        # --- Colors (Modern VS Code-like Dark Theme) ---
        self.colors = {
            "bg_dark": "#181818",
            "bg_mid": "#252526",
            "bg_light": "#333333",
            "fg": "#cccccc",
            "fg_bright": "#ffffff",
            "accent": "#007acc",
            "accent_hover": "#1f8ad2",
            "border": "#444444",
            "highlight": "#264f78",
            "tag_highlight": "#6a4a00",
            "xml_path": "#4ec9b0",
            "xml_line": "#808080",
            "link_header": "#ce9178",
            "meaning_fg": "#dcdcaa",
            "warning": "#f44747",
            "info": "#b5cea8",
            "success": "#4ec9b0",
            "todo": "#e2c08d"
        }

        self.link_meanings = self._get_link_definitions()
        
        self.setup_styles()
        self.setup_ui()
        self.apply_scale()
        self.load_demo_data() # Using demo data instead of files
        self.setup_bindings()
        
        self.root.protocol("WM_DELETE_WINDOW", self.on_close)

    def _get_link_definitions(self):
        return {
            "l101": "Reads title and molecule specification",
            "l103": "Berny optimizations to minima and TS",
            "l502": "Iteratively solves the SCF equations",
            "l601": "Population and related analyses",
            "l9999": "Finalizes calculation and output"
        }

    def setup_styles(self):
        style = ttk.Style()
        style.theme_use('clam')
        style.configure(".", background=self.colors["bg_dark"], foreground=self.colors["fg"], font=("Segoe UI", 10))
        style.configure("TPanedwindow", background=self.colors["border"])
        style.configure("Card.TFrame", background=self.colors["bg_mid"], relief="flat")
        style.configure("TLabel", background=self.colors["bg_mid"], foreground=self.colors["fg"])
        style.configure("Header.TLabel", background=self.colors["bg_light"], foreground=self.colors["fg_bright"], font=("Segoe UI", 11, "bold"))
        style.configure("SubHeader.TLabel", background=self.colors["bg_mid"], foreground=self.colors["accent"], font=("Segoe UI", 10, "bold"))
        style.configure("TButton", padding=5)
        style.map("TButton", background=[("active", self.colors["accent_hover"]), ("!disabled", self.colors["accent"])], foreground=[("!disabled", self.colors["fg_bright"])])
        style.configure("TEntry", fieldbackground=self.colors["bg_dark"], foreground=self.colors["fg_bright"], insertcolor="white", borderwidth=0)
        style.configure("TCombobox", fieldbackground=self.colors["bg_dark"], foreground="black", borderwidth=0)
        style.configure("Treeview", background=self.colors["bg_mid"], foreground=self.colors["fg"], fieldbackground=self.colors["bg_mid"], borderwidth=0, rowheight=50)
        style.map("Treeview", background=[("selected", self.colors["highlight"])], foreground=[("selected", self.colors["fg_bright"])])
        style.configure("Treeview.Heading", background=self.colors["bg_light"], foreground=self.colors["fg_bright"], font=("Segoe UI", 10, "bold"), borderwidth=0)
        style.configure("Vertical.TScrollbar", gripcount=0, background=self.colors["bg_light"], darkcolor=self.colors["bg_dark"], lightcolor=self.colors["bg_dark"], bordercolor=self.colors["border"], arrowcolor=self.colors["fg"])

    def setup_ui(self):
        self.root.configure(bg=self.colors["bg_dark"])
        self.toolbar = ttk.Frame(self.root, style="Card.TFrame", padding=10)
        self.toolbar.pack(fill=tk.X)
        self.scale_lbl = ttk.Label(self.toolbar, text="Global Scale: ", font=("Segoe UI", 10, "bold"))
        self.scale_lbl.pack(side=tk.LEFT, padx=5)
        ttk.Button(self.toolbar, text=" ( + ) ", command=self.zoom_in).pack(side=tk.LEFT, padx=2)
        ttk.Button(self.toolbar, text=" ( - ) ", command=self.zoom_out).pack(side=tk.LEFT, padx=2)
        ttk.Label(self.toolbar, text="|", foreground=self.colors["border"]).pack(side=tk.LEFT, padx=20)
        ttk.Button(self.toolbar, text=" ↻ REFRESH (DEMO) ", command=self.load_demo_data).pack(side=tk.LEFT, padx=5)
        ttk.Label(self.toolbar, text="|", foreground=self.colors["border"]).pack(side=tk.LEFT, padx=20)
        self.status_lbl = ttk.Label(self.toolbar, text="Ready")
        self.status_lbl.pack(side=tk.LEFT)

        self.main_paned = ttk.PanedWindow(self.root, orient=tk.HORIZONTAL)
        self.main_paned.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)

        # Left Column
        left_card = ttk.Frame(self.main_paned, style="Card.TFrame", padding=2)
        self.main_paned.add(left_card, weight=2)
        ttk.Label(left_card, text=" TAG EXPLORER (DEMO)", style="Header.TLabel", padding=10).pack(fill=tk.X)
        search_frame = ttk.Frame(left_card, style="Card.TFrame", padding=10)
        search_frame.pack(fill=tk.X)
        self.search_var = tk.StringVar(); self.search_var.trace("w", self.filter_tags)
        self.search_entry = ttk.Entry(search_frame, textvariable=self.search_var); self.search_entry.pack(fill=tk.X)
        tree_container = tk.Frame(left_card, bg=self.colors["bg_mid"])
        tree_container.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)
        self.tree = ttk.Treeview(tree_container, columns=("Tag", "Occ", "Files", "M", "G", "P"), show="headings", selectmode="browse")
        for col, txt, w in zip(["Tag", "Occ", "Files", "M", "G", "P"], ["Tag", "Tot", "F", "M", "G", "P"], [200, 50, 40, 35, 35, 35]):
            self.tree.heading(col, text=txt); self.tree.column(col, width=w, anchor=tk.CENTER if len(col)<=1 else tk.W)
        self.tree.tag_configure("todo", foreground=self.colors["todo"])
        self.tree.tag_configure("done", foreground=self.colors["fg"])
        tree_scroll = tk.Scrollbar(tree_container, orient=tk.VERTICAL, command=self.tree.yview)
        self.tree.configure(yscrollcommand=tree_scroll.set)
        tree_scroll.pack(side=tk.RIGHT, fill=tk.Y); self.tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        self.tree.bind("<<TreeviewSelect>>", self.on_tag_select_handler)

        # Middle Column
        mid_card = ttk.Frame(self.main_paned, style="Card.TFrame", padding=2)
        self.main_paned.add(mid_card, weight=4)
        self.view_toolbar = ttk.Frame(mid_card, style="Header.TLabel", padding=10); self.view_toolbar.pack(fill=tk.X)
        ttk.Label(self.view_toolbar, text=" VIEW:", style="Header.TLabel").pack(side=tk.LEFT)
        self.file_combo = ttk.Combobox(self.view_toolbar, state="readonly"); self.file_combo.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=15)
        self.file_combo.bind("<<ComboboxSelected>>", self.on_file_selected)
        text_container = tk.Frame(mid_card, bg=self.colors["bg_dark"]); text_container.pack(fill=tk.BOTH, expand=True)
        self.v_scroll = tk.Scrollbar(text_container, orient=tk.VERTICAL, width=25, bg=self.colors["bg_light"], troughcolor=self.colors["bg_dark"], activebackground=self.colors["accent"], bd=0); self.v_scroll.pack(side=tk.RIGHT, fill=tk.Y)
        self.context_text = tk.Text(text_container, wrap=tk.WORD, bg=self.colors["bg_dark"], fg=self.colors["fg"], insertbackground="white", border=0, padx=20, pady=20, undo=True); self.context_text.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        self.context_text.configure(yscrollcommand=self.v_scroll.set); self.v_scroll.configure(command=self.context_text.yview)

        # Right Column
        right_card = ttk.Frame(self.main_paned, style="Card.TFrame", padding=2)
        self.main_paned.add(right_card, weight=2)
        ttk.Label(right_card, text=" ANALYSIS & METADATA", style="Header.TLabel", padding=10).pack(fill=tk.X)
        sidebar_scroll_canvas = tk.Canvas(right_card, bg=self.colors["bg_mid"], highlightthickness=0); sidebar_scroll_canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        side_scroll = ttk.Scrollbar(right_card, orient=tk.VERTICAL, command=sidebar_scroll_canvas.yview); side_scroll.pack(side=tk.RIGHT, fill=tk.Y)
        sidebar_scroll_canvas.configure(yscrollcommand=side_scroll.set)
        self.sidebar_container = ttk.Frame(sidebar_scroll_canvas, style="Card.TFrame", padding=15); sidebar_scroll_canvas.create_window((0, 0), window=self.sidebar_container, anchor="nw")
        def on_configure(e): sidebar_scroll_canvas.configure(scrollregion=sidebar_scroll_canvas.bbox("all"), width=e.width)
        sidebar_scroll_canvas.bind("<Configure>", on_configure)

        ttk.Label(self.sidebar_container, text=" REVIEW STATUS", style="SubHeader.TLabel").pack(fill=tk.X, pady=(0, 5))
        self.checklist_frame = ttk.Frame(self.sidebar_container, style="Card.TFrame"); self.checklist_frame.pack(fill=tk.X, pady=(0, 20))
        self.checks = {}
        for key in ["meaning", "group", "priority"]:
            lbl = tk.Label(self.checklist_frame, text=f"• {key.title()} missing", bg=self.colors["bg_mid"], fg=self.colors["warning"], anchor="w"); lbl.pack(fill=tk.X)
            self.checks[key] = lbl

        ttk.Label(self.sidebar_container, text=" CLASSIFICATION", style="SubHeader.TLabel").pack(fill=tk.X, pady=(0, 10))
        grid_meta = ttk.Frame(self.sidebar_container, style="Card.TFrame"); grid_meta.pack(fill=tk.X, pady=(0, 20))
        ttk.Label(grid_meta, text="Group:").grid(row=0, column=0, sticky="w")
        self.group_combo = ttk.Combobox(grid_meta, state="readonly"); self.group_combo.grid(row=0, column=1, sticky="ew", padx=10, pady=5); self.group_combo.bind("<<ComboboxSelected>>", self.mark_as_dirty)
        ttk.Label(grid_meta, text="Priority:").grid(row=1, column=0, sticky="w")
        self.priority_combo = ttk.Combobox(grid_meta, state="readonly"); self.priority_combo.grid(row=1, column=1, sticky="ew", padx=10, pady=5); self.priority_combo.bind("<<ComboboxSelected>>", self.mark_as_dirty)
        grid_meta.columnconfigure(1, weight=1)

        ttk.Label(self.sidebar_container, text=" MEANING", style="SubHeader.TLabel").pack(fill=tk.X, pady=(0, 5))
        self.meaning_text = tk.Text(self.sidebar_container, wrap=tk.WORD, bg=self.colors["bg_dark"], fg=self.colors["meaning_fg"], height=4, border=0, padx=10, pady=10); self.meaning_text.pack(fill=tk.X, pady=(0, 15)); self.meaning_text.bind("<<Modified>>", self.on_text_modified)
        ttk.Label(self.sidebar_container, text=" OBSERVATION", style="SubHeader.TLabel").pack(fill=tk.X, pady=(0, 5))
        self.obs_text = tk.Text(self.sidebar_container, wrap=tk.WORD, bg=self.colors["bg_dark"], fg=self.colors["fg"], height=4, border=0, padx=10, pady=10); self.obs_text.pack(fill=tk.X, pady=(0, 20)); self.obs_text.bind("<<Modified>>", self.on_text_modified)
        self.save_btn = ttk.Button(self.sidebar_container, text="SAVE CHANGES", command=self.save_data_demo); self.save_btn.pack(fill=tk.X, ipady=10)
        ttk.Label(self.sidebar_container, text=" GAUSSIAN STAGES", style="SubHeader.TLabel").pack(fill=tk.X, pady=(30, 10))
        self.analysis_container = ttk.Frame(self.sidebar_container, style="Card.TFrame"); self.analysis_container.pack(fill=tk.BOTH, expand=True)

    def load_demo_data(self):
        # Sample Excel Mock
        data = {
            "Tag": ["gaussian:scf.energy", "gaussian:scf.iterations", "gaussian:homo", "gaussian:lumo", "gaussian:force.constant", "gaussian:dipole.moment"],
            "Meaning": ["Total energy calculated at SCF level", "Number of steps taken to converge", "Highest Occupied Molecular Orbital", "Lowest Unoccupied Molecular Orbital", "N/A", "N/A"],
            "Group": ["Energy", "Convergence", "Orbitals", "Orbitals", "", ""],
            "Priority": ["High", "Medium", "Medium", "Medium", "", ""],
            "Observation": ["Main result", "Watch for slow convergence", "", "", "Needs review", ""]
        }
        self.df_excel = pd.DataFrame(data)
        self.group_combo['values'] = ["Energy", "Convergence", "Orbitals", "Geometry"]
        self.priority_combo['values'] = ["High", "Medium", "Low"]
        
        # Mock Tag-File mapping
        self.tag_to_files = {
            "gaussian:scf.energy": ["l502.log", "l9999.log"],
            "gaussian:scf.iterations": ["l502.log"],
            "gaussian:homo": ["l601.log"],
            "gaussian:lumo": ["l601.log"],
            "gaussian:force.constant": ["l103.log"],
            "gaussian:dipole.moment": ["l601.log"]
        }
        self.tag_total_counts = {"gaussian:scf.energy": 12, "gaussian:scf.iterations": 4, "gaussian:homo": 1, "gaussian:lumo": 1, "gaussian:force.constant": 48, "gaussian:dipole.moment": 2}
        self.all_tags = sorted(list(self.tag_to_files.keys()))
        self.update_tag_list()
        self.status_lbl.configure(text=f"Loaded {len(self.all_tags)} demo tags.")

    def get_tag_status(self, tag_name):
        match = self.df_excel[self.df_excel["Tag"] == tag_name]
        if match.empty: return False, False, False
        row = match.iloc[0]
        m, g, p = str(row["Meaning"]).lower(), str(row["Group"]).lower(), str(row["Priority"]).lower()
        return m not in ["", "nan", "n/a"], g not in ["", "nan", "n/a"], p not in ["", "nan", "n/a"]

    def update_tag_list(self, ft=""):
        for item in self.tree.get_children(): self.tree.delete(item)
        for t in self.all_tags:
            if ft.lower() in t.lower():
                m_ok, g_ok, p_ok = self.get_tag_status(t)
                is_done = m_ok and g_ok and p_ok
                tag_style = "done" if is_done else "todo"
                m_s, g_s, p_s = ("✓" if x else "⚠" for x in [m_ok, g_ok, p_ok])
                self.tree.insert("", tk.END, values=(t, self.tag_total_counts[t], len(self.tag_to_files[t]), m_s, g_s, p_s), tags=(tag_style,))

    def on_tag_select(self, event):
        sel = self.tree.selection()
        if not sel: return
        self.current_tag = self.tree.item(sel[0])['values'][0]
        self.current_files = sorted(self.tag_to_files.get(self.current_tag, []))
        self.file_combo['values'] = ["[ SUMMARY HOME ]"] + self.current_files
        self.file_combo.current(0); self.on_file_selected(None)
        
        match = self.df_excel[self.df_excel["Tag"] == self.current_tag]
        row = match.iloc[0] if not match.empty else {"Meaning": "N/A", "Group": "", "Priority": "", "Observation": ""}
        self.group_combo.set(row.get("Group", ""))
        self.priority_combo.set(row.get("Priority", ""))
        self.meaning_text.delete("1.0", tk.END); self.meaning_text.insert(tk.END, row.get("Meaning", "N/A"))
        self.obs_text.delete("1.0", tk.END); self.obs_text.insert(tk.END, row.get("Observation", ""))
        self.meaning_text.edit_modified(False); self.obs_text.edit_modified(False); self.is_dirty = False
        self.status_lbl.configure(text="Ready", foreground=self.colors["fg"])
        self.update_checklist(); self.update_sidebar_analysis()

    def on_file_selected(self, event):
        idx = self.file_combo.current()
        if idx <= 0: self.render_demo_summary()
        else: self.render_demo_content(self.current_files[idx-1])

    def render_demo_summary(self):
        self.context_text.config(state=tk.NORMAL); self.context_text.delete("1.0", tk.END)
        s = self.ui_scale
        self.context_text.tag_configure("highlight", background=self.colors["tag_highlight"], foreground=self.colors["fg_bright"])
        self.context_text.tag_configure("path_header", foreground=self.colors["xml_path"], font=("Consolas", int(11 * s), "bold"))
        self.context_text.tag_configure("line_num", foreground=self.colors["xml_line"], font=("Consolas", int(10 * s)))
        
        for f in self.current_files:
            self.context_text.insert(tk.END, f" FILE: /demo/path/{f}\n", "path_header")
            self.context_text.insert(tk.END, " LINE: 452\n" + "-"*40 + "\n", "line_num")
            start = self.context_text.index(tk.INSERT)
            self.context_text.insert(tk.END, f" <scalar dataType=\"xsd:double\" dictRef=\"{self.current_tag}\" units=\"nonsi:hartree\">-75.123456</scalar>\n")
            self.context_text.tag_add("highlight", start + f" + {28}c", start + f" + {28+len(self.current_tag)}c")
            self.context_text.insert(tk.END, "\n" + "═"*60 + "\n\n", "line_num")
        self.context_text.config(state=tk.DISABLED)

    def render_demo_content(self, filename):
        self.context_text.config(state=tk.NORMAL); self.context_text.delete("1.0", tk.END)
        self.context_text.tag_configure("highlight", background=self.colors["tag_highlight"], foreground=self.colors["fg_bright"])
        content = f"--- MOCK LOG FILE: {filename} ---\n\nLots of Gaussian output text here...\n"
        content += f"More lines of simulation data...\n"
        content += f"<scalar dataType=\"xsd:double\" dictRef=\"{self.current_tag}\" units=\"nonsi:hartree\">-75.123456</scalar>\n"
        content += f"\nEOF"
        self.context_text.insert(tk.END, content)
        found = self.context_text.search(self.current_tag, "1.0")
        if found: self.context_text.tag_add("highlight", found, f"{found}+{len(self.current_tag)}c"); self.context_text.see(found)
        self.context_text.config(state=tk.DISABLED)

    def save_data_demo(self):
        if not self.current_tag: return False
        mask = self.df_excel["Tag"] == self.current_tag
        self.df_excel.loc[mask, "Meaning"] = self.meaning_text.get("1.0", tk.END).strip()
        self.df_excel.loc[mask, "Group"] = self.group_combo.get()
        self.df_excel.loc[mask, "Priority"] = self.priority_combo.get()
        self.df_excel.loc[mask, "Observation"] = self.obs_text.get("1.0", tk.END).strip()
        self.is_dirty = False
        self.status_lbl.configure(text=f"Demo: '{self.current_tag}' saved internally", foreground=self.colors["success"])
        self.update_tag_list(self.search_var.get()); self.update_checklist()
        return True

    def update_checklist(self):
        m, g, p = self.meaning_text.get("1.0", tk.END).strip().lower(), self.group_combo.get().strip().lower(), self.priority_combo.get().strip().lower()
        checks = {"meaning": m not in ["", "nan", "n/a"], "group": g not in ["", "nan", "n/a"], "priority": p not in ["", "nan", "n/a"]}
        for k, ok in checks.items():
            self.checks[k].configure(text=f"{'✓' if ok else '⚠'} {k.title()} {'ok' if ok else 'missing'}", fg=self.colors["success"] if ok else self.colors["warning"])

    def update_sidebar_analysis(self):
        for widget in self.analysis_container.winfo_children(): widget.destroy()
        for f in self.current_files:
            l = f.split('.')[0]
            block = ttk.Frame(self.analysis_container, style="Card.TFrame", padding=10); block.pack(fill=tk.X, pady=5)
            ttk.Label(block, text=f"Link {l.upper()}", foreground=self.colors["link_header"], font=("Segoe UI", int(10 * self.ui_scale), "bold")).pack(anchor="w")
            ttk.Label(block, text=self.link_meanings.get(l, "Demo module info."), wraplength=int(300 * self.ui_scale), justify="left").pack(anchor="w", pady=(5, 0))

    def on_tag_select_handler(self, e):
        if self.is_dirty and messagebox.askyesno("Unsaved", f"Save changes to '{self.current_tag}'?"): self.save_data_demo()
        self.on_tag_select(e)

    def on_close(self):
        if self.is_dirty and messagebox.askyesno("Exit", "Save changes before exiting?"): self.save_data_demo()
        self.root.destroy()

    def mark_as_dirty(self, *args): self.is_dirty = True; self.status_lbl.configure(text="Unsaved changes...", foreground=self.colors["warning"]); self.update_checklist()
    def on_text_modified(self, e):
        if e.widget.edit_modified(): self.mark_as_dirty(); e.widget.edit_modified(False)
    def apply_scale(self):
        s = self.ui_scale; base_std, base_tree, base_hdr, base_sub, base_txt = 12, 18, 16, 14, 14
        style = ttk.Style()
        style.configure(".", font=("Segoe UI", int(base_std * s)))
        style.configure("Header.TLabel", font=("Segoe UI", int(base_hdr * s), "bold"))
        style.configure("SubHeader.TLabel", font=("Segoe UI", int(base_sub * s), "bold"))
        style.configure("Treeview", font=("Segoe UI", int(base_tree * s)), rowheight=int(50 * s))
        style.configure("Treeview.Heading", font=("Segoe UI", int(base_tree * s), "bold"))
        style.configure("TButton", font=("Segoe UI", int(base_std * s), "bold"), padding=int(10 * s))
        style.configure("TCombobox", font=("Segoe UI", int(base_std * s)))
        self.context_text.configure(font=("Consolas", int(base_txt * s)))
        self.meaning_text.configure(font=("Segoe UI", int(base_std * s)))
        self.obs_text.configure(font=("Segoe UI", int(base_std * s)))
        self.search_entry.configure(font=("Segoe UI", int(base_std * s)))
        self.group_combo.configure(font=("Segoe UI", int(base_std * s)))
        self.priority_combo.configure(font=("Segoe UI", int(base_std * s)))
        self.file_combo.configure(font=("Segoe UI", int(base_hdr * s), "bold"))
        self.status_lbl.configure(font=("Segoe UI", int(base_std * s)))
        self.scale_lbl.configure(font=("Segoe UI", int(base_std * s), "bold"))
        for lbl in self.checks.values(): lbl.configure(font=("Segoe UI", int(base_std * s)))
        self.root.option_add("*TCombobox*Listbox.font", ("Segoe UI", int(base_std * s)))
        self.v_scroll.configure(width=int(20 * s))
        if self.current_tag: self.on_tag_select(None)
    def zoom_in(self): self.ui_scale += 0.2; self.apply_scale()
    def zoom_out(self): 
        if self.ui_scale > 0.6: self.ui_scale -= 0.2; self.apply_scale()
    def setup_bindings(self): self.root.bind("<Control-plus>", lambda e: self.zoom_in()); self.root.bind("<Control-equal>", lambda e: self.zoom_in()); self.root.bind("<Control-minus>", lambda e: self.zoom_out()); self.root.bind("<Control-s>", lambda e: self.save_data_demo())
    def filter_tags(self, *args): self.update_tag_list(self.search_var.get())

if __name__ == "__main__":
    root = tk.Tk()
    app = TagExplorerV5Demo(root)
    root.mainloop()

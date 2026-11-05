import os
import tkinter as tk
from tkinter import ttk, messagebox
import threading
import pandas as pd

class TagExplorerV4:
    def __init__(self, root):
        self.root = root
        self.root.title("ioChem-BD Gaussian Tag Explorer - V4 Professional")
        self.root.geometry("1600x1000")

        # --- Scale and Spacing System ---
        self.ui_scale = 1.2  # Initial scale for high-res
        self.base_font_size = 14
        
        # --- File and Data State ---
        self.tags_file = "gaussian-tags-file.txt"
        self.excel_file = "Ontology Mapping Reference 2.xlsx"
        self.tag_to_files = {}
        self.tag_total_counts = {}
        self.all_tags = []
        self.df_excel = None
        self.current_tag = None
        self.current_files = []
        self.context_lines = 3

        # --- Colors (Modern VS Code-like Dark Theme) ---
        self.colors = {
            "bg_dark": "#181818",       # Background deep
            "bg_mid": "#252526",        # Sidebar / List
            "bg_light": "#333333",      # Headers / Toolbars
            "fg": "#cccccc",            # Main text
            "fg_bright": "#ffffff",     # Bold text
            "accent": "#007acc",        # VS Code blue
            "accent_hover": "#1f8ad2",
            "border": "#444444",        # Discrete borders
            "highlight": "#264f78",     # Selection highlight
            "tag_highlight": "#6a4a00", # Specific tag yellow-ish highlight
            "xml_path": "#4ec9b0",      # Teal for paths
            "xml_line": "#808080",      # Gray for line numbers
            "link_header": "#ce9178",   # Orange-ish for links
            "meaning_fg": "#dcdcaa",    # Yellow-ish for meanings
            "warning": "#f44747",
            "info": "#b5cea8"
        }

        self.link_meanings = self._get_link_definitions()
        
        self.setup_styles()
        self.setup_ui()
        self.apply_scale()
        self.load_data()
        self.setup_bindings()

    def _get_link_definitions(self):
        return {
            "l0": "Initializes program and controls overlaying",
            "l1": "Processes route section, builds list of links to execute, and initializes scratch files",
            "l101": "Reads title and molecule specification",
            "l102": "Fletcher-Powell optimizations",
            "l103": "Berny optimizations to minima and TS, STQN transition state searches",
            "l105": "Murtaugh-Sargent optimizations",
            "l106": "Numerical differentiation of forces/dipoles to obtain polarizability/ hyperpolarizability",
            "l107": "Linear-synchronous-transit (LST) transition state search",
            "l108": "Unrelaxed potential energy surface scan",
            "l109": "Newton-Raphson optimization",
            "l110": "Double numerical differentiation of energies to produce frequencies",
            "l111": "Double numerical differentiation of energies to compute polarizabilities and hyperpolarizabilities",
            "l112": "Performs the Self-Consistent Virial Scaling method (SCVS)",
            "l113": "EF optimization using analytic gradients",
            "l114": "EF numerical optimization (using only energies)",
            "l115": "Follows reaction path using GS3 algorithm",
            "l116": "Numerical self-consistent reaction field (SCRF)",
            "l117": "Performs IPCM solvation calculations.",
            "l118": "BOMD calculations",
            "l120": "Controls ONIOM calculations",
            "l121": "ADMP calculations",
            "l122": "Counterpoise calculations",
            "l123": "Follows reaction path using the HPC algorithm (and others)",
            "l124": "Performs ONIOM with PCM and external-iteration PCM",
            "l202": "Reorients coordinates, calculates symmetry, and checks variables",
            "l301": "Generates basis set information",
            "l302": "Calculates overlap, kinetic, and potential integrals",
            "l303": "Calculates multipole integrals",
            "l308": "Computes dipole velocity and Rx∇ integrals",
            "l310": "Computes spdf 2-electron integrals in a primitive fashion",
            "l311": "Computes sp 2-electron integrals",
            "l314": "Computes spdf 2-electron integrals",
            "l316": "Prints 2-electron integrals",
            "l319": "Computes 1-electron integrals for approximate spin orbital coupling",
            "l401": "Forms the initial MO guess",
            "l402": "Performs semi-empirical and molecular mechanics calculations",
            "l405": "Initializes an MCSCF calculation",
            "l502": "Iteratively solves the SCF equations (conven. UHF & ROHF, all direct methods, SCRF)",
            "l503": "Iteratively solves the SCF equations using direct minimization",
            "l506": "Performs an ROHF or GVB-PP calculation",
            "l508": "Quadratically convergent SCF program",
            "l510": "MC-SCF",
            "l601": "Population and related analyses (including multipole moments)",
            "l602": "1-electron properties (potential, field, and field gradient)",
            "l604": "Evaluates MOs or density over a grid of points",
            "l607": "Performs NBO analyses",
            "l608": "Non-iterative DFT energies",
            "l609": "Atoms in Molecules properties",
            "l610": "Numerical integration (for testing integral codes)",
            "l701": "1-electron integral first or second derivatives",
            "l702": "2-electron integral first or second derivatives (sp)",
            "l703": "2-electron integral first or second derivatives (spdf)",
            "l716": "Processes information for optimizations and frequencies",
            "l801": "Initializes transformation of 2-electron integrals",
            "l802": "Performs integral transformation (N3 in-core)",
            "l804": "Integral transformation",
            "l811": "Transforms integral derivatives & computes their contributions to MP2 2nd derivatives",
            "l901": "Anti-symmetrizes 2-electron integrals",
            "l902": "Determines the stability of the Hartree-Fock wavefunction",
            "l903": "Old in-core MP2",
            "l904": "Complete basis set (CBS) extrapolation method of Petersson, et. al.",
            "l905": "Complex MP2",
            "l906": "Semi-direct MP2",
            "l908": "Electron Propagator Program",
            "l909": "ADC(3) and related electron propagator models",
            "l913": "Calculates post-SCF energies and gradient terms",
            "l914": "CI-Singles, RPA and ZIndo excited states; SCF stability",
            "l915": "Computes fifth order quantities (for MP5, QCISD(TQ) and BD(TQ))",
            "l916": "Old MP4 and CCSD",
            "l918": "Reoptimizes the wavefunction",
            "l923": "SAC-CI program",
            "l925": "Implements the Excited State Electron Transfer (EET) model",
            "l1002": "Iteratively solves the CPHF equations; computes various properties (including NMR)",
            "l1003": "Iteratively solves the CP-MCSCF equations",
            "l1014": "Computes analytic CI-Singles second derivatives",
            "l1101": "Computes 1-electron integral derivatives",
            "l1102": "Computes dipole derivative integrals",
            "l1110": "2-electron integral derivative contribution to F(x)",
            "l1111": "2 particle density matrix and post-SCF derivatives",
            "l1112": "MP2 second derivatives",
            "l9999": "Finalizes calculation and output"
        }

    def setup_styles(self):
        style = ttk.Style()
        style.theme_use('clam')

        # --- Global Style Config ---
        style.configure(".", background=self.colors["bg_dark"], foreground=self.colors["fg"], font=("Segoe UI", 10))
        
        # PanedWindow
        style.configure("TPanedwindow", background=self.colors["border"])
        
        # Frames (Card-like)
        style.configure("Card.TFrame", background=self.colors["bg_mid"], relief="flat")
        
        # Labels
        style.configure("TLabel", background=self.colors["bg_mid"], foreground=self.colors["fg"])
        style.configure("Header.TLabel", background=self.colors["bg_light"], foreground=self.colors["fg_bright"], font=("Segoe UI", 11, "bold"))
        style.configure("SubHeader.TLabel", background=self.colors["bg_mid"], foreground=self.colors["accent"], font=("Segoe UI", 10, "bold"))
        
        # Buttons
        style.configure("TButton", padding=5)
        style.map("TButton", 
                  background=[("active", self.colors["accent_hover"]), ("!disabled", self.colors["accent"])],
                  foreground=[("!disabled", self.colors["fg_bright"])])
        
        # Entries & Combos
        style.configure("TEntry", fieldbackground=self.colors["bg_dark"], foreground=self.colors["fg_bright"], insertcolor="white", borderwidth=0)
        style.configure("TCombobox", fieldbackground=self.colors["bg_dark"], foreground="black", borderwidth=0)
        
        # Treeview (Modern)
        style.configure("Treeview", 
                        background=self.colors["bg_mid"], 
                        foreground=self.colors["fg"], 
                        fieldbackground=self.colors["bg_mid"], 
                        borderwidth=0, 
                        rowheight=30)
        style.map("Treeview", background=[("selected", self.colors["highlight"])], foreground=[("selected", self.colors["fg_bright"])])
        style.configure("Treeview.Heading", background=self.colors["bg_light"], foreground=self.colors["fg_bright"], font=("Segoe UI", 10, "bold"), borderwidth=0)

        # Scrollbar (Modern Look)
        style.configure("Vertical.TScrollbar", gripcount=0, background=self.colors["bg_light"], darkcolor=self.colors["bg_dark"], lightcolor=self.colors["bg_dark"], bordercolor=self.colors["border"], arrowcolor=self.colors["fg"])

    def setup_ui(self):
        self.root.configure(bg=self.colors["bg_dark"])

        # 1. Top Toolbar (Zoom & Global Controls)
        self.toolbar = ttk.Frame(self.root, style="Card.TFrame", padding=10)
        self.toolbar.pack(fill=tk.X)
        
        ttk.Label(self.toolbar, text="Global Scale: ", font=("Segoe UI", 10, "bold")).pack(side=tk.LEFT, padx=5)
        self.btn_plus = ttk.Button(self.toolbar, text=" ( + ) ", command=self.zoom_in)
        self.btn_plus.pack(side=tk.LEFT, padx=2)
        self.btn_minus = ttk.Button(self.toolbar, text=" ( - ) ", command=self.zoom_out)
        self.btn_minus.pack(side=tk.LEFT, padx=2)
        
        ttk.Label(self.toolbar, text="|", foreground=self.colors["border"]).pack(side=tk.LEFT, padx=20)
        
        # New Refresh Button
        self.btn_refresh = ttk.Button(self.toolbar, text=" ↻ REFRESH DATA ", command=self.refresh_all_data)
        self.btn_refresh.pack(side=tk.LEFT, padx=5)
        
        ttk.Label(self.toolbar, text="|", foreground=self.colors["border"]).pack(side=tk.LEFT, padx=20)
        self.status_lbl = ttk.Label(self.toolbar, text="Ready", font=("Segoe UI", 10))
        self.status_lbl.pack(side=tk.LEFT)

        # 2. Main Layout (Three Columns)
        self.main_paned = ttk.PanedWindow(self.root, orient=tk.HORIZONTAL)
        self.main_paned.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)

        # --- LEFT COLUMN: Tags ---
        left_card = ttk.Frame(self.main_paned, style="Card.TFrame", padding=2)
        self.main_paned.add(left_card, weight=1)
        
        header_left = ttk.Label(left_card, text=" TAG EXPLORER", style="Header.TLabel", padding=10)
        header_left.pack(fill=tk.X)
        
        search_frame = ttk.Frame(left_card, style="Card.TFrame", padding=10)
        search_frame.pack(fill=tk.X)
        self.search_var = tk.StringVar()
        self.search_var.trace("w", self.filter_tags)
        self.search_entry = ttk.Entry(search_frame, textvariable=self.search_var)
        self.search_entry.pack(fill=tk.X)
        
        # Treeview for Tags
        self.tree = ttk.Treeview(left_card, columns=("Tag", "Occ", "Files"), show="headings", selectmode="browse")
        self.tree.heading("Tag", text="Tag", anchor=tk.W)
        self.tree.heading("Occ", text="Total")
        self.tree.heading("Files", text="Files")
        self.tree.column("Tag", width=200, anchor=tk.W)
        self.tree.column("Occ", width=60, anchor=tk.CENTER)
        self.tree.column("Files", width=60, anchor=tk.CENTER)
        self.tree.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)
        self.tree.bind("<<TreeviewSelect>>", self.on_tag_select)

        # --- MIDDLE COLUMN: Context & File View ---
        mid_card = ttk.Frame(self.main_paned, style="Card.TFrame", padding=2)
        self.main_paned.add(mid_card, weight=3)
        
        # Navbar-like view selector
        self.view_toolbar = ttk.Frame(mid_card, style="Header.TLabel", padding=10)
        self.view_toolbar.pack(fill=tk.X)
        ttk.Label(self.view_toolbar, text=" VIEW:", style="Header.TLabel").pack(side=tk.LEFT)
        self.file_combo = ttk.Combobox(self.view_toolbar, state="readonly")
        self.file_combo.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=15)
        self.file_combo.bind("<<ComboboxSelected>>", self.on_file_selected)

        # XML Content Area
        self.context_text = tk.Text(mid_card, wrap=tk.WORD, bg=self.colors["bg_dark"], fg=self.colors["fg"], 
                                    insertbackground="white", border=0, padx=20, pady=20, undo=True)
        self.context_text.pack(fill=tk.BOTH, expand=True)
        
        # Custom wider scrollbar
        self.v_scroll = tk.Scrollbar(mid_card, orient=tk.VERTICAL, command=self.context_text.yview, 
                                     width=25, bg=self.colors["bg_light"], troughcolor=self.colors["bg_dark"],
                                     activebackground=self.colors["accent"], bd=0)
        self.v_scroll.pack(side=tk.RIGHT, fill=tk.Y)
        self.context_text.configure(yscrollcommand=self.v_scroll.set)

        # --- RIGHT COLUMN: Metadata & Sidebar ---
        right_card = ttk.Frame(self.main_paned, style="Card.TFrame", padding=2)
        self.main_paned.add(right_card, weight=2)
        
        header_right = ttk.Label(right_card, text=" ANALYSIS & METADATA", style="Header.TLabel", padding=10)
        header_right.pack(fill=tk.X)
        
        sidebar_scroll_canvas = tk.Canvas(right_card, bg=self.colors["bg_mid"], highlightthickness=0)
        sidebar_scroll_canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        
        side_scroll = ttk.Scrollbar(right_card, orient=tk.VERTICAL, command=sidebar_scroll_canvas.yview)
        side_scroll.pack(side=tk.RIGHT, fill=tk.Y)
        sidebar_scroll_canvas.configure(yscrollcommand=side_scroll.set)
        
        self.sidebar_container = ttk.Frame(sidebar_scroll_canvas, style="Card.TFrame", padding=15)
        sidebar_scroll_canvas.create_window((0, 0), window=self.sidebar_container, anchor="nw")
        
        def on_configure(e): sidebar_scroll_canvas.configure(scrollregion=sidebar_scroll_canvas.bbox("all"), width=e.width)
        sidebar_scroll_canvas.bind("<Configure>", on_configure)

        # Group/Priority Section
        ttk.Label(self.sidebar_container, text=" CLASSIFICATION", style="SubHeader.TLabel").pack(fill=tk.X, pady=(0, 10))
        
        grid_meta = ttk.Frame(self.sidebar_container, style="Card.TFrame")
        grid_meta.pack(fill=tk.X, pady=(0, 20))
        
        ttk.Label(grid_meta, text="Group:").grid(row=0, column=0, sticky="w")
        self.group_combo = ttk.Combobox(grid_meta, state="readonly")
        self.group_combo.grid(row=0, column=1, sticky="ew", padx=10, pady=5)
        
        ttk.Label(grid_meta, text="Priority:").grid(row=1, column=0, sticky="w")
        self.priority_combo = ttk.Combobox(grid_meta, state="readonly")
        self.priority_combo.grid(row=1, column=1, sticky="ew", padx=10, pady=5)
        grid_meta.columnconfigure(1, weight=1)

        # Meaning & Obs Section
        ttk.Label(self.sidebar_container, text=" MEANING", style="SubHeader.TLabel").pack(fill=tk.X, pady=(0, 5))
        self.meaning_text = tk.Text(self.sidebar_container, wrap=tk.WORD, bg=self.colors["bg_dark"], fg=self.colors["meaning_fg"], height=4, border=0, padx=10, pady=10)
        self.meaning_text.pack(fill=tk.X, pady=(0, 15))

        ttk.Label(self.sidebar_container, text=" OBSERVATION", style="SubHeader.TLabel").pack(fill=tk.X, pady=(0, 5))
        self.obs_text = tk.Text(self.sidebar_container, wrap=tk.WORD, bg=self.colors["bg_dark"], fg=self.colors["fg"], height=4, border=0, padx=10, pady=10)
        self.obs_text.pack(fill=tk.X, pady=(0, 20))
        
        self.save_btn = ttk.Button(self.sidebar_container, text="SYNC TO EXCEL", command=self.save_data_to_excel)
        self.save_btn.pack(fill=tk.X, ipady=10)

        # Gaussian Stages Section (Visual Blocks)
        ttk.Label(self.sidebar_container, text=" GAUSSIAN STAGES", style="SubHeader.TLabel").pack(fill=tk.X, pady=(30, 10))
        self.analysis_container = ttk.Frame(self.sidebar_container, style="Card.TFrame")
        self.analysis_container.pack(fill=tk.BOTH, expand=True)

    def apply_scale(self):
        """Dynamic scaling of fonts, padding, and widget sizes."""
        s = self.ui_scale
        font_size = int(self.base_font_size * s)
        
        # 1. Update Styles
        style = ttk.Style()
        style.configure(".", font=("Segoe UI", int(10 * s)))
        style.configure("Header.TLabel", font=("Segoe UI", int(12 * s), "bold"))
        style.configure("SubHeader.TLabel", font=("Segoe UI", int(10 * s), "bold"))
        style.configure("Treeview", font=("Segoe UI", int(10 * s)), rowheight=int(30 * s))
        style.configure("Treeview.Heading", font=("Segoe UI", int(10 * s), "bold"))
        style.configure("TButton", font=("Segoe UI", int(10 * s), "bold"), padding=int(8 * s))
        style.configure("TCombobox", font=("Segoe UI", int(10 * s)))
        
        # 2. Update Direct Widget Attributes
        self.context_text.configure(font=("Consolas", int(12 * s)))
        self.meaning_text.configure(font=("Segoe UI", int(11 * s)))
        self.obs_text.configure(font=("Segoe UI", int(11 * s)))
        self.search_entry.configure(font=("Segoe UI", int(11 * s)))
        self.group_combo.configure(font=("Segoe UI", int(10 * s)))
        self.priority_combo.configure(font=("Segoe UI", int(10 * s)))
        self.file_combo.configure(font=("Segoe UI", int(11 * s), "bold"))
        
        # Popup font for comboboxes
        self.root.option_add("*TCombobox*Listbox.font", ("Segoe UI", int(11 * s)))
        
        # Scrollbar width
        self.v_scroll.configure(width=int(20 * s))
        
        # Refresh current view
        if self.current_tag:
            self.on_tag_select(None)

    def zoom_in(self):
        self.ui_scale += 0.2
        self.apply_scale()

    def zoom_out(self):
        if self.ui_scale > 0.6:
            self.ui_scale -= 0.2
            self.apply_scale()

    def setup_bindings(self):
        self.root.bind("<Control-plus>", lambda e: self.zoom_in())
        self.root.bind("<Control-equal>", lambda e: self.zoom_in())
        self.root.bind("<Control-minus>", lambda e: self.zoom_out())

    def refresh_all_data(self):
        """Manually reloads both Excel and Tag files."""
        self.status_lbl.configure(text="Refreshing data...")
        self.load_data()
        messagebox.showinfo("Refresh", "Data successfully reloaded from Excel and Tags file.")

    def load_data(self):
        # 1. Reset Internal State
        self.tag_to_files = {}
        self.all_tags = []
        
        # 2. Load Excel Data
        if os.path.exists(self.excel_file):
            try:
                self.df_excel = pd.read_excel(self.excel_file)
                cols = self.df_excel.columns
                # Ensure at least 5 columns exist (Tag, Meaning, Group, Priority, Obs)
                while len(self.df_excel.columns) < 5:
                    self.df_excel[f"Col_{len(self.df_excel.columns)}"] = ""
                
                if len(cols) > 2:
                    self.group_combo['values'] = sorted([str(x) for x in self.df_excel.iloc[:, 2].unique() if pd.notna(x)])
                if len(cols) > 3:
                    self.priority_combo['values'] = sorted([str(x) for x in self.df_excel.iloc[:, 3].unique() if pd.notna(x)])
            except Exception as e:
                print(f"Excel Load Error: {e}")
                self.df_excel = pd.DataFrame(columns=["Tag", "Meaning", "Group", "Priority", "Observation"])

        # 3. Load Tag Mapping and Auto-Merge
        if os.path.exists(self.tags_file):
            try:
                with open(self.tags_file, "r") as f:
                    cf = None
                    for line in f:
                        line = line.rstrip()
                        if not line or line.startswith("Select"): continue
                        if line.startswith(" "):
                            tag = line.strip()
                            if cf:
                                if tag not in self.tag_to_files: self.tag_to_files[tag] = []
                                self.tag_to_files[tag].append(cf)
                        else: cf = line
                
                self.all_tags = sorted(list(self.tag_to_files.keys()))
                
                # Auto-Merge: If tag from txt is not in Excel, add a row
                if self.df_excel is not None:
                    tag_col = self.df_excel.columns[0]
                    # Normalize existing tags for comparison (stripped and lower)
                    existing_tags_map = {str(t).strip().lower(): str(t) for t in self.df_excel[tag_col].tolist()}
                    
                    new_rows = []
                    for t in self.all_tags:
                        norm_t = t.strip().lower()
                        if norm_t not in existing_tags_map:
                            # Create a blank row for this new tag
                            new_row = {c: "" for c in self.df_excel.columns}
                            new_row[tag_col] = t
                            new_rows.append(new_row)
                            # Add to map to prevent duplicates within this loop
                            existing_tags_map[norm_t] = t
                    
                    if new_rows:
                        self.df_excel = pd.concat([self.df_excel, pd.DataFrame(new_rows)], ignore_index=True)
                        print(f"Merged {len(new_rows)} new tags into internal model.")

                self.update_tag_list()
                threading.Thread(target=self.scan_total_occurrences, daemon=True).start()
                self.status_lbl.configure(text=f"Loaded {len(self.all_tags)} tags.")
            except Exception as e:
                print(f"Tag File Load Error: {e}")

    def scan_total_occurrences(self):
        counts = {}
        unique_files = set()
        for f_list in self.tag_to_files.values():
            for f in f_list: unique_files.add(f)
        
        for fp in unique_files:
            if not os.path.exists(fp): continue
            try:
                with open(fp, "r") as f:
                    content = f.read()
                    for tag in self.all_tags:
                        c = content.count(f'dictRef="{tag}"') + content.count(f"dictRef='{tag}'")
                        if c > 0: counts[tag] = counts.get(tag, 0) + c
            except: pass
        self.tag_total_counts = counts
        self.root.after(0, lambda: self.update_tag_list(self.search_var.get()))

    def update_tag_list(self, ft=""):
        # Clear Tree
        for item in self.tree.get_children(): self.tree.delete(item)
        
        for t in self.all_tags:
            if ft.lower() in t.lower():
                files = self.tag_to_files.get(t, [])
                occ = self.tag_total_counts.get(t, len(files))
                f_count = len(set(files))
                self.tree.insert("", tk.END, values=(t, occ, f_count))

    def filter_tags(self, *args):
        self.update_tag_list(self.search_var.get())

    def on_tag_select(self, event):
        sel = self.tree.selection()
        if not sel: return
        self.current_tag = self.tree.item(sel[0])['values'][0]
        self.current_files = sorted(list(set(self.tag_to_files.get(self.current_tag, []))))
        
        options = ["[ SUMMARY HOME ]"] + [os.path.basename(f) for f in self.current_files]
        self.file_combo['values'] = options
        self.file_combo.current(0)
        self.on_file_selected(None)
        
        # Load Metadata
        meaning, group, priority, obs = "N/A", "", "", ""
        if self.df_excel is not None:
            cols = self.df_excel.columns
            # Robust matching: strip and lower
            tag_col_data = self.df_excel[cols[0]].astype(str).str.strip().str.lower()
            match = self.df_excel[tag_col_data == self.current_tag.strip().lower()]
            
            if not match.empty:
                row = match.iloc[0]
                if len(cols) > 1: meaning = str(row.iloc[1]) if pd.notna(row.iloc[1]) else "N/A"
                if len(cols) > 2: group = str(row.iloc[2]) if pd.notna(row.iloc[2]) else ""
                if len(cols) > 3: priority = str(row.iloc[3]) if pd.notna(row.iloc[3]) else ""
                if len(cols) > 4: obs = str(row.iloc[4]) if pd.notna(row.iloc[4]) else ""
        
        self.group_combo.set(group)
        self.priority_combo.set(priority)
        self.meaning_text.delete("1.0", tk.END); self.meaning_text.insert(tk.END, meaning)
        self.obs_text.delete("1.0", tk.END); self.obs_text.insert(tk.END, obs)
        
        self.update_sidebar_analysis()

    def on_file_selected(self, event):
        idx = self.file_combo.current()
        if idx <= 0:
            threading.Thread(target=self.load_summary, args=(self.current_tag, self.current_files), daemon=True).start()
        else:
            threading.Thread(target=self.load_file_content, args=(self.current_tag, self.current_files[idx-1]), daemon=True).start()

    def load_summary(self, tag_name, files):
        data = []
        for fp in files:
            try:
                with open(fp, "r") as f:
                    lines = f.readlines()
                    for i, l in enumerate(lines):
                        if f'dictRef="{tag_name}"' in l or f"dictRef='{tag_name}'" in l:
                            s, e = max(0, i-self.context_lines), min(len(lines), i+self.context_lines+1)
                            data.append((fp, i+1, "".join(lines[s:e])))
            except: pass
        self.root.after(0, lambda: self.render_summary(tag_name, data))

    def render_summary(self, tag_name, data):
        self.context_text.config(state=tk.NORMAL)
        self.context_text.delete("1.0", tk.END)
        
        # Tags for XML
        s = self.ui_scale
        self.context_text.tag_configure("highlight", background=self.colors["tag_highlight"], foreground=self.colors["fg_bright"])
        self.context_text.tag_configure("path_header", foreground=self.colors["xml_path"], font=("Consolas", int(11 * s), "bold"))
        self.context_text.tag_configure("line_num", foreground=self.colors["xml_line"], font=("Consolas", int(10 * s)))
        
        for path, ln, snip in data:
            self.context_text.insert(tk.END, f" FILE: {path}\n", "path_header")
            self.context_text.insert(tk.END, f" LINE: {ln}\n", "line_num")
            self.context_text.insert(tk.END, " " + "-"*40 + "\n", "line_num")
            
            start = self.context_text.index(tk.INSERT)
            self.context_text.insert(tk.END, snip + "\n")
            end = self.context_text.index(tk.INSERT)
            
            curr = start
            while True:
                found = self.context_text.search(tag_name, curr, stopindex=end)
                if not found: break
                te = f"{found}+{len(tag_name)}c"
                self.context_text.tag_add("highlight", found, te)
                curr = te
            self.context_text.insert(tk.END, "\n" + "═"*60 + "\n\n", "line_num")
        
        self.context_text.config(state=tk.DISABLED)

    def load_file_content(self, tag_name, fp):
        try:
            with open(fp, "r") as f: content = f.read()
        except: content = "Error loading file."
        self.root.after(0, lambda: self.render_content(tag_name, content))

    def render_content(self, tag_name, content):
        self.context_text.config(state=tk.NORMAL)
        self.context_text.delete("1.0", tk.END)
        self.context_text.tag_configure("highlight", background=self.colors["tag_highlight"], foreground=self.colors["fg_bright"])
        self.context_text.insert(tk.END, content)
        
        curr = "1.0"; first = None
        while True:
            found = self.context_text.search(tag_name, curr, stopindex=tk.END)
            if not found: break
            if not first: first = found
            te = f"{found}+{len(tag_name)}c"
            self.context_text.tag_add("highlight", found, te)
            curr = te
        if first: self.context_text.see(first); self.context_text.yview_scroll(-5, tk.UNITS)
        self.context_text.config(state=tk.DISABLED)

    def update_sidebar_analysis(self):
        # Clear previous blocks
        for widget in self.analysis_container.winfo_children(): widget.destroy()
        
        links = sorted(list(set(os.path.basename(f).split('.')[0] for f in self.current_files)))
        s = self.ui_scale
        
        for l in links:
            # Create a block for each link
            block = ttk.Frame(self.analysis_container, style="Card.TFrame", padding=10)
            block.pack(fill=tk.X, pady=5)
            
            lbl_l = ttk.Label(block, text=f"Link {l.upper()}", foreground=self.colors["link_header"], font=("Segoe UI", int(10 * s), "bold"))
            lbl_l.pack(anchor="w")
            
            desc = self.link_meanings.get(l, "Specific module for this calculation stage.")
            lbl_d = ttk.Label(block, text=desc, wraplength=int(300 * s), justify="left")
            lbl_d.pack(anchor="w", pady=(5, 0))
            
            ttk.Frame(self.analysis_container, height=1, style="TFrame").pack(fill=tk.X, pady=5) # Separator

    def save_data_to_excel(self):
        if self.current_tag is None or self.df_excel is None: return
        try:
            new_m = self.meaning_text.get("1.0", tk.END).strip()
            new_g = self.group_combo.get().strip()
            new_p = self.priority_combo.get().strip()
            new_o = self.obs_text.get("1.0", tk.END).strip()
            
            cols = self.df_excel.columns
            # Robust matching: strip and lower
            tag_col_data = self.df_excel[cols[0]].astype(str).str.strip().str.lower()
            mask = tag_col_data == self.current_tag.strip().lower()
            
            if any(mask):
                if len(cols) > 1: self.df_excel.loc[mask, cols[1]] = new_m
                if len(cols) > 2: self.df_excel.loc[mask, cols[2]] = new_g
                if len(cols) > 3: self.df_excel.loc[mask, cols[3]] = new_p
                if len(cols) > 4: self.df_excel.loc[mask, cols[4]] = new_o
            else:
                row = {cols[0]: self.current_tag}
                if len(cols) > 1: row[cols[1]] = new_m
                if len(cols) > 2: row[cols[2]] = new_g
                if len(cols) > 3: row[cols[3]] = new_p
                if len(cols) > 4: row[cols[4]] = new_o
                self.df_excel = pd.concat([self.df_excel, pd.DataFrame([row])], ignore_index=True)
            
            self.df_excel.to_excel(self.excel_file, index=False)
            messagebox.showinfo("Success", f"Metadata for '{self.current_tag}' synchronized.")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to save: {e}")

if __name__ == "__main__":
    root = tk.Tk()
    app = TagExplorerV4(root)
    root.mainloop()

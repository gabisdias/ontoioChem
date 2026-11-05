import os
import tkinter as tk
from tkinter import ttk, messagebox
import threading
import pandas as pd

class TagExplorerV7:
    def __init__(self, root):
        self.root = root
        self.root.title("ioChem-BD Gaussian Tag Explorer - V7")
        self.root.geometry("1600x1000")

        # Configuration and State
        self.tags_file = "gaussian-tags-file.txt"
        self.excel_file = "Ontology mapping reference 2.xlsx"
        self.tag_to_files = {}
        self.tag_meanings = {}
        self.all_tags = []
        
        # Base scale factor - adjusted for high-res screens
        self.base_font_size = 36 
        self.context_lines = 3
        self.current_tag = None
        self.current_files = []

        self.link_meanings = {
            "l1": "Route & Initializer: Processes the route section (#), builds the list of links to execute, and initializes scratch files.",
            "l101": "Molecule Spec: Reads the title and molecule specification (Geometry, Charge, Multiplicity).",
            "l202": "Symmetry & Reorientation: Reorients coordinates and calculates molecular symmetry.",
            "l301": "Basis Set & Integrals: Generates basis set information and handles ECP.",
            "l401": "Initial Guess: Forms the initial molecular orbital (MO) guess.",
            "l502": "SCF Iterations: Iteratively solves the Self-Consistent Field (SCF) equations.",
            "l50X": "SCF Specialized: SCF variant or convergence control.",
            "l601": "Population Analysis: Performs Mulliken/NBO population analysis and multipole moments.",
            "l701": "Derivatives: Calculates forces and gradients.",
            "l801": "Integral Transformation: Transformation for post-SCF methods (MP2, CCSD).",
            "l925": "Excited States: Implements EET model and CIS/TD-DFT transitions.",
            "jobcpu": "Performance Summary: Summary of CPU usage and execution time.",
            "entering": "Control Flow: Marks transition between different execution links."
        }

        self.colors = {
            "bg": "#1e1e1e",
            "fg": "#d4d4d4",
            "header_bg": "#333333",
            "list_bg": "#252526",
            "list_fg": "#cccccc",
            "accent": "#0e639c",
            "highlight": "#4b4b00",
            "warning": "#f44747",
            "info": "#b5cea8",
            "file_header": "#4ec9b0",
            "link_header": "#ce9178",
            "meaning_fg": "#dcdcaa"
        }

        self.setup_ui()
        self.apply_global_styles() # Initial scale application
        self.load_data()
        self.setup_bindings()

    def apply_global_styles(self):
        """Applies the current font size to all styles and widgets."""
        s = self.base_font_size
        
        style = ttk.Style()
        style.theme_use('clam')
        
        # Global Font definitions
        font_main = ("Helvetica", s // 2)
        font_bold = ("Helvetica", s // 2, "bold")
        font_mono = ("Consolas", s // 2)
        font_small = ("Helvetica", max(12, s // 3))
        font_status = ("Helvetica", max(10, s // 4))

        # ttk Styles
        style.configure("TFrame", background=self.colors["bg"])
        style.configure("TLabel", background=self.colors["bg"], foreground=self.colors["fg"], font=font_main)
        style.configure("Header.TLabel", background=self.colors["header_bg"], font=font_bold)
        style.configure("TEntry", fieldbackground=self.colors["list_bg"], foreground=self.colors["fg"], font=font_main)
        style.configure("TButton", font=font_main)
        style.configure("TCombobox", fieldbackground=self.colors["list_bg"], foreground="black", font=font_main)
        style.configure("Status.TLabel", background=self.colors["header_bg"], font=font_status)

        # Update non-ttk widgets manually
        self.tag_listbox.configure(font=font_mono)
        self.context_text.configure(font=font_mono)
        self.analysis_text.configure(font=font_small)
        self.search_entry.configure(font=font_main)
        
        # Update combobox list font (the popup)
        self.root.option_add("*TCombobox*Listbox.font", font_main)

        # Force update of labels if they aren't using styles properly
        self.file_label.configure(font=font_main)

    def setup_ui(self):
        self.root.configure(bg=self.colors["bg"])
        
        # Top Control Bar
        ctrl_frame = ttk.Frame(self.root)
        ctrl_frame.pack(fill=tk.X, padx=5, pady=5)
        ttk.Label(ctrl_frame, text="Global Zoom Control: ").pack(side=tk.LEFT, padx=5)
        ttk.Button(ctrl_frame, text="Increase Font (+)", command=self.zoom_in).pack(side=tk.LEFT, padx=2)
        ttk.Button(ctrl_frame, text="Decrease Font (-)", command=self.zoom_out).pack(side=tk.LEFT, padx=2)

        self.main_paned = ttk.PanedWindow(self.root, orient=tk.HORIZONTAL)
        self.main_paned.pack(fill=tk.BOTH, expand=True)

        # 1. Left Column: Tag List
        left_frame = ttk.Frame(self.main_paned)
        self.main_paned.add(left_frame, weight=1)
        ttk.Label(left_frame, text="Tags List", style="Header.TLabel").pack(fill=tk.X, padx=5, pady=5)
        
        self.search_var = tk.StringVar()
        self.search_var.trace("w", self.filter_tags)
        self.search_entry = ttk.Entry(left_frame, textvariable=self.search_var)
        self.search_entry.pack(fill=tk.X, padx=5, pady=5)
        
        self.tag_listbox = tk.Listbox(left_frame, bg=self.colors["list_bg"], fg=self.colors["list_fg"], highlightthickness=0, border=0)
        self.tag_listbox.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        self.tag_listbox.bind("<<ListboxSelect>>", self.on_tag_select)

        # 2. Middle Column: File Browser / Summary
        mid_frame = ttk.Frame(self.main_paned)
        self.main_paned.add(mid_frame, weight=4)
        
        file_sel_frame = ttk.Frame(mid_frame)
        file_sel_frame.pack(fill=tk.X, padx=10, pady=5)
        self.file_label = ttk.Label(file_sel_frame, text="Current View: ")
        self.file_label.pack(side=tk.LEFT)
        self.file_combo = ttk.Combobox(file_sel_frame, state="readonly")
        self.file_combo.pack(side=tk.LEFT, fill=tk.X, expand=True)
        self.file_combo.bind("<<ComboboxSelected>>", self.on_file_selected)

        # Context Text (Full file or Summary)
        self.context_text = tk.Text(mid_frame, wrap=tk.WORD, bg=self.colors["list_bg"], fg=self.colors["fg"], 
                                    insertbackground="white", border=0)
        self.context_text.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)
        v_scroll = ttk.Scrollbar(mid_frame, orient=tk.VERTICAL, command=self.context_text.yview)
        v_scroll.pack(side=tk.RIGHT, fill=tk.Y)
        self.context_text.configure(yscrollcommand=v_scroll.set)

        # 3. Right Column: Sidebar
        right_frame = ttk.Frame(self.main_paned)
        self.main_paned.add(right_frame, weight=2)
        ttk.Label(right_frame, text="Detailed Analysis", style="Header.TLabel").pack(fill=tk.X, padx=5, pady=5)
        self.analysis_text = tk.Text(right_frame, wrap=tk.WORD, bg=self.colors["header_bg"], fg=self.colors["fg"], border=0, padx=10, pady=10)
        self.analysis_text.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        self.analysis_text.config(state=tk.DISABLED)

        self.status_var = tk.StringVar(value="Ready")
        ttk.Label(self.root, textvariable=self.status_var, relief=tk.SUNKEN, anchor=tk.W, style="Status.TLabel").pack(side=tk.BOTTOM, fill=tk.X)

    def setup_bindings(self):
        self.root.bind("<Control-plus>", lambda e: self.zoom_in())
        self.root.bind("<Control-equal>", lambda e: self.zoom_in())
        self.root.bind("<Control-minus>", lambda e: self.zoom_out())

    def zoom_in(self):
        self.base_font_size += 4
        self.apply_global_styles()
        if self.current_tag: self.on_tag_select(None)

    def zoom_out(self):
        if self.base_font_size > 12:
            self.base_font_size -= 4
            self.apply_global_styles()
            if self.current_tag: self.on_tag_select(None)

    def load_data(self):
        if os.path.exists(self.excel_file):
            try:
                df = pd.read_excel(self.excel_file)
                tc, mc = df.columns[0], df.columns[1]
                for _, r in df.iterrows():
                    self.tag_meanings[str(r[tc]).strip()] = str(r[mc]).strip()
            except: pass

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
                self.update_tag_list()
            except: pass

    def update_tag_list(self, ft=""):
        self.tag_listbox.delete(0, tk.END)
        for t in self.all_tags:
            if ft.lower() in t.lower(): self.tag_listbox.insert(tk.END, t)

    def filter_tags(self, *args):
        self.update_tag_list(self.search_var.get())

    def on_tag_select(self, event):
        sel = self.tag_listbox.curselection()
        if not sel: return
        self.current_tag = self.tag_listbox.get(sel[0])
        self.current_files = sorted(list(set(self.tag_to_files.get(self.current_tag, []))))
        
        options = ["[ SUMMARY / HOME ]"] + [os.path.basename(f) for f in self.current_files]
        self.file_combo['values'] = options
        self.file_combo.current(0)
        self.on_file_selected(None)
        self.update_sidebar()

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
        self.context_text.tag_configure("highlight", background=self.colors["highlight"], foreground="white")
        self.context_text.tag_configure("file_path", foreground=self.colors["file_header"], font=("Consolas", max(14, self.base_font_size // 4), "bold"))
        
        for path, ln, snip in data:
            self.context_text.insert(tk.END, f"FILE: {path}\n", "file_path")
            self.context_text.insert(tk.END, f"LINE: {ln}\n", "Status.TLabel")
            start = self.context_text.index(tk.INSERT)
            self.context_text.insert(tk.END, snip + "\n" + "="*40 + "\n\n")
            end = self.context_text.index(tk.INSERT)
            
            curr = start
            while True:
                found = self.context_text.search(tag_name, curr, stopindex=end)
                if not found: break
                te = f"{found}+{len(tag_name)}c"
                self.context_text.tag_add("highlight", found, te)
                curr = te
        self.context_text.config(state=tk.DISABLED)

    def load_file_content(self, tag_name, fp):
        try:
            with open(fp, "r") as f: content = f.read()
        except: content = "Error."
        self.root.after(0, lambda: self.render_content(tag_name, content))

    def render_content(self, tag_name, content):
        self.context_text.config(state=tk.NORMAL)
        self.context_text.delete("1.0", tk.END)
        self.context_text.tag_configure("highlight", background=self.colors["highlight"], foreground="white")
        self.context_text.insert(tk.END, content)
        
        curr = "1.0"
        first = None
        while True:
            found = self.context_text.search(tag_name, curr, stopindex=tk.END)
            if not found: break
            if not first: first = found
            te = f"{found}+{len(tag_name)}c"
            self.context_text.tag_add("highlight", found, te)
            curr = te
        if first:
            self.context_text.see(first)
            self.context_text.yview_scroll(-5, tk.UNITS)
        self.context_text.config(state=tk.DISABLED)

    def update_sidebar(self):
        links = set(os.path.basename(f).split('.')[0] for f in self.current_files)
        self.analysis_text.config(state=tk.NORMAL)
        self.analysis_text.delete("1.0", tk.END)
        self.analysis_text.tag_configure("section", foreground=self.colors["file_header"], font=("Helvetica", self.base_font_size // 3, "bold"))
        self.analysis_text.tag_configure("link_title", foreground=self.colors["link_header"], font=("Helvetica", max(10, self.base_font_size // 4), "bold"))

        self.analysis_text.insert(tk.END, "TAG MEANING:\n", "section")
        self.analysis_text.insert(tk.END, f"{self.tag_meanings.get(self.current_tag, 'N/A')}\n\n")
        self.analysis_text.insert(tk.END, "GAUSSIAN STAGES:\n", "section")
        for l in sorted(list(links)):
            self.analysis_text.insert(tk.END, f"Link {l}:\n", "link_title")
            self.analysis_text.insert(tk.END, f"{self.link_meanings.get(l, 'Gaussian module.')}\n\n")
        self.analysis_text.config(state=tk.DISABLED)

if __name__ == "__main__":
    root = tk.Tk()
    app = TagExplorerV7(root)
    root.mainloop()

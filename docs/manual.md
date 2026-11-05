# OntoIochem: Minimum Viable Ontology and Semantic Layer Manual

**Reference:** OntoIochem v11, revised 8 October 2026.  
**Audience:** computational chemists, ioChem-BD developers and metadata specialists.  
**Scope:** development rationale, tag mapping, current classes and properties, validation, and implementation requirements.

## 1. Purpose and present status

OntoIochem provides a common vocabulary for describing computational chemistry data managed by ioChem-BD. Its immediate purpose is scientific discovery: finding calculations by combining chemical composition, calculation methodology, computed quantities and publication metadata. For example, a user should eventually be able to search for selenium-containing molecular systems whose HOMO energy exceeds a specified threshold.

This release is a first minimum viable model. It contains the concepts and relationships judged essential during the present development cycle. It records deliberate choices, rather than claiming a unique or universally optimal classification of computational chemistry. Several valid ontology architectures could support the same scientific questions. Here, the working preference was for a small, understandable set of relationships and reusable value representations.

The OWL file defines the vocabulary and logical axioms. A deployed semantic layer additionally needs mappings from parsed records, stable identifiers, an RDF data population process and a query service. A natural-language interface would translate scientific requests into queries over that populated graph. The ontology alone does not extract outputs or create a search index.

The current file has **71 named classes, 39 object properties, 25 datatype properties and 203 named individuals**. These counts include the four organizational object superproperties and four datatype superproperties. Named individuals already in the ontology include controlled vocabulary entries; they are not 203 demonstrated repository calculations. The file is serialized as RDF/XML. Changing its extension from `.owl` to `.rdf` does not change its semantics.

## 2. Development route and choice of foundation

The work began with a review of existing semantic resources for computational chemistry, including Gainesville Core and OntoCompChem. Gainesville Core, represented in this project by `gc07.owl` and the namespace `http://purl.org/gc/`, was selected as the principal structural reference. Its distinction between molecular concepts, calculation concepts, publication concepts and auxiliary concepts provided a useful starting point for the ioChem-BD scope.

OntoCompChem was a relevant comparison because its published development connects Gainesville Core with the CML CompChem convention and Gaussian quantum chemistry calculations [1]. The project required a vocabulary spanning Gaussian, ORCA and ADF, so Gainesville's broader conceptual organization was retained as the foundation. This was a project-specific choice of fit and maintainability, not a demonstration that Gainesville is intrinsically superior to every alternative. The complete initial comparison matrix is outside the evidence supplied for this manual.

The supplied `cc_conceptual_map2.pdf` records a broad conceptual map of the reference framework. It displays the four main areas alongside a much larger space of quantum-mechanical methods, functionals, basis sets, molecular objects and result types. The map was an exploratory instrument, not the final OWL class inventory. Its associated `cmap` and `project.idx` files were also supplied as native serialized concept-map/project records; the PDF was the readable source used to inspect the diagram. A conceptual map was constructed from the reference ontology. It identified the main entities and distinguished class specialization from scientific relationships. A computational method, a basis set, a molecular system and a calculated energy are different kinds of information, even when they appear together in a program output. This map guided the selection of concepts actually needed to describe ioChem-BD data.

The development then followed the sequence below:

1. Select the computational chemistry concepts relevant to the platform.
2. Investigate their corresponding terms and extraction contexts in XML conversion files for Gaussian, ADF and ORCA.
3. Extract, inspect, group and prioritize parser tags; compile a cross-program mapping table.
4. Relate those tags to ontology entities and preserve their source context.
5. Adapt the Gainesville-based structure and remove concepts outside the chosen scope.
6. Review names, scientific definitions and class organization.
7. Define object properties connecting the retained entities.
8. Define datatype properties and consolidate numerical values, vectors and text descriptors.
9. Run structural and logical checks; document unresolved implementation questions.

The review progressively standardized names (v6), introduced the Value model (v7), simplified object properties (v8), consolidated datatype properties (v9), added structural and naming descriptors (v10), and placed those descriptors consistently in MolecularDescription while removing the Smiles class (v11). The user-reviewed changes to MolecularSystem and output coordinates were incorporated between these revisions. The filename sequence and the embedded versionIRI are separate identifiers; the current v11 file still carries versionInfo 0.8.0.

This was iterative. The tag inventory informed the ontology, and the ontology in turn constrained which tags could be mapped without introducing unsupported concepts. A high-priority parser tag was not sufficient reason to create a new class. Kinetic and potential energies, for example, were removed from the retained property scope when their corresponding entities were not part of the agreed model.

## 3. Reading the terminology

| Term | Meaning in this project | Example |
|---|---|---|
| Class | A type of entity in the model | `MolecularSystem`, `ElectronicEnergy`, `FloatValue` |
| Individual | A particular instance of a class | One calculation, one coordinate record, one numerical-value node |
| Object property | A relationship between individuals | A calculation `usesBasisSet` a basis-set individual |
| Datatype property | A relationship from an individual to a literal | A `FloatValue` has the literal `1.25` through `hasFloatValue` |
| Literal | A text, number, date or other typed value | `"InChI=..."^^xsd:string` |
| IRI | A machine identifier for a class, property or individual | `http://purl.org/iochem/inchi` |
| Domain / range | Types inferred for the subject / object of a property | `hasAtom`: `MolecularSystem` to `Atom` |
| Subclass axiom | A logical “is a” statement | Every `FloatValue` is a `Value` |
| Subproperty axiom | Specialization of a relationship | `hasVectorRepresentation` specializes `hasNumericalValue` |
| Parser tag | A field identifier or structural location in extraction/conversion material | `cc:eener`, `x:coords`, or a CML `atomArray` |
| RDF | Graph data model expressed as subject–predicate–object statements | A calculation uses a basis set |
| OWL | Language for defining ontology classes, properties and logical axioms over RDF | Class hierarchies and coordinate restrictions |
| CML | Chemical Markup Language, the structured representation used in the conversion workflow | An atom array or dictionary-referenced scalar |
| SPARQL | Query language for RDF graphs | Filter calculations by element and energy |

A class tree is not simply a folder tree. If `CoordinatesInput` is a subclass of `MolecularSystem`, every coordinate-input individual is logically also a molecular-system individual. Domain and range declarations similarly infer types; they do not function like form-validation rules that reject every incorrectly typed entry. These distinctions matter when interpreting the current organization.

The naming convention uses PascalCase without spaces for class names. Technical identifiers such as basis-set and functional names retain their established spellings. Human-readable property labels use lowercase words and spaces; property IRIs remain compact identifiers such as `hasCoordinatesOutput` or `inchiKey`. Labels and IRIs should not be confused when implementing mappings.

## 4. XML tags, CML context and prioritization

The supplied workbook, **`mappings/ontology-mapping-reference.xlsx`** (originally `Ontology Mapping Reference (3).xlsx`), contains three worksheets. **The second worksheet, `30 entities`, was the working reference used to select and relate concepts across Gaussian, ADF and ORCA.** The first worksheet is an earlier discovery inventory, not the final ontology inclusion list:

| Worksheet | Content inspected | Interpretation |
|---|---|---|
| `gaussian_total` | 373 tag entries with meaning, group, priority and observations | Gaussian discovery inventory |
| `30 entities` | 56 non-header entries, including metadata and units | Working cross-program correspondence table; the title is not a reliable row count |
| `Gaussian energies` | 25 nonempty rows of values and notes | Exploratory numerical notes, not a general conversion specification |

The earlier Gaussian inventory assigns 68 entries to priority 1, 74 to priority 2 and 231 to priority 3. Its groups are calculation metadata, molecular description, calculated properties, provenance and unknown. These statistics describe discovery work, not the final retained scope. The second worksheet brings together 32 computational targets, ten publication/descriptor metadata entries and 14 unit-related entries; despite its title, it contains more than 30 entities.

The working selection was reviewed by scientific relevance, source context and usefulness to the proposed semantic layer. The code supports manual assignment of meanings, groups and priorities; it does not compute an automatic scientific ranking. Some entries were removed later to preserve the essential scope. A priority label records a curation decision, not implementation coverage or chemical equivalence across programs.

A mapping needs more than a tag string. CML associates meaning with dictionary references, conventions and units [2]. The same local name can occur in different sections, software namespaces or steps of a calculation. A record should retain the namespace binding, source file, template/module context, input or output role, datatype and unit. Names beginning `cc:`, `g:`, `o:`, `a:` or `x:` are qualified identifiers whose interpretation depends on the document's namespace declarations.

The extraction and prioritization work was described by the project as a code-supported process: inventory XML tags, check their context, group related information, prioritize it and export a reference table. The supplied scripts clarify how this review was supported:

### The tools used for tag exploration

`searchTag.sh` locates a requested `dictRef` inside ioChem-BD XML conversion templates. It checks for a local `iochem-bd` checkout, clones the repository if absent, prompts for a software format and tag, then prints matching XML filenames and line numbers. Its search root is `jumbo-converters/jumbo-converters-compchem/jumbo-converters-compchem-<format>`. ADF, Gaussian and ORCA are among the selectable formats. This connects a semantic candidate to the conversion rule and surrounding program-output context.

`tag_explorer_v5.py` is a Tkinter review application. It reads a tag-to-file index, `gaussian-tags-file.txt`, and an Excel inventory configured as `Ontology Mapping Reference 2.xlsx`. The supplied workbook has a later filename; paths must be configured before reuse. The explorer:

- builds a searchable list of tags and associated files;
- counts literal `dictRef` occurrences, accepting single or double quotes;
- shows a summary with three lines of context on either side of each match, or the full XML file with matches highlighted;
- displays Gaussian stage descriptions based on template filename prefixes;
- lets the reviewer edit meaning, group, priority and observations;
- flags missing meaning, group or priority and marks fully annotated entries as reviewed;
- appends previously unlisted tags to its working inventory and saves annotations to Excel.

These operations support contextual validation by a chemist. The review checklist checks annotation completeness, not the scientific correctness of a mapping. Occurrence counts describe template text, not how frequently a value appears in repository calculations. Neither supplied script converts numerical outputs into RDF or automatically validates units, orbital selection or energy conventions. The supplied explorer consumes an existing index; the separate process that originally generated that index was not supplied.

The code reads the first Excel sheet by default and writes its DataFrame back as a single-sheet workbook. It therefore supports inventory annotation, while the second-sheet cross-program mapping is a separately curated reference. For reuse, keep a working copy and preserve the multi-sheet reference; supporting a particular sheet and retaining all sheets would require an explicit code change. The scripts were inspected for this manual; their GUI and repository-cloning workflow were not executed.


## 5. Priority tags and mapping examples

The following table transcribes representative entries from `30 entities`. **These are navigation references for a developer, not necessarily the exact final scalar to extract.** An orbital-occupation tag can identify the block containing the energies needed to determine HOMO/LUMO; an atom-array reference can identify structural information used in another derivation. Whitespace surrounding tag names is trimmed for readability; unresolved locations remain visible. Earlier class paths containing `Molecule` or `Smiles` must be reconciled with v11 rather than copied into a new implementation.

| Ontology target | Gaussian candidate | ADF candidate | ORCA candidate | Source context / review |
|---|---|---|---|---|
| `AtomCount` | `cc:atomcount` | `?` | `atomArray count` | Workbook: `l301.bais2.xml`; structural block; atom count can be derived from a complete atom array |
| `AtomicNumber` | `cc:atomicNumber` | `cc:atomicNumber` | `cc:atomicNumber` | `l101.zmat3.xml`; verify element/atom context |
| `AtomicMass` | `cc:atomicmass` | `?` | `atomArray count` | `l716.xml`; structural locator; count itself is not the atomic mass |
| `BasisSet` | `cc:basis` | `cc:basis` | `cc:basis` | `l301.basis.xml`; normalize names while retaining the original label |
| `ElectronicEnergy` | `cc:eener` | `NONE` | `o:totalEnergy/totalener` | `l502.footer.xml`; distinguish final energy from iteration values |
| `BondingEnergy` | `NONE` | `results/bonding.energy.xml` reference | `NONE` | Template/file reference, not a scalar tag; reference state requires definition |
| `ChargeSum` | `x:chargesum` | `a:charge` | `x:chargesum` | `l601.mulliken.xml`; establish whether the field is input total charge or a population-charge sum |
| `CoordinatesInput` / `CoordinatesOutput` | `x:coords` | `x:coords` | `?` | `l502.pcm.xml`; context must distinguish input from output |
| `MolecularMass` | `cc:molmass` | `cc:molmass` | `cc:totalmass` | Gaussian file unresolved; do not confuse mass with atom count |
| `Dipole` | `x:dipole` | `x:dipole` | `cc:dipole` | `l601.multipole.xml`; identify vector components, units and reference frame |
| `Mulliken` | `cc:mulliken` | `x:charge` | `cc:mulliken` | File unresolved; identify atom indices and population-analysis type |
| `Program` / `ProgramVersion` | `cc:program` / `cc:version` | `cc:program` / `cc:programVersion` | `?` / `?` | Software metadata; ORCA extraction requires confirmation |
| `DensityFunctional` | `cc:method` | `cc:method` | `o:corrmethod` | `l9999.archive.xml`; a method string does not always denote a density functional |
| `HOMO` / `LUMO` | `cc:occupation` | `cc:mo.occupation` for HOMO | `o:occEnergy` for HOMO | `l601.orbital.closedshell.xml`; inspect the associated orbital-energy block |
| `ConvergenceStatus` | `g:converged` | `cc:scfConverged` | `o:scfener` | `l103.xml`; inspect surrounding SCF status, not just its energy |

`?` means unresolved in the workbook. `NONE` records the absence of a proposed correspondence in that table; it is not proof that the program cannot produce the quantity. Slash-separated alternatives, structural references and `href` values direct the developer to inspect the corresponding block. The implemented mapping must then select the actual value, role and unit.

The retained priority scope includes molecular composition and charge, coordinates, basis set, functional, program and version, selected system energies, dipole, polarizability, Mulliken analysis, convergence and publication metadata. Representative thermochemical and structural locators in the working sheet include:

| Retained target | Gaussian | ADF | ORCA |
|---|---|---|---|
| `ThermalEnergy` | `cc:zpe.sumelectthermal` | Not specified | `o:thermalcorrenthalpy` |
| `ThermalEntalpy` | `cc:zpe.sumelectthermalent` | Not specified | `o:totalenthalpy` |
| `FreeEnergy` | `cc:zpe.sumelectthermalfe` | Not specified | `o:gibbsenthalpy` |
| `ZPEenergy` | `cc:zpe.sumelectzpe` | Not specified | `o:thermalcorr` |
| `TotalEntropy` | `cc:s.total` | `cc:total` | `o:totalentropycorr` |
| `DispersionEnergy` | `g:dispenergy` | `cc:dispener` | `o:dispersion` |
| `Stoichiometry` | `g:stoichiometry` | `?` | `?` |
| `ElementType` | `cc:elementType` | `cc:elementType` | `cc:elementType` |

The software-specific names above remain locators: a tag called a correction must not automatically be used as the final thermochemical total. The main Gaussian thermochemistry context is recorded as `1716.xml` in several rows, while another row uses `l716.xml`; filenames should be resolved against the checkout.

**Removed after selection:** separate ZPE correction, kinetic energy and potential energy. `ZPEenergy` retains the energy including the zero-point contribution; it is scientifically distinct from the correction alone. Removing the correction reduced the represented scope rather than asserting that both quantities are identical. Other discovery-stage targets without a final class, such as `IsotopeMass`, were not automatically imported into v11.

Publication information marked `metadata` in the mapping table comes from repository or publication records rather than necessarily from program output. SMILES, InChI and IUPAC names likewise may be supplied or generated separately. A parser job title and the user-assigned repository item name should not be silently treated as the same field.

## 6. Current class organization

The ontology retains four main areas. The tables below reproduce **named, direct subclass relationships in v11**. Anonymous restrictions are explained later. Prefixes distinguish exact IRIs: `gc:` is `http://purl.org/gc/`; `io:` is `http://purl.org/iochem/`; `onto:` is `http://purl.org/iochem/ontoiochem#`; `pt:` is the retained periodic-table namespace `http://www.daml.org/2003/01/periodictable/PeriodicTable#`.

### gc:AuxiliaryConcept

| Parent class | Direct subclasses |
|---|---|
| `gc:AuxiliaryConcept` | `io:ChemistryUnity`, `io:ElectricDipoleMomentUnit`, `io:EnergyAndWorkUnity`, `io:FreqUnity`, `io:Value` |
| `io:Value` | `io:FloatValue`, `io:IntegerValue`, `io:NaturalValue`, `io:VectorValue` |

### gc:CalculationConcept

| Parent class | Direct subclasses |
|---|---|
| `gc:CalculationConcept` | `io:CalculationResults`, `io:MetodologyFeature` |
| `io:CalculationResults` | `gc:CalculatedProperties`, `gc:CalculatedSystemProperties`, `gc:SystemEnergies`, `onto:CoordinatesOutput` |
| `gc:CalculatedProperties` | `io:AtomicProperties`, `io:CalculatedSystem` |
| `io:AtomicProperties` | `io:Mulliken` |
| `io:CalculatedSystem` | `io:Dipole`, `io:Polarizability` |
| `gc:CalculatedSystemProperties` | `io:ConvergenceStatus` |
| `gc:SystemEnergies` | `gc:ElectronicEnergy`, `io:BondingEnergy`, `io:DispersionEnergy`, `io:FreeEnergy`, `io:HOMO`, `io:LUMO`, `io:ThermalEnergy`, `io:ThermalEntalpy`, `io:TotalEntropy`, `io:ZPEenergy` |
| `io:MetodologyFeature` | `gc:BasisSet`, `gc:DensityFunctional`, `gc:ParameterSet`, `io:Program` |
| `gc:ParameterSet` | `io:Keywords` |
| `io:Program` | `io:ProgramVersion`, `onto:ProgramName` |
| `onto:ProgramName` | `onto:ADF`, `onto:Gaussian`, `onto:Orca` |

### gc:MolecularConcept

| Parent class | Direct subclasses |
|---|---|
| `gc:MolecularConcept` | `gc:MolecularStructureObject`, `pt:Element` |
| `gc:MolecularStructureObject` | `gc:Atom`, `gc:MolecularSystem` |
| `gc:MolecularSystem` | `io:AtomCount`, `io:ChargeSum`, `io:CoordinatesInput`, `io:MolecularDescription`, `io:MolecularMass`, `io:Stoichiometry` |
| `io:MolecularDescription` | `io:ElementType` |
| `pt:Element` | `gc:AtomicMass`, `io:AtomicNumber`, `io:MolarMass` |

### gc:PublicationConcept

| Parent class | Direct subclasses |
|---|---|
| `gc:PublicationConcept` | `gc:Publication`, `io:Authors`, `io:Institution` |
| `gc:Publication` | `io:CompChem`, `io:IssueDate` |
| `io:CompChem` | `io:Article`, `io:Data` |
| `io:Article` | `io:Journal` |
| `io:Data` | `io:Collection` |
| `io:Collection` | `io:Item`, `io:Subjects`, `io:URI` |


`MolecularSystem` replaced `Molecule` as the organizing concept, accommodating neutral and charged systems without making every record depend on the narrower molecule label. `CoordinatesInput` records starting positions; `CoordinatesOutput` belongs to calculation results. The latter does not by itself assert successful geometry optimization.

The current tree still contains descriptive quantities as subclasses of the entities they describe, and publication containers as subclasses of other containers. Thus `ChargeSum` and `MolecularDescription` are inferred as `MolecularSystem`, `Item` as `Collection`, and `Journal` as `Article`. `TotalEntropy` is grouped under `SystemEnergies` although it is not dimensionally an energy. These are acknowledged consequences of the retained minimum structure, not recommendations to reinterpret the scientific meaning of those quantities. Future restructuring would need explicit review and data migration.

Exact identifiers such as `MetodologyFeature`, `ThermalEntalpy` and `ZPEenergy` are retained here even where their spelling could be improved. Namespace reuse also needs care: retaining a Gainesville IRI while adapting its surrounding axioms does not prove equivalence to every published Gainesville version. The v11 file has no `owl:imports`; its external-looking identifiers do not load external ontologies automatically.

## 7. Object properties: a small set of meaningful connections

Object properties were defined after the principal entities had been selected. The guiding rule was that each relationship should express a necessary connection between individuals. Earlier versions contained many organizational properties mirroring individual class branches. These were simplified to four main groups: `auxiliaryProperty`, `molecularProperty`, `calculationProperty` and `publicationProperty`. Methodology belongs to the calculation group.

| Group | Properties, including specialized descendants |
|---|---|
| `io:auxiliaryProperty` | `io:hasComponentX`, `io:hasComponentY`, `io:hasComponentZ`, `io:hasNumericalValue`, `io:hasVectorRepresentation`, `io:unit` |
| `io:molecularProperty` | `io:coordinates`, `io:hasAtom`, `io:hasChargeSum`, `io:hasMolecularDescription`, `io:hasMolecularQuantity`, `io:isElement` |
| `io:calculationProperty` | `io:dipole`, `io:hasAtomicProperties`, `io:hasCalculationResult`, `io:hasCoordinatesOutput`, `io:hasEnergy`, `io:hasMolecularSystem`, `io:hasMulliken`, `io:hasParameterSet`, `io:hasPolarizability`, `io:hasSystemProperty`, `io:isPropertyOfAtom`, `io:usesBasisSet`, `io:usesDensityFunctional`, `io:usesMethod`, `io:usesProgram` |
| `io:publicationProperty` | `io:hasAuthor`, `io:hasCollection`, `io:hasFile`, `io:hasInstitution`, `io:hasItem`, `io:hasJournal`, `io:hasPublication`, `io:hasPublicationMetadata` |

The organizational roots have no domain, range or transitivity imposed. They organize the vocabulary without assigning additional types to their subjects. More specific properties use `subPropertyOf` where the meaning and inherited domain/range are compatible. For example, the range of `hasVectorRepresentation` is `VectorValue`, which specializes the `Value` range of `hasNumericalValue`.

One relationship can serve several scientific classes. `hasEnergy` connects a result to a quantity whose class identifies whether it is electronic energy, free energy, HOMO or another retained energy concept. The quantity then connects to its numerical-value node. This avoids a separate relationship for every energy subtype.

Relationship direction follows the main ingestion and query paths: a system has atoms; a calculation uses a program; a value has a unit. Labels generally use “has”, “uses” or “is”. These words are naming choices, not OWL operators. The model does not automatically declare every inverse relation. An inverse traversal can still be expressed in SPARQL with `^property`; an explicit inverse property is justified when it has a concrete application rather than merely duplicating a path. The reviewed minimum deliberately avoids adding transitivity, symmetric properties or recursive grouping relations without a scientific need.

## 8. Values, units and Cartesian components

A scientific quantity, its numeric value and its unit are distinct parts of a record. The value model introduces reusable classes under `AuxiliaryConcept`:

- `Value` provides the common abstraction.
- `FloatValue` stores a floating-point literal through `hasFloatValue` (`xsd:double`).
- `IntegerValue` stores an integer through `hasIntegerValue`.
- `NaturalValue` stores a non-negative integer through `hasNaturalValue`; zero is allowed by the chosen datatype.
- `VectorValue` connects to component-value nodes through `hasComponentX`, `hasComponentY` and `hasComponentZ`.

The quantity class carries the scientific interpretation. `ElectronicEnergy` represents the selected final method-dependent energy, including the nuclear term when that is the program convention. `HOMO` and `LUMO` represent frontier orbital energies in this minimum, rather than a full orbital model. `ZPEenergy` represents electronic energy including zero-point energy; `ThermalEnergy`, `ThermalEntalpy` and `FreeEnergy` represent the selected thermochemical totals. `TotalEntropy` is an entropy quantity despite its placement under SystemEnergies. `Mulliken` retains population-analysis information; a partial charge must be identified as such and associated with its atom.

A scalar path is:

**Calculation → calculation result → scientific quantity → numerical value → literal**, with a unit associated explicitly with the numerical representation.

For electronic energy, the property path is `hasCalculationResult / hasEnergy / hasNumericalValue / hasFloatValue`. The energy individual is typed `ElectronicEnergy`; the value individual is typed `FloatValue`. No `FloatValue` subclass is created inside `ElectronicEnergy`.

For coordinates, the path is **coordinate entity → VectorValue → x/y/z FloatValue nodes → double literals**. Both coordinate classes contain an existential restriction requiring a vector representation with at least one component of each axis. The three component properties are reused rather than recreating x/y/z classes or direct literal properties for every vector quantity. No uniqueness/cardinality rule for component records or vector representations was added.

Input coordinates are reached from an atom through `coordinates`. Output coordinates are reached from calculation results through `hasCoordinatesOutput`. A Cartesian vector represents one position, not an entire multi-atom geometry. The model still needs an explicit correspondence between each output position and its atom, and a way to distinguish geometries or optimization steps when several occur. Input and output use the same numerical architecture but retain different roles.

The declared policy is canonical SI values during ingestion: joules for energies, metres for coordinates and coulomb metres for dipole moments. Normalization must actually be implemented; the OWL axioms do not perform conversion. Queries using eV, ångström or debye require a consistent conversion at the ingestion or query boundary.

A remaining alignment issue is that v11 also carries unit restrictions directly on some scientific classes, while the recommended representation attaches units to value nodes. `ElectronicEnergy`, for example, requires a direct `unit` link to `Joule`; that does not automatically copy the unit to its `FloatValue`. Conversely, a value-node unit does not remove the class restriction. Coordinate output lacks the direct metre restriction present on coordinate input. Deployment should adopt and validate one explicit storage policy across both paths before relying on unit-filtered queries.

The same caution applies to charge: a total-charge number in units of the elementary charge is not numerically identical to electric charge in coulombs. The mapping must specify which representation `ChargeSum` stores. Mulliken partial charge is a different observable and must retain its atom association.

## 9. Datatype properties and molecular descriptors

Datatype properties were reviewed to avoid duplicate paths for numerical quantities. Floating-point values now use the generic value layer, rather than retaining independent direct literals for each energy or Cartesian component. Text fields remain direct literals when no intermediate entity is needed.

| Group | Properties, including specialized descendants |
|---|---|
| `io:auxiliaryData` | `io:hasFloatValue`, `io:hasIntegerValue`, `io:hasName`, `io:hasNaturalValue`, `io:hasValue` |
| `io:molecularData` | `io:atomIndex`, `io:elementType`, `io:hasElementSymbol`, `io:inchi`, `io:inchiKey`, `io:iupacName`, `io:smiles`, `io:stoichiometry` |
| `io:calculationData` | `io:convergenceStatus`, `io:keywords`, `io:programVersion` |
| `io:publicationData` | `io:articleIdentifier`, `io:issueDate`, `io:itemName`, `io:subjects`, `io:uri` |

Four descriptors now have domain `MolecularDescription` and range `xsd:string`: `smiles`, `inchi`, `inchiKey` and `iupacName`. `MolecularSystem` connects to the description through `hasMolecularDescription`. They are optional and can coexist, because they support different ways of identifying, representing or searching for a system. A string datatype does not establish that the content is valid SMILES, a correct InChI, a valid InChIKey or an IUPAC-compliant name; suitable application-level checks are still needed.

The old `Smiles` class was removed after confirming it had no incoming references in the current file. Popularity of a representation was not a sufficient reason to model it differently from the other descriptors. A separate descriptor-record class would become useful if provenance, generating software, canonicalization method or version needed to be stored independently for each representation. Those requirements were not part of the present minimum.

The user-assigned name is stored through `itemName` on `Item`, in the publication area. It labels a repository record; it need not be a scientific name or match the system's IUPAC name. Existing `hasName` remains a shared naming property for basis sets, functionals, people, institutions, journals and programs. `itemName` was not made its subproperty, which would inherit that property's restricted domain union.

`issueDate` retains `xsd:date` in the delivered ontology. `uri` uses `xsd:anyURI`; it is distinct from the IRI identifying a graph node. Optional textual fields have no global functionality or completeness rule: a record can lack a descriptor without becoming inconsistent.

## 10. Scientific search and a worked query

The semantic layer is intended to combine constraints across records, not merely display an ontology tree. Representative searches include selenium-containing systems with a specified HOMO energy, calculations using a selected functional and basis set, charged systems with converged calculations, and published datasets containing particular computed quantities.

The following query expresses the selenium/HOMO example over populated data. It uses exact v11 IRIs and assumes energy values have been normalized to joules. The threshold `1.602176634E-19` joules corresponds to 1 eV. A result must explicitly carry a unit on the value node for this query to match.

```sparql
PREFIX io: <http://purl.org/iochem/>
PREFIX gc: <http://purl.org/gc/>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

SELECT DISTINCT ?calculation ?system ?homoEnergyJ
WHERE {
  ?calculation io:hasMolecularSystem ?system ;
               io:hasCalculationResult ?result .
  ?system io:hasAtom/io:isElement ?element .
  ?element io:hasElementSymbol "Se" .
  ?result io:hasEnergy ?quantity .
  ?quantity rdf:type/rdfs:subClassOf* io:HOMO ;
            io:hasNumericalValue ?value .
  ?value io:hasFloatValue ?homoEnergyJ ; io:unit io:Joule .
  FILTER (?homoEnergyJ > 1.602176634E-19)
}
```

A query can be logically and syntactically correct yet have no matches because the mapped data are absent, use another unit representation, or omit explicit links. The energy reference convention matters scientifically too: a positive HOMO threshold is a user criterion, not a statement that this is a generally useful boundary for every method and system.

HOMO/LUMO extraction must inspect orbital energies together with occupancy, ordering and, where relevant, spin channels. An occupancy value alone is not an orbital energy. The minimum ontology does not yet represent the full orbital spectrum or spin-resolved frontier-orbital records; ingestion must avoid concealing those distinctions. A natural-language interface should resolve them when they affect the query.

## 11. Validation and what it establishes

Validation proceeded at several levels: RDF/XML parsing, comparison of class and property changes, checking representative paths, SPARQL/inference tests, and reasoner execution. Classes were protected from unintended edits during property revisions; later authorized edits replaced the molecule focus and removed the redundant `Smiles` class.

For the current 71-class release, **Pellet 2.3.1** reported `Consistent: Yes` and no unsatisfiable concepts on the delivered file. **HermiT 1.3.8.1099** reported consistency and no unsatisfiable named classes on a diagnostic copy in which only the `issueDate` range changed from `xsd:date` to `xsd:string`. The delivered ontology still has `xsd:date`. No unsupported-datatype-ignore option was used for that successful diagnostic run.

The distinction is important: `xsd:date` is outside the mandatory OWL 2 datatype map, which includes `xsd:dateTime` and `xsd:dateTimeStamp` [3]. The installed HermiT aborts on that range in the original file. Its result therefore applies to the modified diagnostic copy, whereas the original-file result comes from Pellet. Earlier profile-check acceptance should not be treated as evidence that every engine supports the datatype.

Logical consistency means that the reasoner found no contradiction under the model's axioms. It does not establish correct chemical meanings, complete records, valid identifiers, correct units, correct energy conventions or robust extraction across software versions. The ontology has no declared class disjointness, so some scientifically inappropriate multiple typings remain logically possible.

OWL uses an open-world interpretation. Missing x/y/z triples need not cause inconsistency: existential restrictions can be satisfied by unnamed values in a model. Validation of actual populated fields should use a separate data-validation mechanism, for example SHACL shapes and parser-level tests. That mechanism is an implementation requirement, not a feature already added to v11.

## 12. Implementation priorities and maintenance

The next stage is a small mapping-driven implementation, tested on representative calculations from all three programs. Each mapping should identify its source selector, target entity and property path, literal datatype, source and target units, contextual role, repeat handling, and a test fixture. Keep distinctions such as absent, unavailable, unparsed and invalid values rather than replacing them with zero.

Before exposing scientific search, resolve the following items:

| Item | Why it matters |
|---|---|
| Final vs intermediate results | Optimization and SCF outputs contain repeated energies and geometries |
| Input charge vs population sums | The current ChargeSum path is an input molecular descriptor |
| Frontier orbital extraction | Occupancy is not energy; spin and ordering can change the answer |
| Thermochemical totals vs corrections | A correction, total enthalpy and total free energy are different quantities |
| Output position–atom correspondence | A coordinate vector alone does not identify which atom moved |
| Units on quantities and values | Class restrictions do not propagate units to numerical nodes |
| Item–calculation correspondence | v11 has no explicit object property connecting an Item to its calculation |
| Identifier scope | InChI, SMILES and names do not necessarily distinguish conformers or calculation conditions |
| Provenance and versions | Reprocessing needs the parser/template revision and original source context |
| Namespace and release policy | Shared IRIs, file versions and changed axioms need a stable publication strategy |

For thermochemistry, match the reported observable and its conditions. The working sheet directs the developer to the relevant thermochemistry context; it is not a literal equivalence specification. The implemented mapping must distinguish corrections from totals. For clarity, `G = H − TS` describes Gibbs free energy; enthalpy and internal energy are related by `H = U + pV`. These distinctions should be explicit in the executable mapping without expanding the present ontology scope.

Unit conversion, extraction coverage and mapping completeness are separate deliverables. Selecting Gaussian, ORCA and ADF for the first mapping exercise does not mean every retained quantity is already validated for all three. ADF bonding energy, for example, should not be equated with a different program's total electronic energy solely because both are expressed in energy units.

Changes should remain explicit and versioned. Preserve stable identifiers where possible; document renamed or removed concepts and migrate existing data when property paths change. Retain the source workbook as development evidence, but use a reviewed, current mapping table as the implementation authority. This release establishes a usable starting vocabulary and a clear set of implementation questions; successful deployment will be demonstrated by correct populated records and scientifically meaningful search results.

## References and source record

- **Project ontology:** `ontology/ontoiochem.owl` (v11), revised 8 October 2026; 71 named classes. SHA-256 of this repository copy: `2cad6b5eca0c222bc64fa92d96fc038f60adb8cf8b3cd6755eeb3d8a3d1f9416`. The file originally circulated as `ontoiochem_v11.owl` (SHA-256 `1c61b7a09c43c2145e6404d5d678ec8c80a5b46dc238e69fc0e28aa0b1ab02fc`) differs only by the English translation of one annotation (see `CHANGELOG.md`).
- **Tag mapping evidence:** `mappings/ontology-mapping-reference.xlsx`; worksheets `gaussian_total`, `30 entities` and `Gaussian energies`. The workbook describes a development-stage mapping and includes paths older than v11.
- **Conceptual map:** `cc_conceptual_map2.pdf`, inspected visually; associated `cmap` and `project.idx` native project records. The diagram is an exploratory Gainesville-based map, not the current OWL hierarchy.
- **Tools:** `tag_explorer_v5.py` and `searchTag.sh`, inspected as source code; the tag index and conversion-template checkout were not supplied.
- **Development sequence:** project decisions and revisions recorded during preparation of the minimum ontology, including later removal of ZPE correction, kinetic energy and potential energy. The second mapping worksheet is the principal selection reference.
- **[1]** Krdzavac et al., *An Ontology and Semantic Web Service for Quantum Chemistry Calculations*, JCIM (2019). [DOI](https://doi.org/10.1021/acs.jcim.9b00227); [accepted manuscript record](https://www.repository.cam.ac.uk/handle/1810/293653).
- **[2]** Murray-Rust et al., *The semantics of Chemical Markup Language (CML): dictionaries and conventions* (2011). [Open-access article](https://pmc.ncbi.nlm.nih.gov/articles/PMC3206453/).
- **[3]** W3C, *OWL 2 Structural Specification and Functional-Style Syntax*, section 4. [Datatype maps](https://www.w3.org/TR/owl2-syntax/#Datatype_Maps).
- **[4]** W3C, *SPARQL 1.1 Query Language*. [Specification](https://www.w3.org/TR/sparql11-query/).
- **[5]** ioChem-BD technical documentation. [Gaussian conversion templates](https://docs.iochem-bd.org/data/codes/gaussian.html); [conversion test dataset](https://docs.iochem-bd.org/data/conversion-test-dataset.html). These are reference resources, not proof that every workbook correspondence has been tested.

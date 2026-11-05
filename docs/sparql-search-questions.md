# OntoIochem v11

Scientific search questions and SPARQL templates

Ten examples for a semantic layer in ioChem-BD

These examples show how the minimum ontology can support scientific discovery, comparisons and data curation. Each question is written in natural language and paired with a directly copyable SPARQL query using the OntoIochem v11 vocabulary.

The queries assume that repository records have been mapped to RDF, that the relevant links are populated, and that numerical quantities and units are normalized. Energy values use joules, Mulliken partial charges use coulombs, and dipole components use coulomb metres. Required type assertions must be explicit or available through the endpoint’s inference configuration.

Validation: all ten query templates were checked for SPARQL syntax and for the presence of their io: terms in v11. They have not been executed against the ioChem-BD repository. Actual results depend on the populated graph and endpoint configuration.

## 1 Selenium and HOMO energy

**Find selenium-containing systems with a HOMO energy greater than 1 eV.**

Combines elemental composition with a calculated electronic property. HOMO energies stored in joules are converted to electronvolts in the result.

```sparql
PREFIX io: <http://purl.org/iochem/>

SELECT DISTINCT ?calculation ?homoEv WHERE {
  ?calculation io:hasMolecularSystem ?system ;
               io:hasCalculationResult ?result .
  ?system io:hasAtom/io:isElement/io:hasElementSymbol "Se" .
  ?result io:hasEnergy ?energy .
  ?energy a io:HOMO ; io:hasNumericalValue ?value .
  ?value io:hasFloatValue ?homoJ ; io:unit io:Joule .
  BIND(?homoJ / 1.602176634E-19 AS ?homoEv)
  FILTER(?homoEv > 1)
}
```

## 2 Small frontier orbital gaps

**Find calculations with a HOMO–LUMO gap smaller than 2 eV.**

Computes the energy difference without requiring a separate gap entity. Both energies must belong to the same result and follow a compatible orbital selection convention.

```sparql
PREFIX io: <http://purl.org/iochem/>

SELECT DISTINCT ?calculation ?gapEv WHERE {
?calculation io:hasCalculationResult ?result .
?result io:hasEnergy ?homo, ?lumo .
?homo a io:HOMO ; io:hasNumericalValue ?hv .
?lumo a io:LUMO ; io:hasNumericalValue ?lv .
?hv io:hasFloatValue ?h ; io:unit io:Joule .
?lv io:hasFloatValue ?l ; io:unit io:Joule .
BIND((?l - ?h) / 1.602176634E-19 AS ?gapEv)
FILTER(?gapEv >= 0 && ?gapEv < 2)
}
```

## 3 Large dipole moments

**Find systems with a calculated dipole moment larger than 3 debye.**

Uses the three Cartesian components in coulomb metres. Comparing squared magnitudes avoids a square-root function, which is not part of standard SPARQL 1.1.

```sparql
PREFIX io: <http://purl.org/iochem/>

SELECT DISTINCT ?calculation WHERE {
?calculation io:hasCalculationResult/io:hasSystemProperty/io:dipole ?dipole .
?dipole io:hasVectorRepresentation ?vector .
?vector io:unit io:CoulombMeter ;
 io:hasComponentX/io:hasFloatValue ?x ;
 io:hasComponentY/io:hasFloatValue ?y ;
 io:hasComponentZ/io:hasFloatValue ?z .
FILTER((?x*?x + ?y*?y + ?z*?z) > (3*3.33564E-30)*(3*3.33564E-30))
}
```

## 4 Charge and system size

**Find negatively charged systems containing between 10 and 30 atoms.**

Combines total system charge with the atom-count descriptor. The charge representation must be normalized consistently; the sign is sufficient for this search.

```sparql
PREFIX io: <http://purl.org/iochem/>

SELECT DISTINCT ?calculation ?atomCount WHERE {
?calculation io:hasMolecularSystem ?system .
?system io:hasChargeSum/io:hasNumericalValue ?chargeValue ; io:hasMolecularQuantity
    ?count .
?chargeValue (io:hasIntegerValue|io:hasFloatValue) ?charge .
?count a io:AtomCount ; io:hasNumericalValue/io:hasNaturalValue ?atomCount .
FILTER(?charge < 0 && ?atomCount >= 10 && ?atomCount <= 30)
}
```

## 5 Local nitrogen charges

**Find systems containing nitrogen atoms with Mulliken partial charges below −0.5 elementary charges.**

Links each Mulliken result to its atom and converts coulombs to elementary-charge units. The mapped Mulliken records must represent partial charges, rather than another population quantity.

```sparql
PREFIX io: <http://purl.org/iochem/>

SELECT DISTINCT ?calculation ?atom ?chargeInE WHERE {
?calculation io:hasMolecularSystem/io:hasAtom ?atom ;
    io:hasCalculationResult/io:hasMulliken ?mulliken .
?atom io:isElement/io:hasElementSymbol "N" .
?mulliken io:isPropertyOfAtom ?atom ; io:hasNumericalValue ?value .
?value io:hasFloatValue ?chargeC ; io:unit io:Coulomb .
BIND(?chargeC / 1.602176634E-19 AS ?chargeInE)
FILTER(?chargeInE < -0.5)
}
```

## 6 Comparisons across programs

**Find systems studied with different computational programs using the same density functional and basis set.**

Matches an InChIKey, a functional entity and a basis-set entity. A shared InChIKey does not establish identical geometry, spin state or calculation conditions. Program names and method identifiers must be normalized.

```sparql
PREFIX io: <http://purl.org/iochem/>

SELECT DISTINCT ?inchiKey ?calc1 ?calc2 ?program1 ?program2 WHERE {
  ?calc1
    io:hasMolecularSystem/io:hasMolecularDescription/io:inchiKey ?inchiKey ;
    io:usesProgram/io:hasName ?program1 ;
    io:usesDensityFunctional ?functional ;
    io:usesBasisSet ?basis .
  ?calc2
    io:hasMolecularSystem/io:hasMolecularDescription/io:inchiKey ?inchiKey ;
    io:usesProgram/io:hasName ?program2 ;
    io:usesDensityFunctional ?functional ;
    io:usesBasisSet ?basis .
  FILTER(
    LCASE(STR(?program1)) != LCASE(STR(?program2)) &&
    STR(?calc1) < STR(?calc2)
  )
}
```

## 7 Pyridine calculations with geometry output

**Find ORCA calculations on systems whose IUPAC names contain “pyridine”, with output coordinates and a recorded convergence status.**

Combines a molecular description, program metadata and available results. The query returns the recorded status; it does not filter for successful convergence. Output coordinates alone do not establish that the geometry was optimized.

```sparql
PREFIX io: <http://purl.org/iochem/>

SELECT DISTINCT ?calculation ?iupacName ?status ?coordinates WHERE {
?calculation io:usesProgram/io:hasName ?program ;
    io:hasMolecularSystem/io:hasMolecularDescription/io:iupacName ?iupacName ;
    io:hasCalculationResult ?result .
?result io:hasCoordinatesOutput ?coordinates ;
    io:hasSystemProperty/io:convergenceStatus ?status .
FILTER(LCASE(STR(?program)) = "orca")
FILTER(CONTAINS(LCASE(STR(?iupacName)), "pyridine"))
}
```

## 8 Authors and selenium calculations

**Which authors are associated with the largest number of selenium-containing calculations linked to publications dated 2025?**

Counts distinct calculations per author and returns the ten largest counts. The year refers to the linked publication date, not the calculation date.

```sparql
PREFIX io: <http://purl.org/iochem/>

SELECT ?author
       (COUNT(DISTINCT ?calculation) AS ?nCalculations)
WHERE {
  ?calculation
    io:hasMolecularSystem/io:hasAtom/io:isElement/io:hasElementSymbol "Se" ;
    io:hasPublication ?publication .
  ?publication io:hasAuthor ?author ;
               io:issueDate ?date .
  FILTER(STRSTARTS(STR(?date), "2025-"))
}
GROUP BY ?author
ORDER BY DESC(?nCalculations)
LIMIT 10
```

## 9 Discovery through user assigned names

**Find published collections containing items whose user-assigned names mention “transition state” or “TS”.**

Searches itemName within published collections and returns a collection URI when available. A matching name is a discovery hint; it does not confirm a transition state scientifically.

```sparql
PREFIX io: <http://purl.org/iochem/>

SELECT DISTINCT ?publication ?item ?name ?collectionUrl WHERE {
?publication io:hasFile/io:hasCollection ?collection .
?collection io:hasItem ?item . ?item io:itemName ?name .
FILTER(REGEX(STR(?name), "transition state|(^|[^a-z])ts([^a-z]|$)", "i"))
OPTIONAL { ?collection io:hasPublicationMetadata ?identifier . ?identifier a io:URI ;
    io:uri ?collectionUrl . }
}
```

## 10 Missing units on HOMO values

**Find calculations with HOMO values that have no unit recorded on their numerical-value nodes.**

Supports data curation by checking the current graph for a missing unit assertion at a specific node. Under the open-world assumption, absence is not an OWL inconsistency. A unit may also be recorded on the quantity node.

```sparql
PREFIX io: <http://purl.org/iochem/>

SELECT DISTINCT ?calculation ?value ?homo WHERE {
?calculation io:hasCalculationResult/io:hasEnergy ?energy .
?energy a io:HOMO ; io:hasNumericalValue ?value .
?value io:hasFloatValue ?homo .
FILTER NOT EXISTS { ?value io:unit ?unit . }
}
```

#!/bin/bash

if [ ! -d "iochem-bd" ]; then
    echo "iochem-bd folder not found, cloning..."
    git clone --depth 1 https://gitlab.com/ioChem-BD/iochem-bd.git iochem-bd
fi

formats=(adf gaussian lammps orca amber gromacs qespresso ams gronor molcas turbomole castep grrm mopac vasp xtb)

echo "Select a format:"
select FORMAT in "${formats[@]}"; do
    if [[ -n "$FORMAT" ]]; then
        break
    fi
    echo "Invalid selection, please try again."
done

echo "Select output mode:"
select MODE in "Tags only (unique, sorted)" "Tags with filenames (unique, sorted)"; do
    if [[ -n "$MODE" ]]; then
        break
    fi
    echo "Invalid selection, please try again."
done

if [[ "$REPLY" == "1" ]]; then
    find iochem-bd/jumbo-converters/jumbo-converters-compchem/jumbo-converters-compchem-$FORMAT -name "*.xml" \
    | while read -r f; do
        xmllint --xpath '//@dictRef' "$f" 2>/dev/null | sed -E 's/dictRef="([^"]*)"/\1\n/g'
    done | grep -v '^$' | sort -u
else
    for f in $(find iochem-bd/jumbo-converters/jumbo-converters-compchem/jumbo-converters-compchem-$FORMAT -name "*.xml"); do
        tags=$(xmllint --xpath '//@dictRef' "$f" 2>/dev/null | sed -E 's/dictRef="([^"]*)"/\1\n/g' | grep -v '^$' | sort -u)
        if [[ -n "$tags" ]]; then
            echo "$f"
            echo "$tags"
        fi
    done
fi

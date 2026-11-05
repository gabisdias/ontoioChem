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

read -rp "Enter tag value (dictRef): " TAG

while read -r f; do
    matches=$(grep -n "dictRef=\"$TAG\"" "$f")
    if [[ -n "$matches" ]]; then
        echo "$f"
        echo "$matches"
    fi
done < <(find "iochem-bd/jumbo-converters/jumbo-converters-compchem/jumbo-converters-compchem-$FORMAT" -name "*.xml")

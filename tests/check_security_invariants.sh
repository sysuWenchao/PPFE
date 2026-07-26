#!/bin/bash
set -euo pipefail

if git grep -n -E '\brand[[:space:]]*\(|\bsrand[[:space:]]*\(' \
    -- 'src/*.cpp' 'src/*.h' 'src/include/*.h'; then
    echo "Error: non-cryptographic rand()/srand() found in protocol code" >&2
    exit 1
fi

if git grep -n 'AES_KEY' -- 'src/*.cpp' 'src/*.h' 'src/include/*.h'; then
    echo "Error: fixed AES_KEY found in protocol code" >&2
    exit 1
fi

if git grep -n 'ECB_Mode' -- 'src/*.cpp' 'src/*.h' 'src/include/*.h'; then
    echo "Error: ECB message mode found in protocol PRF code" >&2
    exit 1
fi

if git grep -n -E 'encZeroNext[[:space:]]*\+\+[[:space:]]*%' \
    -- 'src/*.cpp' 'src/*.h' 'src/include/*.h'; then
    echo "Error: Enc(0) cache wraps around and reuses ciphertexts" >&2
    exit 1
fi

while IFS= read -r tracked_artifact; do
    if [[ -e "$tracked_artifact" ]]; then
        echo "Error: generated or precompiled artifact exists in the source tree: $tracked_artifact" >&2
        exit 1
    fi
done < <(git ls-files build troy-nova/build encryption/libtroy.so \
    encryption/utils/libtroy.so)

echo "Source security invariants passed"

#!/bin/bash

set -e  # Esce se un comando fallisce

# ----------------------------------------
# Controllo Emscripten
# ----------------------------------------
if ! command -v emcmake &> /dev/null
then
    echo "Emscripten non trovato. Installazione in corso..."
    
    # Clona EMSDK se non esiste
    if [[ ! -d ./emsdk ]]; then
        git clone https://github.com/emscripten-core/emsdk.git
    fi
    cd emsdk
    ./emsdk install latest
    ./emsdk activate latest
    source ./emsdk_env.sh
    cd ..
    
    # Verifica che emcmake sia disponibile
    if ! command -v emcmake &> /dev/null
    then
        echo "Errore: emcmake non trovato anche dopo installazione EMSDK."
        echo "Assicurati che ./emsdk_env.sh sia eseguito correttamente."
        exit 1
    fi
else
    echo "Emscripten già presente."
fi

# ----------------------------------------
# Patch a fastcomp (se possibile)
# ----------------------------------------
if [[ -f scripts/emscripten.patch && -f emsdk/fastcomp/emscripten/src/shell.js ]]; then
    echo "Applicazione patch a fastcomp..."
    patch -N --verbose emsdk/fastcomp/emscripten/src/shell.js scripts/emscripten.patch
else
    echo "Attenzione: file per patch non trovati, salto patch."
fi

# ----------------------------------------
# Build JS e WASM
# ----------------------------------------
mkdir -p jsbuild && cd jsbuild
rm -rf *

echo "Compilazione WebAssembly..."
emcmake cmake .. -DNO_AES=1 -DARCH=default -DBUILD_WASM=1 -DBUILD_JS=0
make
cp turtlecoin-crypto-wasm.js ../dist/

echo "Compilazione JavaScript..."
emcmake cmake .. -DNO_AES=1 -DARCH=default -DBUILD_WASM=0 -DBUILD_JS=1
make
cp turtlecoin-crypto.js ../dist/

echo "Build completata. File disponibili in ./dist/"

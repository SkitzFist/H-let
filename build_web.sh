#!/usr/bin/env bash
set -eu

OUT_DIR="build/web"
mkdir -p $OUT_DIR

export EMSDK_QUIET=1

odin build src/main_web \
    -target:js_wasm32 \
    -build-mode:obj \
    -define:RAYLIB_WASM_LIB=env.o \
    -define:RAYGUI_WASM_LIB=env.o \
    -out:$OUT_DIR/game.wasm.o

ODIN_PATH=$(odin root)
cp $ODIN_PATH/core/sys/wasm/js/odin.js $OUT_DIR

files="$OUT_DIR/game.wasm.o ${ODIN_PATH}/vendor/raylib/wasm/libraylib.a ${ODIN_PATH}/vendor/raylib/wasm/libraygui.a"
flags="-sUSE_GLFW=3 -sSTACK_SIZE=2097152 -sALLOW_MEMORY_GROWTH=1 -sINITIAL_MEMORY=33554432 -sWASM_BIGINT -sWARN_ON_UNDEFINED_SYMBOLS=0 -sASSERTIONS --shell-file src/main_web/index_template.html --preload-file assets"

emcc -o $OUT_DIR/index.html $files $flags
rm $OUT_DIR/game.wasm.o

echo "Web build created in ${OUT_DIR}"

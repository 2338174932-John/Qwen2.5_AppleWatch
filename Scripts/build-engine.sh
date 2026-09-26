#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="${ENGINE_BUILD_DIR:-$ROOT/.engine-build}"
CMAKE="${CMAKE:-cmake}"
"$CMAKE" -S "$ROOT/Vendor/llama.cpp" -B "$BUILD" -G Xcode \
 -DCMAKE_SYSTEM_NAME=watchOS -DCMAKE_OSX_SYSROOT=watchos \
 -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_DEPLOYMENT_TARGET=10.0 \
 -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO \
 "-DCMAKE_C_FLAGS=-D_DARWIN_C_SOURCE -ffile-prefix-map=$ROOT=." \
 "-DCMAKE_CXX_FLAGS=-D_DARWIN_C_SOURCE -ffile-prefix-map=$ROOT=." \
 -DBUILD_SHARED_LIBS=OFF -DGGML_NATIVE=OFF -DGGML_METAL=OFF \
 -DGGML_ACCELERATE=OFF -DGGML_BLAS=OFF -DGGML_OPENMP=OFF \
 -DLLAMA_BUILD_COMMON=OFF -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_TOOLS=OFF \
 -DLLAMA_BUILD_EXAMPLES=OFF -DLLAMA_BUILD_APP=OFF -DLLAMA_OPENSSL=OFF
"$CMAKE" --build "$BUILD" --config Release --target llama -j 4
mkdir -p "$ROOT/Lib"
xcrun libtool -static -o "$ROOT/Lib/libOfflineInference.a" \
 "$BUILD/src/Release-watchos/libllama.a" \
 "$BUILD/ggml/src/Release-watchos/libggml.a" \
 "$BUILD/ggml/src/Release-watchos/libggml-cpu.a" \
 "$BUILD/ggml/src/Release-watchos/libggml-base.a"

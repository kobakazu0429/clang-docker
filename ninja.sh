#!/bin/bash
CLANG_BUILD_DIR="/tmp/clang-build"
ENABLE_PROJECTS="clang;clang-tools-extra"
CMAKE_INSTALL_TARGETS="install-clang install-clang-resource-headers install-clang-format"
CLANG_INSTALL_DIR="/tmp/clang-install"

mkdir -p "$CLANG_INSTALL_DIR"
mkdir -p "$CLANG_BUILD_DIR/build"

pushd "$CLANG_BUILD_DIR/build"

echo "Running build"

set CC=cl
set CXX=cl

cmake -GNinja \
  "$CLANG_BUILD_DIR/src/llvm" \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_PROJECTS="$ENABLE_PROJECTS" \
  -DCMAKE_INSTALL_PREFIX="$CLANG_INSTALL_DIR" \

mold -run ninja -j$(nproc) $CMAKE_INSTALL_TARGETS

cmake --build "$CLANG_BUILD_DIR/build" --target clangd

popd

echo "Done"

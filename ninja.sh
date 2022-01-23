#!/bin/bash
CLANG_BUILD_DIR="/tmp/clang-build"
CMAKE_ARGS="-DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_PROJECTS=clang"
CMAKE_INSTALL_TARGETS="install-clang install-clang-resource-headers install-clang-format"
CLANG_INSTALL_DIR="/tmp/clang-install"

mkdir -p "$CLANG_INSTALL_DIR"
mkdir -p "$CLANG_BUILD_DIR/build"

pushd "$CLANG_BUILD_DIR/build"

# Run the build as specified in the build arguments.
echo "Running build"

cmake -GNinja \
  -DCMAKE_INSTALL_PREFIX="$CLANG_INSTALL_DIR" \
  $CMAKE_ARGS \
  "$CLANG_BUILD_DIR/src/llvm"

ninja $CMAKE_INSTALL_TARGETS

popd

# Cleanup.
# rm -rf "$CLANG_BUILD_DIR/build"

echo "Done"

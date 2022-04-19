# syntax=docker/dockerfile:1.3

#===- llvm/utils/docker/debian8/build/Dockerfile -------------------------===//
#
# Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
#===----------------------------------------------------------------------===//

FROM debian:11 as builder
LABEL maintainer "LLVM Developers"
ENV CLANG_BUILD_DIR /tmp/clang-build

# Install build dependencies of llvm.
# First, Update the apt's source list and include the sources of the packages.
RUN grep deb /etc/apt/sources.list | \
  sed 's/^deb/deb-src /g' >> /etc/apt/sources.list

# Install compiler, python
RUN apt update && \
  apt install -y --no-install-recommends ca-certificates gnupg build-essential python3.9 unzip wget gcc vim \
  git clang cmake libstdc++-10-dev libssl-dev libxxhash-dev zlib1g-dev pkg-config && \
  rm -rf /var/lib/apt/lists/*

RUN cd /tmp && \
  git clone https://github.com/rui314/mold.git && \
  cd mold && \
  git checkout v1.1.1 && \
  make -j$(nproc) CXX=clang++ && \
  make install

RUN ln -s /usr/bin/python3 /usr/bin/python & \
  ln -s /usr/bin/pip3 /usr/bin/pip

# Install a newer ninja release. It seems the older version in the debian repos
# randomly crashes when compiling llvm.
RUN \
  wget --no-verbose "https://github.com/ninja-build/ninja/releases/download/v1.10.2/ninja-linux.zip" -O "/tmp/ninja-linux.zip" && \
  wget --no-verbose "https://github.com/Kitware/CMake/releases/download/v3.22.1/cmake-3.22.1-linux-x86_64.tar.gz" -O "/tmp/cmake.tar.gz" && \
  wget --no-verbose "https://codeload.github.com/llvm/llvm-project/tar.gz/refs/tags/llvmorg-13.0.0" -O "/tmp/llvmorg.tar.gz"

RUN mkdir -p "$CLANG_BUILD_DIR/src" && \
  unzip /tmp/ninja-linux.zip -d /usr/local/bin && \
  tar -xf /tmp/cmake.tar.gz -C /usr/local --strip-components 1 && \
  tar -xf /tmp/llvmorg.tar.gz -C "$CLANG_BUILD_DIR/src" --strip-components 1 && \
  rm /tmp/ninja-linux.zip /tmp/cmake.tar.gz /tmp/llvmorg.tar.gz

RUN sed -ie "s/use of undeclared identifier %0/変数 %0 は未定義です/g" "$CLANG_BUILD_DIR/src/clang/include/clang/Basic/DiagnosticSemaKinds.td"

# Run the build. Results of the build will be available at /tmp/clang-install/.
COPY ninja.sh /ninja.sh
# RUN --mount=type=cache,target="$CLANG_BUILD_DIR/build" /ninja.sh
# RUN mkdir -p "$CLANG_INSTALL_DIR" && \
#   mkdir -p "$CLANG_BUILD_DIR/build" && \
#   cd "$CLANG_BUILD_DIR/build"

# RUN --mount=type=cache,target="$CLANG_BUILD_DIR/build" \
#   cmake -GNinja \
#   -DCMAKE_INSTALL_PREFIX="$CLANG_INSTALL_DIR" \
#   $CMAKE_ARGS \
#   "$CLANG_BUILD_DIR/src/llvm"

# RUN --mount=type=cache,target="$CLANG_BUILD_DIR/build" ninja $CMAKE_INSTALL_TARGETS
# RUN --mount=type=cache,target="$CLANG_BUILD_DIR/build" cmake -GNinja -DCMAKE_INSTALL_PREFIX=$CLANG_INSTALL_DIR -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra" "$CLANG_BUILD_DIR/src/llvm"
# RUN --mount=type=cache,target="$CLANG_BUILD_DIR/build" cmake --build "$CLANG_BUILD_DIR/build" --target clangd

# Stage 2. Produce a minimal release image with build results.
# FROM debian:11
# # Install packages for minimal useful image.
# RUN apt update && \
#   apt install -y --no-install-recommends libstdc++6 binutils && \
#   rm -rf /var/lib/apt/lists/*
# # Copy build results of stage 1 to /usr/local.
# COPY --from=builder /tmp/clang-install/ /usr/local/
# COPY --from=builder /tmp/clang-build/build /usr/local/bin

# # COPY --from=builder /tmp/clang-build/build/clang-tblgen /usr/local/bin
# # COPY --from=builder /tmp/clang-build/build/clang-ast-dump /usr/local/bin
# # COPY --from=builder /tmp/clang-build/build/clang-offload-bundler /usr/local/bin
# # COPY --from=builder /tmp/clang-build/build/clang-offload-wrapper /usr/local/bin
# # COPY --from=builder /tmp/clang-build/build/llvm-lit /usr/local/bin
# # COPY --from=builder /tmp/clang-build/build/llvm-tblgen /usr/local/bin

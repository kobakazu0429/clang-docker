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

RUN mkdir /tmp/cmake-install && \
  cd /tmp/cmake-install && \
  wget "https://github.com/Kitware/CMake/releases/download/v3.22.1/cmake-3.22.1-linux-x86_64.tar.gz" -O "cmake.tar.gz" && \
  tar -xvf "cmake.tar.gz" -C /usr/local --strip-components 1 && \
  cd / && \
  rm -rf /tmp/cmake-install

ENV CLANG_BUILD_DIR /tmp/clang-build
RUN echo "Clone from GitHub" && \
  mkdir -p "$CLANG_BUILD_DIR/src" && \
  git clone https://github.com/llvm/llvm-project.git -b llvmorg-13.0.0 --depth 1 "$CLANG_BUILD_DIR/src" && \
  echo "Clone Done"

RUN sed -ie "s/use of undeclared identifier %0/変数 %0 は未定義やで/g" "$CLANG_BUILD_DIR/src/clang/include/clang/Basic/DiagnosticSemaKinds.td"

# Run the build. Results of the build will be available at /tmp/clang-install/.
COPY ninja.sh /ninja.sh
RUN /ninja.sh

# Stage 2. Produce a minimal release image with build results.
FROM debian:11
# Install packages for minimal useful image.
RUN apt update && \
  apt install -y --no-install-recommends libstdc++6 binutils && \
  rm -rf /var/lib/apt/lists/*
# Copy build results of stage 1 to /usr/local.
COPY --from=builder /tmp/clang-install/ /usr/local/

COPY --from=builder /tmp/clang-build/build/clang-format /usr/local/bin
COPY --from=builder /tmp/clang-build/build/clangd /usr/local/bin

# COPY --from=builder /tmp/clang-build/build/clang-tblgen /usr/local/bin
# COPY --from=builder /tmp/clang-build/build/clang-ast-dump /usr/local/bin
# COPY --from=builder /tmp/clang-build/build/clang-offload-bundler /usr/local/bin
# COPY --from=builder /tmp/clang-build/build/clang-offload-wrapper /usr/local/bin
# COPY --from=builder /tmp/clang-build/build/llvm-lit /usr/local/bin
# COPY --from=builder /tmp/clang-build/build/llvm-tblgen /usr/local/bin

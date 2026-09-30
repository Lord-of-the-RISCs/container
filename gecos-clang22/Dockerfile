# Rebuild the complete native and Java stack from the committed source snapshot
# produced by prepare-context.sh. The existing Gecos image supplies the tested
# JDK 25, Maven configuration, and Ubuntu 24.04 development dependencies.
FROM spechls-demo:gecos-main

USER root

# The published image has the general build dependencies. Install the native
# packages required by the local Yosys and CIRCT builds explicitly so this image
# remains self-contained if that base image is refreshed.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      build-essential \
      bison \
      cmake \
      flex \
      gawk \
      git \
      libboost-filesystem-dev \
      libboost-python-dev \
      libboost-system-dev \
      libffi-dev \
      libgmp-dev \
      libmpc-dev \
      libmpfr-dev \
      libreadline-dev \
      libtinfo-dev \
      libxml2-dev \
      ninja-build \
      pkg-config \
      tcl-dev \
      zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*

ARG BUILD_JOBS=32
ENV LLVM22_PREFIX=/opt/llvm22
ENV CIRCT_PREFIX=/home/spechls-user/prefix
ENV PATH=/opt/llvm22/bin:/home/spechls-user/prefix/bin:${PATH}
ENV LD_LIBRARY_PATH=/home/spechls-user/prefix/lib:/opt/circt/lib:/opt/llvm22/lib

COPY --chown=spechls-user:spechls-user sources /workspace/sources
COPY revisions.txt /usr/share/hls-mlir-demo/revisions.txt

# LLVM cannot be compiled by a compiler that does not yet exist. First create
# a Clang 22 bootstrap with the base image compiler, then use that bootstrap to
# build the final LLVM/MLIR installation consumed by CIRCT and SpecHLS.
RUN cmake -G Ninja -S /workspace/sources/llvm/llvm -B /workspace/llvm-bootstrap \
      -DCMAKE_BUILD_TYPE=Release \
      '-DLLVM_ENABLE_PROJECTS=clang' \
      -DLLVM_ENABLE_ASSERTIONS=ON \
      -DLLVM_ENABLE_EH=OFF \
      -DLLVM_ENABLE_RTTI=OFF \
      -DLLVM_TARGETS_TO_BUILD=X86 && \
    cmake --build /workspace/llvm-bootstrap --target clang -j${BUILD_JOBS} && \
    cmake -G Ninja -S /workspace/sources/llvm/llvm -B /workspace/llvm-final \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_C_COMPILER=/workspace/llvm-bootstrap/bin/clang \
      -DCMAKE_CXX_COMPILER=/workspace/llvm-bootstrap/bin/clang++ \
      -DCMAKE_INSTALL_PREFIX=${LLVM22_PREFIX} \
      '-DLLVM_ENABLE_PROJECTS=clang;mlir' \
      -DLLVM_ENABLE_ASSERTIONS=ON \
      -DLLVM_ENABLE_EH=OFF \
      -DLLVM_ENABLE_RTTI=OFF \
      -DLLVM_ENABLE_PIC=ON \
      -DLLVM_TARGETS_TO_BUILD=X86 \
      -DLLVM_BUILD_LLVM_DYLIB=OFF \
      -DLLVM_LINK_LLVM_DYLIB=OFF \
      -DMLIR_BUILD_MLIR_C_DYLIB=ON \
      -DLLVM_INSTALL_UTILS=ON && \
    cmake --build /workspace/llvm-final -j${BUILD_JOBS} && \
    cmake --install /workspace/llvm-final

# Build the committed Yosys tree in the image because SpecHLS embeds its C++
# API and invokes the matching yosys-abc executable during control synthesis.
RUN make -C /workspace/sources/yosys -j${BUILD_JOBS}

# CIRCT is built against the final self-hosted LLVM/MLIR installation. Slang is
# enabled because OptimizeControlLogic imports SystemVerilog through CIRCT.
RUN cmake -G Ninja -S /workspace/sources/circt -B /workspace/circt-build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_C_COMPILER=${LLVM22_PREFIX}/bin/clang \
      -DCMAKE_CXX_COMPILER=${LLVM22_PREFIX}/bin/clang++ \
      -DCMAKE_INSTALL_PREFIX=/opt/circt \
      -DLLVM_DIR=${LLVM22_PREFIX}/lib/cmake/llvm \
      -DMLIR_DIR=${LLVM22_PREFIX}/lib/cmake/mlir \
      -DCIRCT_SLANG_FRONTEND_ENABLED=ON \
      -DVERILATOR_DISABLE=ON && \
    cmake --build /workspace/circt-build -j${BUILD_JOBS} && \
    cmake --install /workspace/circt-build

# Replace the base image native prefix with the committed Clang 22 SpecHLS
# build. The explicit ABC path prevents assumptions about the Yosys install.
RUN rm -rf ${CIRCT_PREFIX}/* && \
    cmake -G Ninja -S /workspace/sources/spechls-circt -B /workspace/spechls-build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_C_COMPILER=${LLVM22_PREFIX}/bin/clang \
      -DCMAKE_CXX_COMPILER=${LLVM22_PREFIX}/bin/clang++ \
      -DCMAKE_INSTALL_PREFIX=${CIRCT_PREFIX} \
      -DLLVM_DIR=${LLVM22_PREFIX}/lib/cmake/llvm \
      -DMLIR_DIR=${LLVM22_PREFIX}/lib/cmake/mlir \
      -DCIRCT_DIR=/opt/circt/lib/cmake/circt \
      -DYosys_INCLUDE_DIR=/workspace/sources/yosys \
      -DYosys_LIBRARY=/workspace/sources/yosys/libyosys.so \
      -DSPECHLS_ABC_EXECUTABLE=/workspace/sources/yosys/yosys-abc && \
    cmake --build /workspace/spechls-build -j${BUILD_JOBS} && \
    cmake --install /workspace/spechls-build

USER spechls-user

# Build the Java frontend from the same committed snapshot and replace the JAR
# consumed by the standalone Docker harness.
RUN cp -a /workspace/sources/gecos-hls /workspace/gecos-hls && \
    cd /workspace/gecos-hls && \
    mvn -B -pl bundles/fr.irisa.cairn.gecos.model.speculative_hls.main -am \
      -Dmaven.test.skip=true package && \
    install -m 0644 jar-gen/SpecHLS.jar /home/spechls-user/SpecHLS.jar

# Verify the historical native/C-API parser discrepancy is covered by this
# image build before it can be used as a test environment.
RUN /home/spechls-user/prefix/bin/spechls-opt \
      /workspace/sources/spechls-circt/test/Uclid/singlespec.2-3.speculated.mlir \
      --allow-unregistered-dialect=false -o /dev/null && \
    python3 -c 'import ctypes,pathlib; lib=ctypes.CDLL("/home/spechls-user/prefix/lib/libgecosapi.so"); lib.parseMLIR.argtypes=[ctypes.c_char_p]; lib.parseMLIR.restype=ctypes.c_void_p; module=lib.parseMLIR(pathlib.Path("/workspace/sources/spechls-circt/test/Uclid/singlespec.2-3.speculated.mlir").read_bytes()); assert module, "parseMLIR returned null"; print("C API parse passed")'

WORKDIR /home/spechls-user

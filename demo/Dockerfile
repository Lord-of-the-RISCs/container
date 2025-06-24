FROM ubuntu:24.04
LABEL maintainer="Jean-Michel Gorius <jean-michel.gorius@irisa.fr>"
LABEL description="SpecHLS demonstration environment"
RUN apt-get -y update && \
  apt-get install -y \
  build-essential \
  ninja-build \
  cmake \
  curl \
  git \
  grep \
  libgtest-dev \
  openssh-client \
  python3 \
  python3-setuptools \
  python3-pip \
  sudo \
  zlib1g-dev \
  libtinfo-dev \
  libxml2-dev \
  clang \
  lld \
  bison \
  flex \
  libreadline-dev \
  gawk \
  tcl-dev \
  libffi-dev \
  graphviz \
  xdot \
  pkg-config \
  libboost-system-dev \
  libboost-python-dev \
  libboost-filesystem-dev \
  mold \
  autoconf \
  automake \
  autotools-dev \
  python3-tomli \
  libmpc-dev \
  libmpfr-dev \
  libgmp-dev \
  bison \
  flex \
  texinfo \
  gperf \
  libtool \
  patchutils \
  bc \
  libexpat-dev \
  libglib2.0-dev \
  libslirp-dev
RUN useradd -m -s /bin/bash spechls-user && echo "spechls-user:spechls" | chpasswd && \
  adduser spechls-user sudo
USER spechls-user
RUN touch /home/spechls-user/.sudo_as_admin_successful
# Setup directories and path
ENV PREFIX=/home/spechls-user/prefix
ENV PATH="$PATH:$PREFIX/bin"
RUN mkdir -p "$PREFIX"
# Setup SpecHLS
ENV SPECHLS_ROOT=/home/spechls-user/spechls
RUN mkdir -p "$SPECHLS_ROOT" && git clone --progress --verbose https://github.com/Lord-of-the-RISCs/setup.git "$SPECHLS_ROOT"
WORKDIR ${SPECHLS_ROOT}
RUN bash setup.sh -irRc
# Setup riscv-gnu-toolchain
WORKDIR /home/spechls-user
RUN git clone https://github.com/riscv-collab/riscv-gnu-toolchain.git
WORKDIR /home/spechls-user/riscv-gnu-toolchain
RUN ./configure --prefix="$PREFIX" --with-arch=rv32i --with-abi=ilp32 && make -j$(nproc) && make install && make clean
# Get embench-iot
WORKDIR /home/spechls-user
RUN git clone --branch embench-1.0 https://github.com/embench/embench-iot.git
WORKDIR /home/spechls-user/embench-iot
RUN ./build_all.py --arch riscv32 --chip generic --board ri5cyverilator --cc riscv32-unknown-elf-gcc --cflags="-c -O2 -ffunction-sections -march=rv32i_zicsr -mabi=ilp32" --ldflags="-Wl,-gc-sections" --user-libs="-lm"

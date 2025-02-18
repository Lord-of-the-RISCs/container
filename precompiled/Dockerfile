FROM ubuntu:24.04
LABEL maintainer="Jean-Michel Gorius <jean-michel.gorius@irisa.fr>"
LABEL description="SpecHLS development environment using precompiled binaries"
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
  libboost-filesystem-dev
RUN useradd -m -s /bin/bash spechls-user && echo "spechls-user:spechls" | chpasswd && \
  adduser spechls-user sudo
USER spechls-user
ENV SPECHLS_ROOT /home/spechls-user/spechls
RUN touch /home/spechls-user/.sudo_as_admin_successful && mkdir -p "$SPECHLS_ROOT" && git config --global --add safe.directory "$SPECHLS_ROOT"
WORKDIR ${SPECHLS_ROOT}

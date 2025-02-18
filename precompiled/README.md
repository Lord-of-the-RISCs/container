# SpecHLS persistent development image

This directory contains a Docker image configuration for active development of SpecHLS. The resulting container relies on an existing pre-compiled distribution of SpecHLS on the host system, and updates inside the container are propagated to the host.

**NOTE:** The README file at the root of this repository contains general instructions to setup Docker on your system.

## Building the image

The contents of the Docker image are described in the [`Dockerfile`](Dockerfile) configuration file. To build the corresponding image, run the following command inside the directory containing the `Dockerfile`.
```sh
docker build --tag 'spechls-dev' .
```
This operation may take a long time, since it will build LLVM, MLIR, and all of SpecHLS' required dependencies.

**WARNING:** The SpecHLS development image requires around 25 GiB of free disk space. Make sure you have enough space available before attempting to build the image.

## Running the container

The following assumes that you have extracted the pre-compiled SpecHLS distribution to the `$SPECHLS_ROOT` directory on the host system.

To run the container, use the following command.
```sh
docker run -it --mount type=bind,source="$SPECHLS_ROOT",target=/home/spechls-user/spechls spechls-dev
# Upon first login, inside of the container, set the permissions of the pre-compiled distribution
sudo chown -R spechls-user .
```
You can then connect to the running instance using Dev Containers. See the top-level README file for more information.


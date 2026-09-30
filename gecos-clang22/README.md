# Local Clang 22 Gecos Image

This image rebuilds the local committed LLVM/MLIR, CIRCT, SpecHLS, Yosys, and
Gecos frontend sources. It replaces the published `spechls-demo:gecos-main`
native prefix and JAR while retaining that image's Ubuntu 24.04, JDK 25, Maven,
and Gecos dependency configuration.

The build context is generated from Git `HEAD` only. Local modifications,
untracked files, Maven outputs, and test artifacts are excluded by design.

## Build

From the LOTR repository root:

```bash
bash container/gecos-clang22/prepare-context.sh "$(pwd)"
```

The resulting image is named:

```text
hls-mlir-demo:spechls
```

The build uses 32 parallel jobs and records the exact source revisions in
`/usr/share/hls-mlir-demo/revisions.txt` in the image.

## Use With The Java Harness

Use the image without `SPEC_HLS_JAR`: it already includes the Gecos JAR built
from the committed local checkout.

```bash
SPECHLS_IMAGE=hls-mlir-demo:spechls \
  spechls-circt/test/Uclid/java/docker-harness/run-in-docker.sh benchmark-001
```

The image defines `CIRCT_PREFIX`, `PATH`, and `LD_LIBRARY_PATH` for its local
Clang 22 native stack. Do not combine this invocation with `GECOS_DEV_VOLUME`
or a host JAR override when validating the self-contained image.

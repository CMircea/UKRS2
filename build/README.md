# Build toolchain for UKRS2 NewGRF work

This directory contains a multi-stage Docker setup for compiling and decompiling NewGRFs with `grfcodec`, plus `nml` tooling.

## Files

- `Dockerfile` - multi-stage image (`builder` builds `grfcodec`, final stage is runtime)
- `.dockerignore` - trims build context
- `scripts/compile.sh` - wrapper for `grfcodec -e`
- `scripts/decompile.sh` - wrapper for `grfcodec -d`

## Build

From repository root:

```bash
docker build -f build/Dockerfile -t ukrs2-toolchain .
```

Optionally pin grfcodec branch/tag/commit:

```bash
docker build -f build/Dockerfile \
  --build-arg GRFCODEC_REF=master \
  -t ukrs2-toolchain .
```

## Run

```bash
docker run --rm -it -v "$PWD":/work ukrs2-toolchain
```

## Usage examples

Inside the container:

```bash
# Decompile a GRF
build/scripts/decompile.sh path/to/file.grf

# Compile an NFO
build/scripts/compile.sh path/to/file.nfo

# Tool help
grfcodec --help
nmlc --help
```

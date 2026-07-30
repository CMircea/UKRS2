# syntax=docker/dockerfile:1

############################
# Stage 1: build grfcodec
############################
FROM debian:bookworm-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    make \
    gcc \
    g++ \
    libc6-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

# Build grfcodec from source
# Pin GRFCODEC_REF to a tag/commit for reproducibility if desired.
ARG GRFCODEC_REF=master
RUN git clone --depth=1 --branch "${GRFCODEC_REF}" https://github.com/OpenTTD/grfcodec.git \
    && make -C grfcodec

############################
# Stage 2: runtime/tooling
############################
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    python3 \
    python3-pip \
    perl \
    file \
    git \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Useful NewGRF companion compiler
RUN pip3 install --no-cache-dir nml

# Copy compiled grfcodec from builder
COPY --from=builder /src/grfcodec/grfcodec /usr/local/bin/grfcodec

WORKDIR /work

CMD ["/bin/bash"]

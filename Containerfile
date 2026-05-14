# Global build args — must be before the first FROM to use in FROM lines
ARG BASE_IMAGE=ghcr.io/ublue-os/bazzite-nvidia-open:stable

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY cosign.pub /cosign.pub

# Build Rio terminal from source (Wayland + librashader filters)
FROM rust:latest AS rio-builder
ARG RIO_VERSION=v0.4.4
RUN apt-get update && apt-get install -y --no-install-recommends \
    cmake pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev glslang-tools
RUN git clone --depth 1 --branch "$RIO_VERSION" https://github.com/raphamorim/rio.git /rio
WORKDIR /rio
RUN RUSTFLAGS='-C link-arg=-s' cargo build -p rioterm --release \
    --no-default-features --features wayland,wgpu

# Base Image — parameterized per variant
FROM ${BASE_IMAGE}

ARG BUILD_SCRIPT=build.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=bind,from=rio-builder,source=/rio,target=/rio \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    --mount=type=secret,id=dkms_key \
    --mount=type=secret,id=dkms_pin \
    --mount=type=secret,id=dkms_cert \
    /ctx/${BUILD_SCRIPT} && \
    ostree container commit

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint

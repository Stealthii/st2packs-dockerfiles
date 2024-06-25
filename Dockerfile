ARG BASE_IMAGE=stackstorm/st2
ARG BASE_IMAGE_TAG=3.8
ARG RUNTIME_IMAGE=alpine
ARG RUNTIME_IMAGE_TAG=3

# Base
FROM $BASE_IMAGE:$BASE_IMAGE_TAG AS base

# Install system packages required for building Python packages
RUN apt-get update && apt-get install -y \
    build-essential \
    libkrb5-dev \
    libssl-dev \
    libffi-dev \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

ONBUILD ARG PACKS
ONBUILD RUN : "${PACKS:?Please add '--build-arg PACKS=\"<space separated list of pack names>\"'.}"

# Builder
FROM base AS builder

# Install custom packs
RUN /opt/stackstorm/st2/bin/st2-pack-install ${PACKS}

###########################
# Minimize the image size. Start with alpine,
# and add only packs and virtualenvs from builder.
FROM $RUNTIME_IMAGE:$RUNTIME_IMAGE_TAG AS runtime

RUN apk add --no-cache rsync

VOLUME ["/opt/stackstorm/packs", "/opt/stackstorm/virtualenvs"]

# Copy packs and virtualenvs
COPY --from=builder /opt/stackstorm/packs /opt/stackstorm/packs
COPY --from=builder /opt/stackstorm/virtualenvs /opt/stackstorm/virtualenvs

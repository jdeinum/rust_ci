# Use Rust image for building
FROM lukemathwalker/cargo-chef:latest-rust-1.89.0 AS chef
WORKDIR /app
RUN apt update

# Install sccache for compilation caching
RUN cargo install sccache --locked

# Configure sccache as the Rust compiler wrapper
ENV RUSTC_WRAPPER=/usr/local/cargo/bin/sccache
ENV SCCACHE_DIR=/sccache
ENV SCCACHE_CACHE_SIZE="10G"

# create our recipe
FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

# build deps
FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
# Use BuildKit cache mount for sccache directory
RUN --mount=type=cache,target=/sccache \
  cargo chef cook --release --recipe-path recipe.json

# build our code
COPY . .
# Use BuildKit cache mount for sccache directory
RUN --mount=type=cache,target=/sccache \
  cargo build --release --bin APP_NAME && \
  echo "=== sccache statistics ===" && \
  sccache --show-stats

# final runtime image
FROM debian:bookworm-slim AS runtime
WORKDIR /app
ENV APP_ENV=production
RUN apt-get update -y \
  && apt-get install -y --no-install-recommends openssl ca-certificates \
  && apt-get autoremove -y \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/APP_NAME app

# just for convienence, but you should really consider using either docker
# volumes (comopose) or ConfigMaps (kubernetes) for deployments.
COPY configuration configuration

# need access to migrations when we start
COPY migrations migrations

# run
ENTRYPOINT ["./app"]

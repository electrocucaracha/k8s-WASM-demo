#checkov:skip=CKV_DOCKER_2:Ensure that HEALTHCHECK instructions have been added to container images
FROM rust:1.90-slim-trixie as builder

WORKDIR /opt/
COPY . .

RUN cargo build --release

FROM debian:trixie-slim
COPY --from=builder /opt/target/release/http-server /opt/http-server/main
CMD ["/opt/http-server/main"]

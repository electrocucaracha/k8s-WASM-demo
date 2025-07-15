FROM rust:1.88-slim-bullseye as builder

WORKDIR /opt/
COPY . .

RUN cargo build --release

FROM debian:bullseye-slim
COPY --from=builder /opt/target/release/http-server /opt/http-server/main
CMD ["/opt/http-server/main"]

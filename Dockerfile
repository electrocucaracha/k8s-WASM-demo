FROM rust:1.62-slim-buster as builder

WORKDIR /opt/
COPY . .

RUN cargo build --release

FROM debian:buster-slim
COPY --from=builder /opt/target/release/http-server /opt/http-server/main
CMD ["/opt/http-server/main"]

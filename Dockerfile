FROM rust:1.51 as builder

RUN USER=root cargo new --bin ora
WORKDIR ./ora
COPY ./Cargo.lock ./Cargo.toml ./
RUN cargo build --release
RUN rm src/*.rs
COPY ./src ./src
RUN rm ./target/release/deps/ora*
RUN cargo build --release

FROM ubuntu:20.04

RUN apt update && apt install -y libssl-dev

COPY --from=builder /ora/target/release/ora .
EXPOSE 8080
ENTRYPOINT ["./ora"]
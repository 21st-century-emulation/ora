FROM nimlang/nim:1.4.6-ubuntu AS build

WORKDIR /app

COPY ora.nimble ora.nimble

RUN nimble refresh && nimble install

COPY ora.nim ora.nim

RUN nim c -d:useStdLib ora.nim

FROM ubuntu:20.04 as runtime

WORKDIR /app
COPY --from=build /app/ora ./ora

ENTRYPOINT ["./ora"]
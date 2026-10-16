# 1. 构建前端和嵌入资源
FROM node:24-bookworm AS frontend
WORKDIR /work
COPY . .
RUN npm ci && npm run prepare_install

# 2. 编译 Go 服务端
FROM golang:1.26.6-bookworm AS builder
WORKDIR /work
COPY --from=frontend /work/src/server ./src/server
WORKDIR /work/src/server/gkill/main/gkill_server
RUN go build -o /gkill_server .

# 3. 运行镜像
FROM debian:bookworm-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /data

COPY --from=builder /gkill_server /usr/local/bin/gkill_server

ENV GKILL_HOME=/data
ENV RUN_MODE=server
ENV PORT=9999

EXPOSE 9999 8810

CMD ["sh", "-c", "if [ \"$RUN_MODE\" = \"mcp\" ]; then exec gkill_server mcp --kind readwrite --transport http; else exec gkill_server; fi"]

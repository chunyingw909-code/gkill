
# ============================================
# gkill - Zeabur Dockerfile
# Go 1.26.9 + Vue + MCP
# ============================================

# 1. 构建前端
FROM node:24-bookworm AS frontend

WORKDIR /work

COPY . .

RUN npm ci && npm run prepare_install


# 2. 编译 Go 后端
FROM golang:1.26.9-bookworm AS builder

WORKDIR /work

COPY --from=frontend /work/src/server ./src/server

WORKDIR /work/src/server/gkill/main/gkill_server

RUN go build -o /gkill_server .


# 3. 创建运行环境
FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /data

COPY --from=builder /gkill_server /usr/local/bin/gkill_server


# 4. Zeabur 环境配置
ENV GKILL_HOME=/data
ENV RUN_MODE=server
ENV PORT=9999

EXPOSE 9999 8810


# 5. 启动 gkill 或 MCP
CMD ["sh", "-c", "if [ \"$RUN_MODE\" = \"mcp\" ]; then exec gkill_server --gkill_home_dir /data mcp --kind readwrite --transport http; else exec gkill_server --address 0.0.0.0:9999 --disable_tls --gkill_home_dir /data; fi"]

# 构建时
FROM docker.io/library/golang:alpine AS builder
ARG REPO
# eg. amd64 | arm64
ARG ARCH
# eg. x86_64 | aarch64
ARG CPU_ARCH
ARG TAG
# eg. latest
ARG IMAGE_VERSION
ENV REPO=$REPO \
     ARCH=$ARCH \
     CPU_ARCH=$CPU_ARCH \
     TAG=$TAG \
     IMAGE_VERSION=$IMAGE_VERSION

RUN apk add --no-cache --virtual .build-deps \
                git

ENV CGO_ENABLED=0 \
     GOOS=linux \
     GOARCH=$ARCH

WORKDIR /output/
WORKDIR /source/
COPY source-src/ ./
RUN go mod download
RUN SHORT_SHA=$(git rev-parse --short HEAD) && \
     go build -o /output/xray -trimpath -buildvcs=false -gcflags="all=-l=4" \
     -ldflags="-X github.com/xtls/xray-core/core.build=${SHORT_SHA} -s -w -buildid=" \
     -v ./main


# 运行时
FROM scratch AS runtime
COPY rootfs/ /
ADD https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geoip.dat /usr/share/xray/geoip.dat
ADD https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geosite.dat /usr/share/xray/geosite.dat
COPY --from=builder /output/xray /usr/sbin/xray
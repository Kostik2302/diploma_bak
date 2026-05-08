# syntax=docker/dockerfile:1
# Сборка Go с возможностью указать корпоративный GOPROXY (Nexus Go Proxy).
ARG GO_VERSION=1.22-alpine

FROM golang:${GO_VERSION} AS build
WORKDIR /src

# По умолчанию — публичный proxy; в CI передайте --build-arg GOPROXY=http://nexus:8081/repository/go-proxy/
ARG GOPROXY=https://proxy.golang.org,direct
ENV GOPROXY=${GOPROXY}

COPY app/go.mod app/main.go ./
RUN go mod tidy \
	&& CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /out/ping .

FROM alpine:3.19
RUN apk add --no-cache ca-certificates
COPY --from=build /out/ping /usr/local/bin/ping
ENV PORT=8080
EXPOSE 8080
USER nobody
CMD ["/usr/local/bin/ping"]

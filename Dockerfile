FROM golang:1.25-alpine AS builder

RUN apk add --no-cache git gcc musl-dev

RUN go install -ldflags="-s -w" github.com/schollz/croc/v10@v10.7.0

FROM alpine:latest

EXPOSE 9009 9010 9011 9012 9013

COPY --from=builder /go/bin/croc /croc
COPY croc-entrypoint.sh /croc-entrypoint.sh

RUN chmod +x /croc-entrypoint.sh

USER nobody

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD sh -c ' \
    P="${CROC_PORTS:-${CROC_PORT:-9009}}"; \
    IFS=,; set -- $P; \
    for p in "$@"; do \
        nc -z -w 3 localhost "$p" || exit 1; \
    done'

ENTRYPOINT ["/croc-entrypoint.sh"]
CMD ["relay"]

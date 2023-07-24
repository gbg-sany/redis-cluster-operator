FROM golang:1.19 as builder

ARG PROJECT_NAME=redis-cluster-operator
ARG BUILD_PATH=./cmd/manager/main.go


WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY pkg ./ cmd ./ version ./ third_party ./

RUN GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o output/${PROJECT_NAME} $BUILD_PATH

# =============================================================================
FROM gcr.io/distroless/static:debug
WORKDIR /
COPY --from=builder /src/output/redis-cluster-operator .

ARG PROJECT_NAME=redis-cluster-operator

RUN adduser -D ${PROJECT_NAME}
USER ${PROJECT_NAME}

ENTRYPOINT ["/redis-cluster-operator"]

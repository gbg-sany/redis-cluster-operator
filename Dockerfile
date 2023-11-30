ARG PROJECT_NAME=redis-cluster-operator
#==============================================================================
FROM golang:1.19 as builder

ARG PROJECT_NAME
ARG ARCH=amd64
ARG BUILD_PATH=./cmd/manager/main.go

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY pkg ./ cmd ./ version ./ third_party ./

RUN GOOS=linux GOARCH=${ARCH} CGO_ENABLED=0 go build -o output/${PROJECT_NAME} $BUILD_PATH

# =============================================================================
FROM gcr.io/distroless/static:debug

ARG PROJECT_NAME

WORKDIR /
COPY --from=builder /src/output/${PROJECT_NAME} /usr/local/bin/${PROJECT_NAME}

ENTRYPOINT ["redis-cluster-operator"]
USER 65532:65532
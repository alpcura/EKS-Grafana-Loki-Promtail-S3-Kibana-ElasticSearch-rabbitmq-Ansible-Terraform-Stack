# -------- build stage --------
FROM --platform=$BUILDPLATFORM golang:1.22 AS build
ARG TARGETOS TARGETARCH
WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download
COPY . .

# Worker ana paketin path'i: ./apps/worker
WORKDIR /src/apps/worker
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /out/worker .

# -------- final stage --------
FROM gcr.io/distroless/static:nonroot
COPY --from=build /out/worker /worker
USER nonroot:nonroot
ENTRYPOINT ["/worker"]
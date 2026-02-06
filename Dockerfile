# Building the binary of the App
FROM public.ecr.aws/docker/library/golang:1.25 AS build

WORKDIR /go/src/wiz
COPY . .
ENV GOPROXY=direct
RUN go mod download
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /go/src/wiz/wiz

FROM public.ecr.aws/docker/library/alpine:3.23 AS release

WORKDIR /app
COPY --from=build /go/src/wiz/wiz .
COPY --from=build /go/src/wiz/assets ./assets
COPY --from=build /go/src/wiz/wizexercise.txt .
EXPOSE 8080
ENTRYPOINT ["/app/wiz"]

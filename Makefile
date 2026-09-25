.PHONY: run build test docker-build

run:
	go run cmd/scanner/main.go

build:
	go build -o bin/clm-scanner cmd/scanner/main.go

test:
	go test -v ./...

docker-build:
	docker build -t clm-scanner:latest .

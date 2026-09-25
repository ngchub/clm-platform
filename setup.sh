#!/usr/bin/env bash
set -e

echo "🚀 Multi-Cloud CLM Platform Proje İskeleti Oluşturuluyor..."

# 1. Dizin Yapısının Oluşturulması
mkdir -p cmd/scanner \
         cmd/api \
         cmd/agent \
         internal/scanner \
         internal/pubsub \
         internal/db \
         internal/alert \
         internal/compliance \
         db/migrations \
         terraform \
         .github/workflows

# 2. go.mod Dosyası
cat << 'EOF' > go.mod
module github.com/clm-saas/platform

go 1.22

require (
	cloud.google.com/go/certificatemanager v1.7.0
	cloud.google.com/go/pubsub v1.36.1
	github.com/Azure/azure-sdk-for-go/sdk/azidentity v1.5.1
	github.com/Azure/azure-sdk-for-go/sdk/resourcemanager/keyvault/armkeyvault v1.4.0
	github.com/Azure/azure-sdk-for-go/sdk/security/keyvault/azcertificates v1.1.0
	github.com/aws/aws-sdk-go-v2 v1.26.1
	github.com/aws/aws-sdk-go-v2/config v1.27.11
	github.com/aws/aws-sdk-go-v2/credentials v1.17.11
	github.com/aws/aws-sdk-go-v2/service/acm v1.25.4
	github.com/aws/aws-sdk-go-v2/service/ec2 v1.156.0
	github.com/aws/aws-sdk-go-v2/service/sts v1.28.6
	github.com/gorilla/websocket v1.5.1
	github.com/redis/go-redis/v9 v9.5.1
	golang.org/x/crypto v0.22.0
	golang.org/x/sync v0.7.0
	google.golang.org/api v0.172.0
	google.golang.org/grpc v1.63.2
)
EOF

# 3. PostgreSQL Veritabanı Şeması
cat << 'EOF' > db/migrations/000001_init_schema.sql
CREATE TABLE IF NOT EXISTS tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS cloud_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    provider VARCHAR(32) NOT NULL,
    account_name VARCHAR(255) NOT NULL,
    role_arn_or_id VARCHAR(512),
    external_id VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS certificates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fingerprint_sha256 VARCHAR(64) UNIQUE NOT NULL,
    serial_number VARCHAR(128) NOT NULL,
    subject_cn VARCHAR(255),
    issuer_cn VARCHAR(255),
    not_before TIMESTAMPTZ NOT NULL,
    not_after TIMESTAMPTZ NOT NULL,
    sans TEXT[],
    raw_pem TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tenant_certificates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    certificate_id UUID REFERENCES certificates(id) ON DELETE RESTRICT,
    cloud_account_id UUID REFERENCES cloud_accounts(id) ON DELETE SET NULL,
    endpoint_host VARCHAR(255) NOT NULL,
    endpoint_port INT DEFAULT 443,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_tenant_endpoint UNIQUE(tenant_id, endpoint_host, endpoint_port)
);

CREATE TABLE IF NOT EXISTS scan_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    endpoint_id UUID REFERENCES tenant_certificates(id) ON DELETE CASCADE,
    certificate_id UUID REFERENCES certificates(id) ON DELETE SET NULL,
    is_chain_valid BOOLEAN NOT NULL,
    ocsp_status VARCHAR(32),
    is_aia_triggered BOOLEAN DEFAULT FALSE,
    error_message TEXT,
    scanned_at TIMESTAMPTZ DEFAULT NOW()
);
EOF

# 4. AWS Multi-Region Scanner (internal/scanner/aws.go)
cat << 'EOF' > internal/scanner/aws.go
package scanner

import (
	"context"
	"fmt"
	"log"
	"sync"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials/stscreds"
	"github.com/aws/aws-sdk-go-v2/service/acm"
	"github.com/aws/aws-sdk-go-v2/service/sts"
	"golang.org/x/sync/errgroup"
)

type CustomerAWSConfig struct {
	RoleARN    string
	ExternalID string
}

type CertificateDetails struct {
	ARN        string
	DomainName string
	Status     string
	NotAfter   time.Time
}

func ScanAWSAllRegions(ctx context.Context, customerCfg CustomerAWSConfig) ([]CertificateDetails, error) {
	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion("us-east-1"))
	if err != nil {
		return nil, err
	}

	stsClient := sts.NewFromConfig(cfg)
	appendedCreds := stscreds.NewAssumeRoleProvider(stsClient, customerCfg.RoleARN, func(o *stscreds.AssumeRoleOptions) {
		o.ExternalID = aws.String(customerCfg.ExternalID)
		o.RoleSessionName = "CLM-Parallel-Scanner"
		o.Duration = 15 * time.Minute
	})

	customerBaseCfg := cfg
	customerBaseCfg.Credentials = aws.NewCredentialsCache(appendedCreds)

	regions := []string{"us-east-1", "us-west-2", "eu-central-1", "eu-west-1", "ap-southeast-1"}

	g, gCtx := errgroup.WithContext(ctx)
	g.SetLimit(10)

	var mu sync.Mutex
	var allCertificates []CertificateDetails

	for _, reg := range regions {
		region := reg
		g.Go(func() error {
			regionCfg := customerBaseCfg.Copy()
			regionCfg.Region = region
			acmClient := acm.NewFromConfig(regionCfg)

			listOutput, err := acmClient.ListCertificates(gCtx, &acm.ListCertificatesInput{})
			if err != nil {
				log.Printf("[%s] Bölge taranamadı: %v", region, err)
				return nil
			}

			var regionCerts []CertificateDetails
			for _, summary := range listOutput.CertificateSummaryList {
				desc, err := acmClient.DescribeCertificate(gCtx, &acm.DescribeCertificateInput{CertificateArn: summary.CertificateArn})
				if err != nil {
					continue
				}
				cert := desc.Certificate
				item := CertificateDetails{
					ARN:        aws.ToString(cert.CertificateArn),
					DomainName: aws.ToString(cert.DomainName),
					Status:     string(cert.Status),
				}
				if cert.NotAfter != nil {
					item.NotAfter = *cert.NotAfter
				}
				regionCerts = append(regionCerts, item)
			}

			if len(regionCerts) > 0 {
				mu.Lock()
				allCertificates = append(allCertificates, regionCerts...)
				mu.Unlock()
			}
			return nil
		})
	}

	if err := g.Wait(); err != nil {
		return nil, err
	}

	return allCertificates, nil
}
EOF

# 5. GCP Pub/Sub Publisher (internal/pubsub/publisher.go)
cat << 'EOF' > internal/pubsub/publisher.go
package pubsub

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"cloud.google.com/go/pubsub"
)

type CertificateScanEvent struct {
	TenantID          string    `json:"tenant_id"`
	Host              string    `json:"host"`
	Port              int       `json:"port"`
	FingerprintSHA256 string    `json:"fingerprint_sha256"`
	OCSPStatus        string    `json:"ocsp_status"`
	ValidTo           time.Time `json:"valid_to"`
}

type EventPublisher struct {
	client *pubsub.Client
	topic  *pubsub.Topic
}

func NewEventPublisher(ctx context.Context, projectID, topicID string) (*EventPublisher, error) {
	client, err := pubsub.NewClient(ctx, projectID)
	if err != nil {
		return nil, fmt.Errorf("pubsub client hatası: %w", err)
	}

	topic := client.Topic(topicID)
	topic.PublishSettings.ByteThreshold = 5000
	topic.PublishSettings.CountThreshold = 100
	topic.PublishSettings.DelayThreshold = 100 * time.Millisecond

	return &EventPublisher{client: client, topic: topic}, nil
}

func (p *EventPublisher) Publish(ctx context.Context, event CertificateScanEvent) (string, error) {
	jsonBytes, err := json.Marshal(event)
	if err != nil {
		return "", err
	}

	msg := &pubsub.Message{Data: jsonBytes}
	res := p.topic.Publish(ctx, msg)
	return res.Get(ctx)
}

func (p *EventPublisher) Close() {
	p.topic.Stop()
	p.client.Close()
}
EOF

# 6. Main App Entry (cmd/scanner/main.go)
cat << 'EOF' > cmd/scanner/main.go
package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"
)

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	log.Println("⚡ CLM Multi-Cloud Scanner Engine Başlatılıyor...")

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	<-sigChan

	log.Println("🛑 Scanner Engine Kapatılıyor...")
}
EOF

# 7. Terraform Altyapı Tanımları (terraform/main.tf)
cat << 'EOF' > terraform/main.tf
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.0" }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" { type = string }
variable "region" { type = string, default = "europe-west1" }
variable "db_password" { type = string, sensitive = true }

resource "google_compute_network" "clm_vpc" {
  name                    = "clm-vpc-prod"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "clm_subnet" {
  name          = "clm-subnet-prod"
  ip_cidr_range = "10.10.0.0/20"
  region        = var.region
  network       = google_compute_network.clm_vpc.id
}

resource "google_vpc_access_connector" "serverless_connector" {
  name          = "clm-vpc-conn"
  region        = var.region
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.clm_vpc.name
  min_instances = 2
  max_instances = 10
  machine_type  = "f1-micro"
}

resource "google_pubsub_topic" "cert_scans_topic" {
  name = "cert.scans"
}

resource "google_pubsub_subscription" "db_writer_sub" {
  name  = "cert-scans-db-writer-sub"
  topic = google_pubsub_topic.cert_scans_topic.name
}
EOF

# 8. Multi-Stage Distroless Dockerfile
cat << 'EOF' > Dockerfile
FROM golang:1.22-alpine AS builder
RUN apk add --no-cache git ca-certificates tzdata
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o /app/clm-scanner ./cmd/scanner/main.go

FROM gcr.io/distroless/static-debian12:nonroot
WORKDIR /app
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /app/clm-scanner /app/clm-scanner
USER 65532:65532
ENTRYPOINT ["/app/clm-scanner"]
EOF

# 9. GitHub Actions Workflow (.github/workflows/deploy.yml)
cat << 'EOF' > .github/workflows/deploy.yml
name: Build and Deploy to GCP Cloud Run

on:
  push:
    branches: [ main ]

permissions:
  contents: read
  id-token: write

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      - name: Run Tests
        run: go test -v ./...
EOF

# 10. Development Makefile
cat << 'EOF' > Makefile
.PHONY: run build test docker-build

run:
	go run cmd/scanner/main.go

build:
	go build -o bin/clm-scanner cmd/scanner/main.go

test:
	go test -v ./...

docker-build:
	docker build -t clm-scanner:latest .
EOF

echo "✅ Proje iskeleti başarıyla oluşturuldu!"
echo "📁 Proje Dizini:"
tree -L 3 || ls -R

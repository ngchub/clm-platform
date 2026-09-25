#!/usr/bin/env bash
set -e

echo "🚀 Tüm CLM SaaS Proje Dosyaları Yerel Diske Yazdırılıyor..."

# 1. Dizin Yapısını Oluştur
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
         .github/workflows \
         app/dashboard

# ==========================================
# 2. FRONTEND: Next.js Freemium Landing Page
# ==========================================
cat << 'EOF' > app/page.tsx
"use client";

import React, { useState } from 'react';
import { ShieldCheck, Search, ArrowRight, Lock, AlertTriangle, Server, Globe } from 'lucide-react';

export default function FreemiumLandingPage() {
  const [domain, setDomain] = useState('');
  const [isScanning, setIsScanning] = useState(false);
  const [scanResult, setScanResult] = useState<any>(null);

  const handleScan = (e: React.FormEvent) => {
    e.preventDefault();
    if (!domain) return;

    setIsScanning(true);
    setScanResult(null);

    setTimeout(() => {
      setIsScanning(false);
      setScanResult({
        domain: domain,
        score: 42,
        totalDiscovered: 14,
        expiredCount: 2,
        criticalIssues: 3,
        findings: [
          { subdomain: `vpn.${domain}`, issuer: "Let's Encrypt", daysLeft: -3, status: 'EXPIRED' },
          { subdomain: `dev-api.${domain}`, issuer: "ZeroSSL", daysLeft: 12, status: 'CRITICAL' },
          { subdomain: `staging.${domain}`, issuer: "DigiCert", daysLeft: 84, status: 'GOOD', isGated: true },
          { subdomain: `legacy-portal.${domain}`, issuer: "Sectigo", daysLeft: -15, status: 'EXPIRED', isGated: true },
          { subdomain: `k8s-ingress.${domain}`, issuer: "Let's Encrypt", daysLeft: 5, status: 'CRITICAL', isGated: true },
        ]
      });
    }, 2000);
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col">
      <nav className="border-b border-slate-800 bg-slate-950/80 backdrop-blur-md sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
          <div className="flex items-center gap-2 font-bold text-xl tracking-tight text-white">
            <ShieldCheck className="w-7 h-7 text-indigo-500" />
            <span>CLM<span className="text-indigo-500">.io</span></span>
          </div>
          <div className="flex items-center gap-4">
            <a href="/login" className="text-sm font-medium text-slate-400 hover:text-white transition-colors">Giriş Yap</a>
            <a href="#scan" className="bg-indigo-600 hover:bg-indigo-500 text-white text-sm font-semibold px-4 py-2 rounded-lg transition-all shadow-lg shadow-indigo-600/20">
              Ücretsiz Tara
            </a>
          </div>
        </div>
      </nav>

      <main className="flex-1 max-w-5xl mx-auto px-6 py-16 w-full">
        <div className="text-center space-y-4 mb-12">
          <span className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full text-xs font-semibold bg-indigo-950/80 text-indigo-400 border border-indigo-800/50">
            <Globe className="w-3.5 h-3.5" /> Canlı Certificate Transparency Log Taraması
          </span>
          <h1 className="text-4xl md:text-6xl font-black text-white tracking-tight leading-tight">
            Şirketinizdeki <span className="text-indigo-500">Shadow IT</span> ve <br />
            Kritik SSL Risklerini Anında Tespit Edin
          </h1>
          <p className="text-slate-400 text-lg max-w-2xl mx-auto">
            Domain adınızı girin, kamuya açık CT Log’ları üzerinden unutulmuş ve süresi dolan sertifikalarınızı saniyeler içinde raporlayalım.
          </p>
        </div>

        <div id="scan" className="max-w-2xl mx-auto bg-slate-900 p-2 rounded-2xl border border-slate-800 shadow-2xl mb-12">
          <form onSubmit={handleScan} className="flex flex-col sm:flex-row gap-2">
            <div className="relative flex-1">
              <Search className="w-5 h-5 absolute left-4 top-1/2 -translate-y-1/2 text-slate-500" />
              <input
                type="text"
                placeholder="sirketadi.com"
                value={domain}
                onChange={(e) => setDomain(e.target.value)}
                className="w-full bg-slate-950 border border-slate-800 rounded-xl pl-12 pr-4 py-3.5 text-white placeholder-slate-500 focus:outline-none focus:border-indigo-500 transition-colors"
                required
              />
            </div>
            <button
              type="submit"
              disabled={isScanning}
              className="bg-indigo-600 hover:bg-indigo-500 disabled:bg-indigo-800 text-white font-bold px-8 py-3.5 rounded-xl transition-all flex items-center justify-center gap-2 whitespace-nowrap shadow-lg shadow-indigo-600/30"
            >
              {isScanning ? (
                <>
                  <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  CT-Log Taranıyor...
                </>
              ) : (
                <>
                  Ücretsiz Tara <ArrowRight className="w-4 h-4" />
                </>
              )}
            </button>
          </form>
        </div>

        {scanResult && (
          <div className="space-y-6 animate-in fade-in duration-500">
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <div className="bg-slate-900 border border-slate-800 p-5 rounded-2xl">
                <p className="text-xs text-slate-400 font-medium">Güvenlik Skoru</p>
                <h3 className="text-3xl font-black text-red-500 mt-1">{scanResult.score}/100</h3>
                <p className="text-xs text-red-400 mt-1">Kritik Risk Tespiti</p>
              </div>
              <div className="bg-slate-900 border border-slate-800 p-5 rounded-2xl">
                <p className="text-xs text-slate-400 font-medium">Tespit Edilen Varlık</p>
                <h3 className="text-3xl font-black text-white mt-1">{scanResult.totalDiscovered}</h3>
                <p className="text-xs text-slate-500 mt-1">Subdomain / Sertifika</p>
              </div>
              <div className="bg-slate-900 border border-slate-800 p-5 rounded-2xl">
                <p className="text-xs text-slate-400 font-medium">Süresi Dolanlar</p>
                <h3 className="text-3xl font-black text-red-500 mt-1">{scanResult.expiredCount}</h3>
                <p className="text-xs text-red-400 mt-1">Acil Müdahale Gerekli</p>
              </div>
              <div className="bg-slate-900 border border-slate-800 p-5 rounded-2xl">
                <p className="text-xs text-slate-400 font-medium">Kritik Zincir Riski</p>
                <h3 className="text-3xl font-black text-amber-500 mt-1">{scanResult.criticalIssues}</h3>
                <p className="text-xs text-amber-400 mt-1">Kırık Intermediate CA</p>
              </div>
            </div>

            <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden relative">
              <div className="p-4 border-b border-slate-800 bg-slate-900/80 flex items-center justify-between">
                <h3 className="font-bold text-white flex items-center gap-2">
                  <AlertTriangle className="w-5 h-5 text-amber-500" />
                  CT-Log Taramasında Tespit Edilen Riskler
                </h3>
              </div>

              <div className="divide-y divide-slate-800">
                {scanResult.findings.map((item: any, idx: number) => (
                  <div
                    key={idx}
                    className={`p-4 flex items-center justify-between transition-all ${item.isGated ? 'blur-sm select-none opacity-30' : ''}`}
                  >
                    <div className="flex items-center gap-3">
                      <Server className="w-5 h-5 text-slate-500" />
                      <div>
                        <p className="font-mono text-sm font-semibold text-slate-200">{item.subdomain}</p>
                        <p className="text-xs text-slate-500">Yayıncı: {item.issuer}</p>
                      </div>
                    </div>
                    <div>
                      {item.status === 'EXPIRED' && (
                        <span className="text-xs bg-red-950 text-red-400 border border-red-800 px-3 py-1 rounded-md font-medium">
                          Süresi Doldu ({Math.abs(item.daysLeft)} gün önce)
                        </span>
                      )}
                      {item.status === 'CRITICAL' && (
                        <span className="text-xs bg-amber-950 text-amber-400 border border-amber-800 px-3 py-1 rounded-md font-medium">
                          Kritik Zincir Hatası
                        </span>
                      )}
                    </div>
                  </div>
                ))}
              </div>

              <div className="absolute inset-x-0 bottom-0 h-64 bg-gradient-to-t from-slate-950 via-slate-950/90 to-transparent flex items-end justify-center pb-8 px-4">
                <div className="bg-slate-900 border border-slate-700 p-6 rounded-2xl shadow-2xl max-w-lg w-full text-center space-y-3">
                  <div className="w-10 h-10 bg-indigo-600/20 text-indigo-400 rounded-full flex items-center justify-center mx-auto">
                    <Lock className="w-5 h-5" />
                  </div>
                  <h4 className="text-lg font-bold text-white">Kalan {scanResult.totalDiscovered - 2} Gizli Risk Tespiti Açın</h4>
                  <p className="text-xs text-slate-400">
                    `{domain}` altındaki tüm Unmonitored Shadow IT sertifikalarını görmek ve otonom yenilemeyi başlatmak için ücretsiz hesabınızı aktifleştirin.
                  </p>
                  <button className="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-bold py-3 px-6 rounded-xl transition-all flex items-center justify-center gap-2 text-sm shadow-lg shadow-indigo-600/30">
                    Ücretsiz Hesabı Aktifleştir <ArrowRight className="w-4 h-4" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
EOF

# ==========================================
# 3. FRONTEND: Next.js Multi-Cloud Dashboard
# ==========================================
cat << 'EOF' > app/dashboard/page.tsx
"use client";

import React, { useState } from 'react';
import { Shield, Cloud, Server, AlertCircle, CheckCircle2, RefreshCw, ExternalLink, Filter, Plus } from 'lucide-react';

export default function DashboardPage() {
  const [certificates] = useState([
    { id: '1', domain: 'api.sirket.com', provider: 'AWS', region: 'us-east-1', daysLeft: 82, status: 'HEALTHY', autoRenew: true },
    { id: '2', domain: 'payment.sirket.com', provider: 'AZURE', region: 'westeurope', daysLeft: 12, status: 'WARNING', autoRenew: true },
    { id: '3', domain: 'legacy-vpn.sirket.com', provider: 'ON_PREM', region: 'internal-vpc', daysLeft: -2, status: 'CRITICAL', autoRenew: false },
    { id: '4', domain: 'staging.sirket.com', provider: 'GCP', region: 'europe-west1', daysLeft: 45, status: 'HEALTHY', autoRenew: true },
  ]);

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex">
      <aside className="w-64 border-r border-slate-800 p-6 flex flex-col justify-between hidden md:flex">
        <div className="space-y-8">
          <div className="flex items-center gap-2 font-bold text-xl text-white">
            <Shield className="w-6 h-6 text-indigo-500" />
            <span>CLM Platform</span>
          </div>
          <nav className="space-y-1">
            <a href="#" className="flex items-center gap-3 px-3 py-2 bg-indigo-600/10 text-indigo-400 font-semibold rounded-xl border border-indigo-800/30">
              <Server className="w-4 h-4" /> Envanter & Sertifikalar
            </a>
            <a href="#" className="flex items-center gap-3 px-3 py-2 text-slate-400 hover:text-white hover:bg-slate-900 rounded-xl transition-colors">
              <Cloud className="w-4 h-4" /> Bulut Hesapları
            </a>
            <a href="#" className="flex items-center gap-3 px-3 py-2 text-slate-400 hover:text-white hover:bg-slate-900 rounded-xl transition-colors">
              <RefreshCw className="w-4 h-4" /> Otonom Yenileme (ACME)
            </a>
          </nav>
        </div>
        <div className="bg-slate-900 border border-slate-800 p-4 rounded-xl">
          <p className="text-xs text-slate-400">Aktif Abonelik</p>
          <p className="text-sm font-bold text-white mt-0.5">Enterprise Plan</p>
          <p className="text-xs text-indigo-400 mt-2 font-mono">142/500 Sertifika</p>
        </div>
      </aside>

      <main className="flex-1 p-8 overflow-y-auto">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-8">
          <div>
            <h1 className="text-2xl font-bold text-white">Multi-Cloud Sertifika Envanteri</h1>
            <p className="text-slate-400 text-sm mt-1">Tüm bulut ve VPC ağlarınızdaki aktif TLS/SSL durumları</p>
          </div>
          <button className="bg-indigo-600 hover:bg-indigo-500 text-white font-semibold px-4 py-2.5 rounded-xl transition-all flex items-center gap-2 text-sm shadow-lg shadow-indigo-600/20">
            <Plus className="w-4 h-4" /> Yeni Bulut Hesabı Bağla
          </button>
        </div>

        <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-2xl">
          <div className="p-4 border-b border-slate-800 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Filter className="w-4 h-4 text-slate-400" />
              <span className="text-sm font-medium text-slate-300">Filtrele</span>
            </div>
            <span className="text-xs text-slate-500 font-mono">Toplam: {certificates.length} Sertifika</span>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-slate-300">
              <thead className="bg-slate-950/50 text-slate-400 uppercase text-xs border-b border-slate-800">
                <tr>
                  <th className="p-4">Domain / Endpoint</th>
                  <th className="p-4">Sağlayıcı</th>
                  <th className="p-4">Bölge / Ağ</th>
                  <th className="p-4">Kalan Süre</th>
                  <th className="p-4">Auto-Renewal</th>
                  <th className="p-4 text-right">Durum</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800">
                {certificates.map((cert) => (
                  <tr key={cert.id} className="hover:bg-slate-800/50 transition-colors">
                    <td className="p-4 font-mono font-medium text-white flex items-center gap-2">
                      {cert.domain}
                      <ExternalLink className="w-3.5 h-3.5 text-slate-500" />
                    </td>
                    <td className="p-4 font-semibold">
                      <span className={`px-2.5 py-1 rounded-md text-xs border ${
                        cert.provider === 'AWS' ? 'bg-amber-950/50 text-amber-400 border-amber-800' :
                        cert.provider === 'AZURE' ? 'bg-blue-950/50 text-blue-400 border-blue-800' :
                        cert.provider === 'GCP' ? 'bg-red-950/50 text-red-400 border-red-800' :
                        'bg-purple-950/50 text-purple-400 border-purple-800'
                      }`}>
                        {cert.provider}
                      </span>
                    </td>
                    <td className="p-4 text-slate-400 text-xs font-mono">{cert.region}</td>
                    <td className="p-4">
                      {cert.daysLeft < 0 ? (
                        <span className="text-red-500 font-bold">{Math.abs(cert.daysLeft)} gün önce doldu</span>
                      ) : (
                        <span className={cert.daysLeft <= 15 ? 'text-amber-400 font-bold' : 'text-slate-300'}>
                          {cert.daysLeft} gün kaldı
                        </span>
                      )}
                    </td>
                    <td className="p-4">
                      {cert.autoRenew ? (
                        <span className="inline-flex items-center gap-1 text-xs text-emerald-400">
                          <CheckCircle2 className="w-3.5 h-3.5" /> Aktif (ACME)
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 text-xs text-slate-500">
                          Devre Dışı
                        </span>
                      )}
                    </td>
                    <td className="p-4 text-right">
                      {cert.status === 'HEALTHY' && (
                        <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-emerald-950 text-emerald-400 border border-emerald-800">
                          <CheckCircle2 className="w-3.5 h-3.5" /> Sağlıklı
                        </span>
                      )}
                      {cert.status === 'WARNING' && (
                        <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-amber-950 text-amber-400 border border-amber-800">
                          <AlertCircle className="w-3.5 h-3.5" /> Riskli (Süre Az)
                        </span>
                      )}
                      {cert.status === 'CRITICAL' && (
                        <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-red-950 text-red-400 border border-red-800">
                          <AlertCircle className="w-3.5 h-3.5" /> Kritik
                        </span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </main>
    </div>
  );
}
EOF

# ==========================================
# 4. BACKEND: Go Modülü ve Bağımlılıklar
# ==========================================
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

# ==========================================
# 5. DB: PostgreSQL Hibrit Şema
# ==========================================
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

# ==========================================
# 6. SCANNER: AWS Multi-Region Scanner
# ==========================================
cat << 'EOF' > internal/scanner/aws.go
package scanner

import (
	"context"
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

# ==========================================
# 7. PUBSUB: GCP Cloud Pub/Sub Publisher
# ==========================================
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

# ==========================================
# 8. COMPLIANCE: SOC2 / PCI-DSS Rule Engine
# ==========================================
cat << 'EOF' > internal/compliance/engine.go
package compliance

import (
	"fmt"
	"time"
)

type ComplianceStandard string

const (
	StandardPCIDSS   ComplianceStandard = "PCI_DSS_V4"
	StandardSOC2     ComplianceStandard = "SOC2_TYPE2"
	StandardISO27001 ComplianceStandard = "ISO_27001_2022"
)

type Violation struct {
	Standard    ComplianceStandard `json:"standard"`
	Clause      string             `json:"clause"`
	Severity    string             `json:"severity"`
	Description string             `json:"description"`
	Remediation string             `json:"remediation"`
}

type EndpointScanResult struct {
	Host          string
	TLSVersion    string
	KeyBits       int
	IsChainValid  bool
	OCSPStatus    string
	ValidTo       time.Time
}

func EvaluateCompliance(scan EndpointScanResult) []Violation {
	var violations []Violation

	if scan.TLSVersion == "TLS1.0" || scan.TLSVersion == "TLS1.1" || scan.TLSVersion == "SSLv3" {
		violations = append(violations, Violation{
			Standard:    StandardPCIDSS,
			Clause:      "PCI-DSS v4.0 Req 4.2.1",
			Severity:    "CRITICAL",
			Description: fmt.Sprintf("%s üzerinde zayıf protokol tespiti (%s).", scan.Host, scan.TLSVersion),
			Remediation: "Sunucu konfigürasyonundan TLS 1.0/1.1'i kapatın, minimum TLS 1.2 veya TLS 1.3 zorunlu kılın.",
		})
	}

	if scan.KeyBits < 2048 {
		violations = append(violations, Violation{
			Standard:    StandardPCIDSS,
			Clause:      "PCI-DSS v4.0 Req 4.2.1",
			Severity:    "HIGH",
			Description: fmt.Sprintf("Sertifika anahtar boyutu zayıf (%d bit).", scan.KeyBits),
			Remediation: "En az 2048-bit RSA veya 256-bit ECC anahtar çifti ile yeni bir CSR oluşturup sertifikayı re-issue edin.",
		})
	}

	if !scan.IsChainValid {
		violations = append(violations, Violation{
			Standard:    StandardSOC2,
			Clause:      "SOC 2 CC6.7",
			Severity:    "CRITICAL",
			Description: fmt.Sprintf("%s sertifika zinciri doğrulanamadı (Incomplete CA Chain).", scan.Host),
			Remediation: "Eksik Intermediate CA sertifikasını web sunucunuzun SSL bundle dosyasına ekleyin.",
		})
	}

	return violations
}
EOF

# ==========================================
# 9. MAIN: Go Scanner Entry Point
# ==========================================
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

# ==========================================
# 10. TERRAFORM: GCP Infrastructure
# ==========================================
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

# ==========================================
# 11. DOCKER & CI/CD: Dockerfile & Workflow
# ==========================================
cat << 'EOF' > Dockerfile
FROM golang:1.22-alpine AS builder
RUN apk add --no-cache git ca-certificates tzdata
WORKDIR /app
COPY go.mod ./
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

# ==========================================
# 12. MAKEFILE: Development Shortcuts
# ==========================================
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

echo "✨ Tüm frontend, backend, veritabanı, altyapı ve pipeline dosyaları başarıyla yerel ortama eklendi!"
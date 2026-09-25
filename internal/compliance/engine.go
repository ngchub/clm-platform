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

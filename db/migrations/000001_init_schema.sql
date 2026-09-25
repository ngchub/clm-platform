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

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

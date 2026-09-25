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

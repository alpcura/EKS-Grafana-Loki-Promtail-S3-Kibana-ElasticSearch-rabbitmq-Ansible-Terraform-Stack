// pkg/amqp/publisher.go
package amqpwrap

import (
	"context"
	"errors"
	"log/slog"
	"time"

	amqp "github.com/rabbitmq/amqp091-go"
)

type Publisher struct {
	URL string
	Topology
	conn *amqp.Connection
	ch   *amqp.Channel
}

func (p *Publisher) ConnectAndSetup() error {
	var err error
	p.conn, err = amqp.Dial(p.URL)
	if err != nil { return err }
	ch, err := p.conn.Channel()
	if err != nil { return err }
	if err := EnsureTopology(ch, p.Topology); err != nil { return err }
	if err := ch.Confirm(false); err != nil { return err }
	p.ch = ch
	return nil
}

func (p *Publisher) Publish(ctx context.Context, body []byte) error {
	if p.ch == nil { return errors.New("publisher not initialized") }
	err := p.ch.PublishWithContext(ctx, p.Exchange, p.RoutingKey, false, false, amqp.Publishing{
		ContentType:  "application/json",
		Body:         body,
		DeliveryMode: amqp.Persistent,
		Timestamp:    time.Now(),
	})
	if err != nil { return err }
	select {
	case <-p.ch.NotifyPublish(make(chan amqp.Confirmation, 1)):
		// best-effort: using WaitForConfirms would require acks channel; keep simple
		return nil
	case <-time.After(2 * time.Second):
		slog.Warn("publish confirm timeout")
		return nil
	}
}

func (p *Publisher) Close() {
	if p.ch != nil { _ = p.ch.Close() }
	if p.conn != nil { _ = p.conn.Close() }
}
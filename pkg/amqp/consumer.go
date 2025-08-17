// pkg/amqp/consumer.go
package amqpwrap

import (
	"context"

	amqp "github.com/rabbitmq/amqp091-go"
)

type Handler func([]byte) error

type Consumer struct {
	URL string
	Topology
	conn *amqp.Connection
	ch   *amqp.Channel
}

func (c *Consumer) ConnectAndSetup(prefetch int) error {
	var err error
	c.conn, err = amqp.Dial(c.URL)
	if err != nil { return err }
	ch, err := c.conn.Channel()
	if err != nil { return err }
	if err := EnsureTopology(ch, c.Topology); err != nil { return err }
	if err := ch.Qos(prefetch, 0, false); err != nil { return err }
	c.ch = ch
	return nil
}

func (c *Consumer) Consume(ctx context.Context, h Handler) error {
	deliveries, err := c.ch.Consume(c.Queue, "", false, false, false, false, nil)
	if err != nil { return err }
	for {
		select {
		case d, ok := <-deliveries:
			if !ok { return context.Canceled }
			if err := h(d.Body); err != nil {
				_ = d.Nack(false, false) // send to DLX
			} else {
				_ = d.Ack(false)
			}
		case <-ctx.Done():
			return ctx.Err()
		}
	}
}

func (c *Consumer) Close() {
	if c.ch != nil { _ = c.ch.Close() }
	if c.conn != nil { _ = c.conn.Close() }
}
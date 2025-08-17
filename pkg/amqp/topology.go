// pkg/amqp/topology.go
package amqpwrap

import amqp "github.com/rabbitmq/amqp091-go"

type Topology struct {
	Exchange     string
	RoutingKey   string
	Queue        string
	DeadExchange string
	DeadQueue    string
}

func EnsureTopology(ch *amqp.Channel, t Topology) error {
	// DLX & DLQ
	if err := ch.ExchangeDeclare(t.DeadExchange, "fanout", true, false, false, false, nil); err != nil {
		return err
	}
	if _, err := ch.QueueDeclare(t.DeadQueue, true, false, false, false, nil); err != nil {
		return err
	}
	if err := ch.QueueBind(t.DeadQueue, "", t.DeadExchange, false, nil); err != nil {
		return err
	}

	// Main exchange/queue with DLX
	if err := ch.ExchangeDeclare(t.Exchange, "direct", true, false, false, false, nil); err != nil {
		return err
	}
	args := amqp.Table{"x-dead-letter-exchange": t.DeadExchange}
	if _, err := ch.QueueDeclare(t.Queue, true, false, false, false, args); err != nil {
		return err
	}
	if err := ch.QueueBind(t.Queue, t.RoutingKey, t.Exchange, false, nil); err != nil {
		return err
	}
	return nil
}
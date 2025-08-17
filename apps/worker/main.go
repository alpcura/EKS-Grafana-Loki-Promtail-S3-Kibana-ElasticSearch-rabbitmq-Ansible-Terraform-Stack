package main

import (
	"context"
	"encoding/json"
	"log/slog"

	"os/signal"
	"time"
	"syscall"

	"eks-go-rmq-pro/pkg/amqp"
	"eks-go-rmq-pro/pkg/config"
	"eks-go-rmq-pro/pkg/logger"
)

type Task struct {
	ID string `json:"id"`
	Type string `json:"type"`
	Payload map[string]any `json:"payload"`
}

func main() {
	logger.Init()
	cfg := config.FromEnv()

	top := amqpwrap.Topology{
		Exchange: "tasks", RoutingKey: "tasks.rk", Queue: "tasks.q",
		DeadExchange: "tasks.dlx", DeadQueue: "tasks.dlq",
	}
	cons := &amqpwrap.Consumer{URL: cfg.AMQPURL, Topology: top}
	if err := cons.ConnectAndSetup(20); err != nil { panic(err) }
	defer cons.Close()

	ctx, cancel := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM); defer cancel()
	slog.Info("worker started", "queue", top.Queue)

	handle := func(b []byte) error {
		var t Task
		_ = json.Unmarshal(b, &t)
		slog.Info("processing", "id", t.ID, "type", t.Type)
		time.Sleep(200 * time.Millisecond) // simulate work
		return nil
	}

	if err := cons.Consume(ctx, handle); err != nil { slog.Error("consume", "err", err) }
}
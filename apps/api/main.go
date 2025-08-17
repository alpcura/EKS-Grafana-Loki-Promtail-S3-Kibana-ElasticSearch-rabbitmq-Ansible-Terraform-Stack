package main

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"time"
	"syscall"

	"github.com/go-chi/chi/v5"

	"eks-go-rmq-pro/pkg/amqp"
	"eks-go-rmq-pro/pkg/config"
	"eks-go-rmq-pro/pkg/logger"
	"eks-go-rmq-pro/pkg/repository"
	"eks-go-rmq-pro/pkg/services"
)

func main() {
	logger.Init()
	cfg := config.FromEnv()

	top := amqpwrap.Topology{
		Exchange: "tasks", RoutingKey: "tasks.rk", Queue: "tasks.q",
		DeadExchange: "tasks.dlx", DeadQueue: "tasks.dlq",
	}

	pub := &amqpwrap.Publisher{URL: cfg.AMQPURL, Topology: top}
	if err := pub.ConnectAndSetup(); err != nil { panic(err) }
	defer pub.Close()

	repo := repository.NewMemoryRepo()
	svc  := services.NewTaskService(repo, pub)

	r := chi.NewRouter()
	r.Get("/healthz", func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusOK); _,_ = w.Write([]byte("ok")) })
	r.Get("/readyz",  func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusOK); _,_ = w.Write([]byte("ready")) })

	r.Post("/v1/tasks", func(w http.ResponseWriter, r *http.Request) {
		var in services.CreateTaskInput
		if err := json.NewDecoder(r.Body).Decode(&in); err != nil || in.Type == "" {
			http.Error(w, "invalid body (need type, payload)", http.StatusBadRequest); return
		}
		ctx, cancel := context.WithTimeout(r.Context(), 3*time.Second); defer cancel()
		task, err := svc.CreateTask(ctx, in)
		if err != nil { slog.Error("create", "err", err); http.Error(w, "publish failed", http.StatusInternalServerError); return }
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusAccepted)
		_ = json.NewEncoder(w).Encode(task)
	})

	srv := &http.Server{ Addr: ":"+cfg.AppPort, Handler: r }
	go func() { slog.Info("api listening", "port", cfg.AppPort); _ = srv.ListenAndServe() }()

	// Graceful shutdown
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)
	<-stop
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second); defer cancel()
	_ = srv.Shutdown(ctx)
}
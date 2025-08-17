// pkg/config/config.go
package config

import "os"

type Config struct {
	AppPort     string
	QueueName   string
	AMQPURL     string
}

func FromEnv() Config {
	return Config{
		AppPort:   getenv("APP_PORT", "8080"),
		QueueName: getenv("QUEUE_NAME", "tasks"),
		AMQPURL:   getenv("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/"),
	}
}

func getenv(k, def string) string {
	if v := os.Getenv(k); v != "" { return v }
	return def
}
package models

import "time"

type Task struct {
	ID        string                 `json:"id"`
	Type      string                 `json:"type"`
	Payload   map[string]any         `json:"payload"`
	CreatedAt time.Time              `json:"created_at"`
}
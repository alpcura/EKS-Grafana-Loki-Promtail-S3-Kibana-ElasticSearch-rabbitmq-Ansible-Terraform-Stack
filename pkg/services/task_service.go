package services

import (
	"context"
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"eks-go-rmq-pro/pkg/models"
	"eks-go-rmq-pro/pkg/repository"
)

type Publisher interface {
	Publish(ctx context.Context, body []byte) error
}

type TaskService struct {
	repo repository.TaskRepository
	pub  Publisher
}

func NewTaskService(repo repository.TaskRepository, pub Publisher) *TaskService {
	return &TaskService{repo: repo, pub: pub}
}

type CreateTaskInput struct {
	Type    string         `json:"type"`
	Payload map[string]any `json:"payload"`
}

func (s *TaskService) CreateTask(ctx context.Context, in CreateTaskInput) (models.Task, error) {
	t := models.Task{
		ID:        uuid.NewString(),
		Type:      in.Type,
		Payload:   in.Payload,
		CreatedAt: time.Now().UTC(),
	}
	b, _ := json.Marshal(t)
	if err := s.pub.Publish(ctx, b); err != nil {
		return models.Task{}, err
	}
	if err := s.repo.Save(t); err != nil {
		return models.Task{}, err
	}
	return t, nil
}
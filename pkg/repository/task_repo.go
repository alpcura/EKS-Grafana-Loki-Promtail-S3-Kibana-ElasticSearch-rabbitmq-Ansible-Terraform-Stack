// pkg/repository/task_repo.go
package repository

import "eks-go-rmq-pro/pkg/models"

type TaskRepository interface {
	Save(t models.Task) error
	Get(id string) (models.Task, bool)
}
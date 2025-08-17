// pkg/repository/memory_repo.go
package repository

import (
	"sync"
	"eks-go-rmq-pro/pkg/models"
)

type MemoryRepo struct {
	mu    sync.RWMutex
	store map[string]models.Task
}

func NewMemoryRepo() *MemoryRepo {
	return &MemoryRepo{store: map[string]models.Task{}}
}

func (r *MemoryRepo) Save(t models.Task) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.store[t.ID] = t
	return nil
}

func (r *MemoryRepo) Get(id string) (models.Task, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	v, ok := r.store[id]
	return v, ok
}
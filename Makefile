.PHONY: tidy build up down logs seed
tidy:
	go mod tidy

build:
	docker build -t eks-go-rmq-pro:local .

up:
	docker compose --env-file .env up -d --build

down:
	docker compose down -v

logs:
	docker compose logs -f --tail=200

seed:
	curl -s -X POST http://localhost:8080/v1/tasks \
	  -H 'Content-Type: application/json' \
	  -d '{"type":"email","payload":{"to":"user@example.com","subject":"Hello"}}' | jq .
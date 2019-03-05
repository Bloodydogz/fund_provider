main: dev
stop: down

dev: 
	docker-compose -f docker-compose.dev.yml up
prod:
	docker-compose -f docker-compose.prod.yml up

down: 
	docker-compose -f docker-compose.dev.yml down
	docker-compose -f docker-compose.prod.yml down

#-----------------------------------------------------------
# Set up environment variables
#-----------------------------------------------------------

UID=$(shell id -u)
GID=$(shell id -g)


#-----------------------------------------------------------
# Docker
#-----------------------------------------------------------

# Wake up docker containers
up:
	docker-compose up -d

# Shut down docker containers
down:
	docker-compose down

# Show a status of each container
status:
	docker-compose ps

# Status alias
s: status

# Show logs of each container
logs:
	docker-compose logs

# Restart all containers
restart: down up

# Restart the client container
restart-client:
	docker-compose restart client

# Restart the client container alias
rc: restart-client

# Show the client logs
logs-client:
	docker-compose logs client

# Show the client logs alias
lc: logs-client

# Build and up docker containers
build:
	docker-compose build --build-arg UID=$(UID) --build-arg GID=$(GID)

# Build containers with no cache option
build-no-cache:
	docker-compose build --no-cache

# Build and up docker containers
rebuild: down build

# Run terminal of the php container
php:
	docker-compose exec php bash

# Run terminal of the client container
client:
	docker-compose exec client /bin/sh


#-----------------------------------------------------------
# Logs
#-----------------------------------------------------------

# Clear file-based logs
logs-clear:
	sudo rm docker/dev/nginx/logs/*.log
	sudo rm docker/dev/supervisor/logs/*.log
	sudo rm api/storage/logs/*.log


#-----------------------------------------------------------
# Database
#-----------------------------------------------------------

# Run database migrations
db-migrate:
	docker-compose exec php php artisan migrate

# Migrate alias
migrate: db-migrate

# Run migrations rollback
db-rollback:
	docker-compose exec php php artisan migrate:rollback

# Rollback alias
rollback: db-rollback

# Run seeders
db-seed:
	docker-compose exec php php artisan db:seed

# Fresh all migrations
db-fresh:
	docker-compose exec php php artisan migrate:fresh

# Dump database into file
db-dump:
	docker-compose exec postgres pg_dump -U app -d app > docker/postgres/dumps/dump.sql


#-----------------------------------------------------------
# Redis
#-----------------------------------------------------------

redis:
	docker-compose exec redis redis-cli

redis-flush:
	docker-compose exec redis redis-cli FLUSHALL

#-----------------------------------------------------------
# Queue
#-----------------------------------------------------------

# Restart queue process
queue-restart:
	docker-compose exec php php artisan queue:restart


#-----------------------------------------------------------
# Testing
#-----------------------------------------------------------

# Run phpunit tests
test:
	docker-compose exec php vendor/bin/phpunit --order-by=defects --stop-on-defect

# Run all tests ignoring failures.
test-all:
	docker-compose exec php vendor/bin/phpunit --order-by=defects

# Run phpunit tests with coverage
coverage:
	docker-compose exec php vendor/bin/phpunit --coverage-html tests/report

# Run phpunit tests
dusk:
	docker-compose exec php php artisan dusk

# Generate metrics
metrics:
	docker-compose exec php vendor/bin/phpmetrics --report-html=api/tests/metrics api/app


#-----------------------------------------------------------
# Dependencies
#-----------------------------------------------------------

# Install composer dependencies
composer-install:
	docker-compose exec php composer install

# Update composer dependencies
composer-update:
	docker-compose exec php composer update

# Update yarn dependencies
yarn-update:
	docker-compose exec client yarn update

# Update all dependencies
dependencies-update: composer-update yarn-update

# Show composer outdated dependencies
composer-outdated:
	docker-compose exec yarn outdated

# Show yarn outdated dependencies
yarn-outdated:
	docker-compose exec yarn outdated

# Show all outdated dependencies
outdated: yarn-update composer-outdated


#-----------------------------------------------------------
# Tinker
#-----------------------------------------------------------

# Run tinker
tinker:
	docker-compose exec php php artisan tinker


#-----------------------------------------------------------
# Installation
#-----------------------------------------------------------

# Copy the Laravel API environment file
env-api:
	cp .env.api api/.env

# Copy the NuxtJS environment file
env-client:
	cp .env.client client/.env

# Add permissions for Laravel cache and storage folders
permissions:
	sudo chmod -R 777 api/bootstrap/cache
	sudo chmod -R 777 api/storage

# Permissions alias
perm: permissions

# Generate a Laravel app key
key:
	docker-compose exec php php artisan key:generate --ansi

# Generate a Laravel storage symlink
storage:
	docker-compose exec php php artisan storage:link

# PHP composer autoload command
autoload:
	docker-compose exec php composer dump-autoload

# Install the environment
install: build up install-laravel env-api migrate install-nuxt env-client restart


#-----------------------------------------------------------
# Git commands
#-----------------------------------------------------------

# Undo the last commit
git-undo:
	git reset --soft HEAD~1

# Make a Work In Progress commit
git-wip:
	git add .
	git commit -m "WIP"

# Export the codebase as app.zip archive
git-export:
	git archive --format zip --output app.zip master


#-----------------------------------------------------------
# Frameworks installation
#-----------------------------------------------------------

# Laravel
install-laravel:
	docker-compose down
	sudo rm -rf api
	mkdir api
	docker-compose up -d
	docker-compose exec php composer create-project --prefer-dist laravel/laravel .
	sudo chmod -R 777 api/bootstrap/cache
	sudo chmod -R 777 api/storage
	sudo rm api/.env
	cp .env.api api/.env
	docker-compose exec php php artisan key:generate --ansi
	docker-compose exec php php artisan --version

# Nuxt
install-nuxt:
	docker-compose down
	sudo rm -rf client
	docker-compose run client yarn create nuxt-app ../client
	sudo chown -R ${UID}:${GID} client
	cp .env.client client/.env
	sed -i "1i require('dotenv').config()" client/nuxt.config.js
	docker-compose up -d
	docker-compose exec client yarn info nuxt version


#-----------------------------------------------------------
# Clearing
#-----------------------------------------------------------

# Shut down and remove all volumes
remove-volumes:
	docker-compose down --volumes

# Remove all existing networks (useful if network already exists with the same attributes)
prune-networks:
	docker network prune

# Clear cache
prune-a:
	docker system prune -a

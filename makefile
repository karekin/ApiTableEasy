
define RUN_LOCAL_TXT
Which service do you want to start run?
  1) backend-server
  2) room-server
  3) web-server
endef
export RUN_LOCAL_TXT

ifndef ENV_FILE
ENV_FILE := .env
export ENV_FILE
endif

ifndef DEVENV_FILE
DEVENV_FILE := .env.devenv
export DEVENV_FILE
endif

_dataenv-volumes: ## create data folder with current user permissions
	mkdir -p ./.data/mysql \
	./.data/minio/data \
	./.data/minio/config \
	./.data/redis \
	./.data/rabbitmq \

.PHONY: dataenv
dataenv: _dataenv-volumes
	docker compose --env-file .env -p apitable-devenv -f docker-compose.yaml -f docker-compose.dataenv.yaml up -d mysql minio redis rabbitmq init-db init-appdata

run:
	@echo "$$RUN_LOCAL_TXT"
	@read -p "ENTER THE NUMBER: " SERVICE ;\
 	if [ "$$SERVICE" = "1" ]; then make _run-local-backend-server; fi ;\
 	if [ "$$SERVICE" = "2" ]; then make _run-local-room-server; fi ;\
 	if [ "$$SERVICE" = "3" ]; then make _run-local-web-server; fi ;\

_run-local-backend-server:
	source scripts/export-env.sh $$ENV_FILE;\
	source scripts/export-env.sh $$DEVENV_FILE;\
	cd backend-server ;\
	./gradlew build -x test ;\
	MYSQL_HOST=127.0.0.1 \
	REDIS_HOST=127.0.0.1 \
	RABBITMQ_HOST=127.0.0.1 \
	java -jar application/build/libs/application.jar

_run-local-room-server:
	source scripts/export-env.sh $$ENV_FILE;\
	source scripts/export-env.sh $$DEVENV_FILE;\
	pnpm run start:room-server

_run-local-web-server:
	source scripts/export-env.sh $$ENV_FILE;\
	source scripts/export-env.sh $$DEVENV_FILE;\
	rm -rf packages/datasheet/web_build;\
	pnpm run sd
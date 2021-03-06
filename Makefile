.PHONY: all build build-app run run-app deps version config test logs stop

GO ?= go
COMPOSE ?= docker-compose
DOCKER ?= docker
ECHO ?= echo
GLIDE ?= glide
GOOSE ?= goose

BIN_DIR = $(GOPATH)/bin
BIN_NAME = $(BIN_DIR)/mybanana
REVISION_NAME = $(BIN_DIR)/REVISION
IMPORT_PATH = github.com/makarski/mybanana
CNT_NAME_APP = mybanana-api
CNT_NAME_DB = mybanana-db

all: build

deps:
	$(GLIDE) install

build:
	CNT_NAME_APP=$(CNT_NAME_APP) CNT_NAME_DB=$(CNT_NAME_DB) $(COMPOSE) build

test: deps
test:
	$(GO) vet $$($(GLIDE) novendor)
	$(GO) fmt $$($(GLIDE) novendor)
	$(GO) test $$($(GLIDE) novendor) -v

build-app: test version
	cd $(GOPATH)/src/$(IMPORT_PATH)
	BIN_DIR=$(BIN_DIR) $(GO) build -o $(BIN_NAME)

run:
	CNT_NAME_APP=$(CNT_NAME_APP) CNT_NAME_DB=$(CNT_NAME_DB) $(COMPOSE) up -d

logs:
	$(DOCKER) logs $(CNT_NAME_APP) --follow

stop:
	$(DOCKER) stop $(CNT_NAME_APP) $(CNT_NAME_DB)

remove:
	$(DOCKER) rm $(CNT_NAME_APP) $(CNT_NAME_DB)

run-app:
	BIN_DIR=$(BIN_DIR) $(BIN_NAME)

migrate-up:
	CNT_NAME_APP=$(CNT_NAME_APP) CNT_NAME_DB=$(CNT_NAME_DB) $(COMPOSE) exec $(CNT_NAME_APP) make dc-migrate-up

dc-migrate-up:
	cd migrations && $(GOOSE) mysql "${DB_DSN}" up && cd -

migrate-down:
	CNT_NAME_APP=$(CNT_NAME_APP) CNT_NAME_DB=$(CNT_NAME_DB) $(COMPOSE) exec $(CNT_NAME_APP) make dc-migrate-down

dc-migrate-down:
	cd migrations && $(GOOSE) mysql "${DB_DSN}" down && cd -

version:
	$(ECHO) `git log -n 1 --pretty=format:"%H"` > $(REVISION_NAME)

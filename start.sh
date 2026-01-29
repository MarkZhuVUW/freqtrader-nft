#!/bin/bash

docker compose down --remove-orphans
docker compose up -d --force-recreate
docker compose ps
docker compose logs -f
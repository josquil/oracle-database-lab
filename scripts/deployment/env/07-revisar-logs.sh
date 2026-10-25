#!/usr/bin/env bash
# scripts/deployment/env/07-revisar-logs.sh
source scripts/deployment/env/00-config.sh

echo "== Últimas 20 líneas del log de arranque =="
docker logs "$CONT_NAME" | tail -n 20

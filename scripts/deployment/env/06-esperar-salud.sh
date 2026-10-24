#!/usr/bin/env bash
# scripts/deployment/env/06-esperar-salud.sh
source scripts/deployment/env/00-config.sh

echo "Esperando a que $CONT_NAME este 'healthy' (puede tardar de 3 a 5 minutos)..."
# Bucle que revisa el estado cada 10 segundos
while [ "$(docker inspect -f '{{.State.Health.Status}}' "$CONT_NAME")" != "healthy" ]; do
  sleep 10
  echo -n "."
done
echo
echo "¡Base de datos lista!"
docker ps --filter "name=$CONT_NAME" --format "table {{.Names}}\t{{.Status}}"

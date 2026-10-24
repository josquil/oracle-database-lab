#!/usr/bin/env bash
source scripts/deployment/env/00-config.sh
set -a; source config/.env; set +a

echo "== Ejecutando V000 (Usuarios y Tablespaces) =="
docker exec -i "$CONT_NAME" sqlplus sys/"$ORACLE_PWD"@localhost:1521/FREE AS SYSDBA < database/migrations/V000__setup_entornos_negocio.sql

echo "== Ejecutando V001 (Tablas de negocio) =="
docker exec -i "$CONT_NAME" sqlplus sys/"$ORACLE_PWD"@localhost:1521/FREE AS SYSDBA < database/migrations/V001__create_esquemas_negocio.sql

WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON
COLUMN alerta FORMAT A24
COLUMN destino FORMAT A65

PROMPT ===== Alerta: FRA con ocupación igual o superior al 85 % =====

SELECT 'FRA_OCUPACION_ALTA' AS alerta,
       name AS destino,
       ROUND(space_used / 1048576, 1) AS usado_mb,
       ROUND(space_limit / 1048576, 1) AS limite_mb,
       ROUND(100 * space_used / NULLIF(space_limit, 0), 1) AS usado_pct,
       ROUND(space_reclaimable / 1048576, 1) AS recuperable_mb
FROM v$recovery_file_dest
WHERE space_limit > 0
  AND space_used >= 0.85 * space_limit;

EXIT

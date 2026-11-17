WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 200 PAGESIZE 200 FEEDBACK ON
COLUMN hora FORMAT A19
COLUMN member FORMAT A80

ALTER SESSION SET CONTAINER = CDB$ROOT;

PROMPT ===== A. Fecha y zona de referencia de la base =====
SELECT SYSDATE AS fecha_base,
       SYSTIMESTAMP AS instante_base,
       DBTIMEZONE,
       SESSIONTIMEZONE
FROM dual;

PROMPT ===== B. Grupos actuales: tamano por grupo, no por miembro =====
SELECT group#, thread#, bytes,
       ROUND(bytes / 1048576, 2) AS mib,
       members, sequence#, archived, status
FROM v$log
ORDER BY group#;

SELECT group#, member, status
FROM v$logfile
ORDER BY group#, member;

PROMPT ===== C. Cobertura del historial disponible =====
SELECT COUNT(*) AS registros,
       TO_CHAR(MIN(first_time), 'YYYY-MM-DD HH24:MI:SS') AS desde,
       TO_CHAR(MAX(first_time), 'YYYY-MM-DD HH24:MI:SS') AS hasta
FROM v$log_history;

PROMPT ===== D. Inicios de secuencia por fecha, hora e hilo =====
SELECT TO_CHAR(first_time, 'YYYY-MM-DD HH24') AS hora,
       thread#,
       COUNT(*) AS secuencias_iniciadas,
       MIN(sequence#) AS primera_secuencia,
       MAX(sequence#) AS ultima_secuencia
FROM v$log_history
GROUP BY TO_CHAR(first_time, 'YYYY-MM-DD HH24'), thread#
ORDER BY hora, thread#;

PROMPT ===== E. Detalle del dia de la carga documentada =====
SELECT thread#, sequence#,
       TO_CHAR(first_time, 'YYYY-MM-DD HH24:MI:SS') AS inicio,
       first_change#, next_change#
FROM v$log_history
WHERE first_time >= DATE '2026-11-16'
  AND first_time <  DATE '2026-11-17'
ORDER BY first_time, thread#, sequence#;

EXIT

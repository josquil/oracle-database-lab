WHENEVER SQLERROR EXIT FAILURE ROLLBACK
SET LINESIZE 180 PAGESIZE 100 FEEDBACK ON
SET SERVEROUTPUT ON

ALTER SESSION SET CONTAINER = CDB$ROOT;

PROMPT ===== Preparacion: checkpoint inicial =====
ALTER SYSTEM CHECKPOINT;

PROMPT ===== A. Antes de la carga =====
SELECT SYSTIMESTAMP AS instante,
       estimated_mttr,
       actual_redo_blks,
       recovery_estimated_ios
FROM v$instance_recovery;

ALTER SESSION SET CONTAINER = FREEPDB1;

PROMPT ===== UPDATE de hasta 20000 clientes y COMMIT =====
BEGIN
  UPDATE tiendasur.cliente
  SET telefono = telefono
  WHERE ROWNUM <= 20000;

  DBMS_OUTPUT.PUT_LINE('Filas actualizadas: ' || SQL%ROWCOUNT);
END;
/
COMMIT;

ALTER SESSION SET CONTAINER = CDB$ROOT;

PROMPT ===== B. Despues de la carga, sin checkpoint manual intermedio =====
SELECT SYSTIMESTAMP AS instante,
       estimated_mttr,
       actual_redo_blks,
       recovery_estimated_ios
FROM v$instance_recovery;

PROMPT ===== C. Checkpoint final y comprobacion =====
ALTER SYSTEM CHECKPOINT;

SELECT SYSTIMESTAMP AS instante,
       estimated_mttr,
       actual_redo_blks,
       recovery_estimated_ios
FROM v$instance_recovery;

EXIT

WHENEVER SQLERROR EXIT FAILURE ROLLBACK
SET LINESIZE 220 PAGESIZE 100 FEEDBACK ON
COLUMN index_name FORMAT A26
COLUMN column_name FORMAT A26
COLUMN visibility FORMAT A12

ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT ON FORMAT WRAPPED

PROMPT ===== A. Estadisticas de los indices comparados =====
SELECT index_name, blevel, leaf_blocks, num_rows,
       distinct_keys, clustering_factor, visibility, status
FROM dba_indexes
WHERE owner = 'TIENDASUR'
  AND index_name IN (
    'IX_PED_FECHA', 'IX_PED_CLI_FEC_CUB', 'IX_PED_FEC_IMP_Q11'
  )
ORDER BY index_name;

PROMPT ===== B. Espacio asignado =====
SELECT segment_name AS index_name,
       bytes AS bytes_asignados,
       ROUND(bytes / 1048576, 2) AS mib
FROM dba_segments
WHERE owner = 'TIENDASUR'
  AND segment_name IN (
    'IX_PED_FECHA', 'IX_PED_CLI_FEC_CUB', 'IX_PED_FEC_IMP_Q11'
  )
ORDER BY segment_name;

PROMPT ===== C. Columnas para comprobar prefijos y solapamiento =====
SELECT index_name, column_position, column_name
FROM dba_ind_columns
WHERE index_owner = 'TIENDASUR'
  AND table_name = 'PEDIDO'
ORDER BY index_name, column_position;

PROMPT ===== D. Retirar exclusivamente el candidato experimental =====
DROP INDEX tiendasur.ix_ped_fec_imp_q11;

PROMPT ===== E. Comprobar configuracion restaurada =====
SELECT COUNT(*) AS candidatos_restantes
FROM dba_indexes
WHERE owner = 'TIENDASUR'
  AND index_name = 'IX_PED_FEC_IMP_Q11';

SELECT index_name, visibility, status
FROM dba_indexes
WHERE owner = 'TIENDASUR'
  AND table_name = 'PEDIDO'
ORDER BY index_name;

EXIT

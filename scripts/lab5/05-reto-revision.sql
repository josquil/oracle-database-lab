WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 220 PAGESIZE 100 FEEDBACK ON VERIFY OFF TAB OFF

ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT ON FORMAT WRAPPED

DECLARE
  n NUMBER;
BEGIN
  SELECT COUNT(*) INTO n
  FROM dba_indexes
  WHERE owner = 'TIENDASUR'
    AND index_name IN ('IX_RF_TELEFONO', 'IX_RF_APE_UPPER');

  IF n > 0 THEN
    RAISE_APPLICATION_ERROR(
      -20051,
      'Existen indices IX_RF_ de otra ejecucion: revisar antes de continuar'
    );
  END IF;
END;
/

PROMPT ===== A. Consulta original, sin indices del reto =====
EXEC lab_tools.medir.consulta('RF original sin indices', q'[SELECT * FROM tiendasur.cliente WHERE SUBSTR(telefono, 1, 3) = '600' OR UPPER(apellidos) = 'GIL']');

PROMPT ===== B. Telefono reescrito, todavia sin indices del reto =====
EXEC lab_tools.medir.consulta('RF reescrita sin indices', q'[SELECT * FROM tiendasur.cliente WHERE telefono LIKE '600%' OR UPPER(apellidos) = 'GIL']');

PROMPT ===== Crear indices temporales exclusivos del reto =====
CREATE INDEX tiendasur.ix_rf_telefono
  ON tiendasur.cliente(telefono);

CREATE INDEX tiendasur.ix_rf_ape_upper
  ON tiendasur.cliente(UPPER(apellidos));

PROMPT ===== C. Reescrita con las dos ramas indexadas =====
EXEC lab_tools.medir.consulta('RF reescrita con indices', q'[SELECT * FROM tiendasur.cliente WHERE telefono LIKE '600%' OR UPPER(apellidos) = 'GIL']');

PROMPT ===== Verificar igualdad de los conjuntos de clientes =====
WITH original AS (
  SELECT id_cliente
  FROM tiendasur.cliente
  WHERE SUBSTR(telefono, 1, 3) = '600'
     OR UPPER(apellidos) = 'GIL'
),
reescrita AS (
  SELECT id_cliente
  FROM tiendasur.cliente
  WHERE telefono LIKE '600%'
     OR UPPER(apellidos) = 'GIL'
),
solo_original AS (
  SELECT id_cliente FROM original
  MINUS
  SELECT id_cliente FROM reescrita
),
solo_reescrita AS (
  SELECT id_cliente FROM reescrita
  MINUS
  SELECT id_cliente FROM original
)
SELECT 'SOLO_ORIGINAL' AS diferencia, COUNT(*) AS filas
FROM solo_original
UNION ALL
SELECT 'SOLO_REESCRITA', COUNT(*)
FROM solo_reescrita;

PROMPT ===== Limpieza: retirar solo los indices de este reto =====
DROP INDEX tiendasur.ix_rf_telefono;
DROP INDEX tiendasur.ix_rf_ape_upper;

SELECT COUNT(*) AS indices_temporales_restantes
FROM dba_indexes
WHERE owner = 'TIENDASUR'
  AND index_name IN ('IX_RF_TELEFONO', 'IX_RF_APE_UPPER');

SELECT COUNT(*) AS indices_tiendasur
FROM dba_indexes
WHERE owner = 'TIENDASUR';

EXIT

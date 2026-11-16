# Recuperación de un datafile de aplicación en una PDB

## Alcance y síntomas

Para un datafile de aplicación, con backup RMAN y redo disponible.
No aplicar a SYSTEM ni al undo de CDB$ROOT.

Síntomas: ORA-01116, ORA-01110 y ORA-27041.
El error del sistema operativo concreta la causa.
ORA-63999 puede acompañar al cierre de la PDB por fallo de medios.

Caso comprobado: FREEPDB1, datafile 16,
`/opt/oracle/oradata/FREE/FREEPDB1/academia01.dbf`.

## Comprobaciones previas

Avisar al responsable DBA y al responsable del servicio afectado.
Registrar la hora del fallo y conservar el alert log.
No borrar otros archivos ni ejecutar RESETLOGS por iniciativa propia.

Desde SQL*Plus como SYSDBA, en CDB$ROOT:

```sql
SELECT log_mode FROM v$database;
SELECT name, open_mode FROM v$pdbs;
SELECT file#, con_id, name FROM v$datafile WHERE file# = 16;
```

Desde RMAN conectado a la raíz:

```rman
LIST BACKUP OF DATAFILE 16;
```

Confirmar ARCHIVELOG, backup utilizable, redo necesario y espacio
en el destino. El número 16 es el del laboratorio: identificar
siempre el archivo real antes de ejecutar cambios.
Si no hay copia o redo suficiente, detenerse y escalar.

## Reparación

Si FREEPDB1 sigue READ WRITE, aislar el archivo desde SQL*Plus:

```sql
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER DATABASE DATAFILE 16 OFFLINE;
```

Si Oracle está cerrando la PDB, esperar a que figure MOUNTED.
No lanzar RESTORE mientras el cierre está en curso.
Si ya está MOUNTED, continuar con la reparación en ese estado.

Desde RMAN conectado a CDB$ROOT:

```rman
RESTORE DATAFILE 16;
RECOVER DATAFILE 16;
```

Solo si ambos terminan correctamente, desde SQL*Plus:

```sql
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER DATABASE DATAFILE 16 ONLINE;
ALTER SESSION SET CONTAINER = CDB$ROOT;
```

Si FREEPDB1 permanece MOUNTED:

```sql
ALTER PLUGGABLE DATABASE FREEPDB1 OPEN;
```

## Verificación y cierre

```sql
SELECT name, open_mode FROM v$pdbs;
ALTER SESSION SET CONTAINER = FREEPDB1;
SELECT COUNT(*) FROM admin_academia.aca_estudiantes;
SELECT estudiante_id, estado
FROM admin_academia.aca_estudiantes
WHERE estudiante_id = 104;
```

Exigir READ WRITE y comprobar los datos esperados con el responsable
del servicio. En el simulacro: 20000 estudiantes y fila 104 EGRESADO,
cambio confirmado después del backup. Después se devuelve a ACTIVO
solo para dejar el laboratorio repetible.

Registrar tiempo hasta recuperar el servicio, pérdida de datos
observada y causa. Revisar errores nuevos y notificar la recuperación.
Si falla RECOVER o la apertura, conservar la salida y escalar;
no repetir el simulacro ni forzar la apertura.
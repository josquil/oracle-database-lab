# Lab 5 — Oracle DBA Workflow II


## 1. Preguntas de comprobación


### 1. Compara el paso 6 de tu copia lab4-final con el de la copia lab3-final. ¿Qué demuestra la diferencia?

En la copia del Lab 3 había cinco datafiles de negocio fuera del volumen.
En la copia lab4-final, el paso 6 indicó:
«ninguno: el volumen contiene toda la base de datos».

Esto demuestra que la reubicación realizada en el Lab 4 dejó los
datafiles de negocio dentro del volumen respaldado.

Evidencia:
- evidencia/script/20261115T194658Z_00-backup-lab4.script.log

### 2. Calcula el factor de bloqueo (bfr) de CLIENTE y PEDIDO con sus estadísticas. ¿Por qué en PEDIDO cabe casi el triple de filas por bloque?

He calculado el bfr como NUM_ROWS / BLOCKS:

| Tabla | Filas | Bloques | Bytes medios por fila | BFR calculado |
|---|---:|---:|---:|---:|
| CLIENTE | 100000 | 1517 | 102 | 65,92 |
| PEDIDO | 1000000 | 5320 | 32 | 187,97 |

En PEDIDO caben aproximadamente 2,85 veces más filas por bloque.
Sus filas son más cortas: 32 bytes de media frente a los 102 de CLIENTE.
La proporción no es exacta porque también intervienen las cabeceras,
el espacio reservado y la ocupación real de los bloques.

Evidencia:
- evidencia/script/20261116T093923Z_01-perfil-tiendasur.script.log

#### Reto de la Parte B — Comprobación directa de las filas por bloque

Agrupé las filas de PEDIDO por el bloque obtenido mediante
DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID, 'BIGFILE').

| Medida | Resultado |
|---|---:|
| Filas totales | 1000000 |
| Bloques con filas | 5220 |
| Mínimo de filas por bloque con filas | 2 |
| Media de filas por bloque con filas | 191,57 |
| Máximo de filas por bloque | 200 |
| Bloques según las estadísticas | 5320 |
| NUM_ROWS / BLOCKS | 187,97 |

La media directa es mayor porque divide entre los 5220 bloques que
contienen filas, mientras que el cálculo estadístico divide entre 5320.
Por tanto, no utilizan el mismo conjunto de bloques como denominador.

No todos los bloques contienen las mismas filas: la longitud variable
de las filas y los bloques parcialmente llenos durante la carga pueden
producir distintas ocupaciones. El recuento muestra esa variación,
pero no demuestra la causa concreta de cada bloque.

La consulta terminó con código de salida 0.

Evidencia:
- docs/bitacora/lab5/evidencia/script/20261116T095128Z_01-bfr-pedido.script.log

### 3. ¿Por qué el banco de medida ejecuta cada sentencia dos veces y mide solo la segunda?

La primera ejecución realiza el análisis y calienta la caché.
La segunda mide la consulta en caliente, reduciendo la influencia
del trabajo inicial y permitiendo comparar alternativas en condiciones
más homogéneas.

Mi prueba prueba_pk devolvió una fila, con cuatro lecturas lógicas,
cero lecturas físicas y un tiempo de 1,1 ms. El plan utilizó
INDEX UNIQUE SCAN sobre PK_PEDIDO y TABLE ACCESS BY INDEX ROWID
sobre PEDIDO.

Evidencia:
- evidencia/script/20261116T093925Z_01-herramienta-medir.script.log

### 4. Con tu evidencia 02: altura, número de hojas y factor de ramificación real de IX_PED_CLIENTE. ¿Qué altura tendría con mil millones de filas?

IX_PED_CLIENTE tiene altura 3, 2216 bloques de hoja y 6 bloques de rama,
con un millón de entradas y ninguna entrada borrada.

El factor de ramificación medio es:
(2216 + 6 - 1) / 6 = 370,17, aproximadamente 370 hijos por rama.

El máximo estimado por el script es 543. Usando ese máximo y sus
supuestos de capacidad y ocupación, la proyección para mil millones
de filas es de 2208969 hojas y altura 4. Buscar una fila y recuperar
una columna de la tabla requeriría aproximadamente 5 lecturas:
4 del índice y 1 de la tabla.

En la prueba real de PK_PEDIDO, la búsqueda de ID_PEDIDO e IMPORTE
necesitó 4 lecturas lógicas. Al pedir solamente ID_PEDIDO, presente
en el índice, necesitó 3 y evitó el acceso a la tabla.

### 5. En el volcado de la hoja de PK_CLIENTE, localiza una entrada y descompón el ROWID que guarda en bloque y fila. ¿Por qué no aparece el número de archivo?

La primera entrada de la hoja contiene:

    row#0: data:(6): 00 00 03 1b 00 00
    col 0; len 2: c1 02

La clave c1 02 corresponde a ID_CLIENTE = 1.
Los seis bytes de data se descomponen en:
- 00 00 03 1b: bloque 0x31B, equivalente a 795.
- 00 00: ranura 0 dentro del bloque.

La consulta de comprobación confirmó bloque 795 y ranura 0 para
el cliente 1.

No aparece el número de archivo porque es un tablespace BIGFILE:
el ROWID corto de esta entrada utiliza cuatro bytes para el bloque
y dos para la ranura; no necesita distinguir varios datafiles
dentro del tablespace.

La raíz de PK_CLIENTE tiene 186 entradas separadoras más el hijo
izquierdo kdxbrlmc: en total, 187 hijos, correspondientes a sus
187 hojas.

#### 6. Elige tres pruebas de la Parte D y explica, con las lecturas lógicas medidas, por qué un tipo de índice gana al otro.

He elegido tres comparaciones de mi evidencia 03:

| Prueba | Alternativa inicial | Alternativa final | Lecturas lógicas |
|---|---|---|---|
| Q13: búsqueda por DNI | Sin índice | Índice único UX_CLI_DNI | 1486 → 3 |
| Q7: historial del cliente | IX_PED_CLIENTE | Compuesto / cubriente | 15 → 7 → 3 |
| Q14: combinación de filtros | Sin bitmaps | Cuatro índices bitmap | 4073 → 528 |

En Q13, el plan pasó de TABLE ACCESS FULL a INDEX UNIQUE SCAN
con acceso a la tabla por ROWID. Además de acelerar la búsqueda,
el índice rechazó el DNI duplicado mediante ORA-00001.

En Q7, el índice inicial necesitaba acceder a la tabla y ordenar
las filas. El compuesto (id_cliente, fecha_pedido) eliminó el SORT
y redujo las lecturas de 15 a 7. El cubriente incluyó todas las
columnas solicitadas y evitó también acceder a la tabla: 3 lecturas.
Su coste en espacio fue de 40 MB, frente a los 18 MB de IX_PED_CLIENTE.

En Q14, el plan combinó los cuatro bitmaps mediante BITMAP AND
antes de acceder a la tabla. Las lecturas bajaron de 4073 a 528.
Esta medida corresponde al experimento de consulta; no demuestra
que sea la mejor opción para una carga con escrituras concurrentes.

El script terminó con código 0 y dejó 7 índices en TiendaSur
después de eliminar los objetos experimentales.

### 7. ¿Por qué IX_PED_FECHA tiene un clustering factor cercano al número de bloques e IX_PED_CLIENTE cercano al de filas? ¿Lo arreglaría un REBUILD?

PEDIDO tiene 1000000 filas y 5320 bloques según las estadísticas.
IX_PED_FECHA tiene CF = 5220, mientras que IX_PED_CLIENTE tiene
CF = 999041. El cálculo directo confirmó ambos valores.

La carga dejó las filas físicamente ordenadas por fecha, por lo que
recorrer IX_PED_FECHA permite recuperar filas consecutivas del índice
en pocos bloques de tabla. Los clientes están repartidos: al recorrer
IX_PED_CLIENTE se cambia de bloque de tabla casi en cada entrada.

El CF cuenta cambios de bloque durante el recorrido ordenado,
no solamente bloques únicos: un mismo bloque puede volver a visitarse.

Un REBUILD del índice no reordena las filas de la tabla y, por tanto,
no corrige ese mal agrupamiento. Reordenar la tabla podría favorecer
el acceso por cliente, pero perjudicar el orden por fecha.

### 8. Según tu curva de la Parte E, ¿a partir de qué porcentaje deja de compensar cada índice? Compáralo con la fórmula de la Unidad 3.

El recorrido completo costó 5232 lecturas lógicas en todas las pruebas.

| Comparación | Último punto favorable al índice | Primer punto desfavorable |
|---|---|---|
| CF malo | 0,5 %: 4875 lecturas | 1 %: 9920 lecturas |
| CF bueno | 50 %: 3938 lecturas | 100 %: 7875 lecturas |

Por tanto, el cruce medido queda entre el 0,5 % y el 1 % para
el índice con CF malo, y entre el 50 % y el 100 % para el de CF bueno.
No he medido el porcentaje exacto dentro de esos intervalos.

Con bfr = 188 y suponiendo igual coste por lectura, la fórmula
predice 1/188 = 0,53 %, compatible con el intervalo del CF malo.
Si se supone c_sec/c_aleat = 1/5, la predicción baja al 0,11 %.
Esta segunda cifra es un supuesto de costes, no una latencia medida
en esta prueba.

El optimizador eligió el índice con CF malo hasta el 0,1 % y ya
eligió recorrido completo al 0,2 %. Su cambio queda entre esos
dos puntos y ocurre antes del cruce de lecturas lógicas observado.
El coste estimado por el optimizador no equivale simplemente al
número de lecturas lógicas de esta ejecución en caliente.

### 9. Explica por qué Q4b (Gonz%) usa el índice y aun así lee más bloques que un recorrido completo.

Q4b devolvió 2056 filas y realizó 2024 lecturas lógicas mediante
INDEX RANGE SCAN sobre IX_CLI_APELLIDOS y acceso a CLIENTE por ROWID.
El recorrido completo de Q4a realizó 1523 lecturas lógicas.

El prefijo Gonz% permite localizar un rango en el índice, pero después
hay que recuperar las columnas solicitadas en los bloques de la tabla.
Si esas filas están dispersas, esos accesos pueden acumular más lecturas
que un recorrido completo.

Usar un índice no garantiza menos lecturas. En esta ejecución Q4b
tardó menos, pero ese tiempo aislado no demuestra que su acceso sea
siempre mejor.

Además, Q4a y Q4b no son consultas equivalentes: %ez devolvió
18902 filas y Gonz% devolvió 2056. La comparación muestra el coste
observado de ambos planes, no una prueba de la misma consulta
ejecutada con y sin índice.

### 10. Con tu evidencia 06: bloques modificados por INSERT con 4, 9 y 5 índices. ¿Qué índices de la propuesta del compañero rechazaste y con qué dato?

Se midieron 2000 operaciones de una fila por prueba, deshechas con
ROLLBACK. Los resultados por fila fueron:

| Escenario | Índices en PEDIDO | INSERT | UPDATE estado | UPDATE importe | DELETE |
|---|---:|---:|---:|---:|---:|
| Heredado | 4 | 10,2 | 2,0 | 6,0 | 10,1 |
| Propuesta del compañero | 9 | 20,4 | 6,0 | 6,0 | 20,1 |
| Diseño V005 | 5 | 12,2 | 8,1 | 6,0 | 10,1 |

Las cifras representan cambios de bloque por fila, no bloques distintos
ni escrituras físicas a disco.

El INSERT concuerda aproximadamente con la regla
2 cambios de bloque de tabla y undo + 2 por cada índice mantenido.
Con 4 índices se midieron 10,2; con 9, 20,4; con 5, 12,2.
La propuesta duplicó el coste del INSERT y elevó el redo de
1325 a 2678 bytes por fila. V005 quedó en 1685 bytes por fila.

De los cinco índices propuestos:

- IX_PED_CANAL se rechazó: no se utilizó en la carga observada y tiene
  solo 3 claves distintas. El promedio de filas por valor es 33,333 %.
- IX_PED_FEC_CLI se rechazó: no se utilizó en la carga observada.
  Las consultas por fecha ya usaron IX_PED_FECHA; añadir ID_CLIENTE
  como segunda columna no aportó una mejora demostrada en esta carga.
- IX_PED_ESTADO no se conservó como índice completo. Sí fue utilizado
  por Q12: devolvió 20000 pendientes con 147 lecturas, por lo que no
  puede calificarse de inútil. Se sustituyó por el diseño parcial
  IX_PED_PENDIENTES sobre FECHA_PENDIENTE, destinado a las filas en P.
- IX_PED_CLI_FEC sí demostró utilidad: Q7 obtuvo 4 filas con 7 lecturas.
  V005 lo sustituyó por IX_PED_CLI_FEC_CUB para cubrir la consulta
  incluyendo sus columnas de salida.
- IX_PED_CP se conservó: Q3 devolvió 102 filas con 106 lecturas.
  Sus 11000 claves distintas dan aproximadamente un 0,009 % de
  filas por valor medio.

Además, se retiraron dos índices heredados:

- IX_PED_CLIENTE: era prefijo izquierdo del compuesto. V005 creó antes
  IX_PED_CLI_FEC_CUB, que empieza por ID_CLIENTE, manteniendo ese
  acceso para la clave ajena.
- IX_PED_IMPORTE: no tuvo uso en la carga observada. Se hizo INVISIBLE
  y Q2 mantuvo el mismo plan con IX_PED_FECHA y 335 lecturas.

La decisión no se basó solo en el número de claves distintas:
también se comprobaron uso real, coste de escritura, redundancia
y posibilidad de retirada reversible. La ventana de observación
del laboratorio es corta; en producción habría que incluir los
procesos periódicos antes de concluir que un índice no se necesita.

### 11. Distingue, con tus gráficos de la Parte H, un índice con divisiones 50/50, uno con divisiones 90/10 y uno con patrón cola.

Las pruebas insertaron 200000 filas en cada tabla.

| Índice | Divisiones totales | Divisiones 90/10 | Hojas | Ocupación viva |
|---|---:|---:|---:|---:|
| IX_AZAR | 595 | 0 | 596 | 75,4 % |
| IX_CRECIENTE | 398 | 398 | 399 | 99,9 % |
| IX_INVERTIDA (REVERSE) | 511 | 0 | 512 | 77,9 % |

En IX_AZAR, las claves llegan a diferentes zonas del árbol.
Cuando se llena una hoja intermedia, se divide repartiendo sus
entradas aproximadamente por la mitad. Después las hojas se vuelven
a llenar. El histograma muestra ocupaciones variadas, entre el 40 %
y el 99 %, sin hojas vacías. El 75,4 % de ocupación no demuestra
por sí solo una degradación que requiera mantenimiento.

En IX_CRECIENTE, las claves nuevas llegan al extremo derecho.
Las 398 divisiones fueron 90/10: se deja llena la hoja anterior
y se continúa en una nueva. El mapa aparece lleno de izquierda
a derecha y la ocupación viva media es del 99,9 %.

IX_INVERTIDA reparte las claves secuenciales al invertir sus bytes.
No registró divisiones 90/10 y tuvo una ocupación del 77,9 %.
El coste se observó en la consulta por rango: el índice normal
permitió INDEX RANGE SCAN con 4 lecturas, mientras que con REVERSE
se eligió TABLE ACCESS FULL y se realizaron 878 lecturas.

El patrón cola se distingue por su asimetría, no solo por una
ocupación media baja. En IX_COLA, el mapa tenía la izquierda vacía
y la derecha llena: se insertan claves crecientes y se borran
las más antiguas.

Tras 200000 altas, 150000 bajas y otras 50000 altas quedaron
100000 mensajes vivos, con identificadores entre 150001 y 250000.
El índice tenía 425 hojas, 224 sin entradas vivas, 70497 entradas
borradas aún contabilizadas y una ocupación viva del 47,1 %.

Obtener el primer mensaje requirió 226 lecturas, frente a las 2
del índice sano: había que atravesar hojas sin entradas vivas
antes de encontrar el mensaje más antiguo.


### 12. ¿Qué remedio elegirías para el patrón cola en producción, en horario de servicio, y por qué?

Elegiría primero COALESCE para resolver el síntoma medido:
fusiona bloques del índice cuando es posible y libera bloques
para su reutilización dentro del propio segmento.

| Estado | Hojas | Entradas borradas | MB del segmento | Lecturas del siguiente mensaje |
|---|---:|---:|---:|---:|
| Cola degradada | 425 | 70497 | 4,00 | 226 |
| Tras COALESCE | 201 | 0 | 4,00 | 2 |
| Tras SHRINK SPACE | 201 | 0 | 1,69 | 2 |
| Tras REBUILD ONLINE | 223 | 0 | 2,00 | 2 |

COALESCE resolvió el problema de lectura y mantuvo el segmento
en 4 MB: recuperó espacio reutilizable dentro del índice, pero
no lo devolvió al tablespace.

Si además fuera necesario devolver espacio al tablespace,
consideraría SHRINK SPACE, comprobando sus requisitos y el
impacto operativo. En esta ejecución, después de COALESCE,
redujo el segmento de 4 a 1,69 MB y mantuvo las 2 lecturas.

No elegiría REBUILD ONLINE solo para este síntoma: después de
las operaciones anteriores no mejoró las lecturas, que siguieron
en 2, y dejó un segmento de 2 MB con 223 hojas.

Las operaciones se probaron consecutivamente sobre el mismo
índice; no son tres ensayos independientes partiendo de la misma
cola degradada. Por tanto, la tabla demuestra la evolución
observada, no una comparación aislada del coste de cada remedio.

En producción, una operación en línea no debe interpretarse como
ausencia absoluta de bloqueos, esperas o consumo de recursos.
Se debe comprobar su comportamiento bajo la carga real.

Si el patrón reaparece de forma continua, revisaría el diseño:
por ejemplo, particionar por fecha y retirar particiones completas
cuando la política de retención y los accesos lo permitan.

### 13. Con tu evidencia 08: ¿qué valores compara Oracle al abrir para decidir si hace falta recuperación?

Oracle compara la información de checkpoint registrada en el
control file para cada datafile con la de la cabecera del propio
archivo. En la evidencia se consultan mediante:

- V$DATAFILE.CHECKPOINT_CHANGE#: checkpoint registrado en el control file.
- V$DATAFILE_HEADER.CHECKPOINT_CHANGE#: checkpoint de la cabecera.

Antes del checkpoint, los archivos mostrados de CDB$ROOT y
academia01.dbf tenían el valor 6423505 en ambos sitios.

Después de modificar datos, confirmar y ejecutar
ALTER SYSTEM CHECKPOINT, esos archivos mostraron 6428985
tanto en el control file como en sus cabeceras.

Los archivos de PDB$SEED (CON_ID = 2) mantuvieron 2098101
en ambos sitios. Su checkpoint no avanzó porque la PDB está
en solo lectura; ese valor antiguo no indica por sí solo un fallo.

La comparación se hace entre la información de cada archivo:
no se exige que PDB$SEED tenga el mismo checkpoint que los
archivos abiertos en lectura y escritura.

DBWn escribe los bloques de datos y CKPT registra la información
del checkpoint en el control file y en las cabeceras.
Si un archivo está atrasado respecto al estado requerido,
Oracle necesita aplicar redo para recuperarlo.

La igualdad observada demuestra la sincronización de los
checkpoints consultados, pero no basta por sí sola para afirmar
que nunca habrá recuperación: también importa si el cierre
anterior fue limpio o hubo una caída de instancia.

### 14. ¿Qué protege la multiplexación del control file en el mismo volumen y qué no? ¿Cómo se haría en producción?

Protege frente a la pérdida o daño de una copia individual, siempre
que quede otra copia sana. No protege frente a la pérdida completa
del volumen que contiene todas las copias, ni sustituye a un backup.

Mi configuración terminó con control01.ctl, control02.ctl y
control03.ctl bajo /opt/oracle/oradata/FREE/.

En el simulacro B se eliminó control03.ctl con la base parada.
El arranque no pudo completar MOUNT y devolvió ORA-00205.
Se repuso el archivo desde una copia sana y se completaron
MOUNT y OPEN, sin restaurar los datafiles.

En producción, las copias se distribuirían entre almacenamientos
con dominios de fallo diferentes y se complementarían con backups
del control file, incluido el autobackup de RMAN.


### 15. Explica los estados CURRENT, ACTIVE e INACTIVE con tu evidencia 10 y por qué Oracle rechaza los tres borrados del paso 4.

CURRENT identifica el grupo en el que LGWR está escribiendo.
ACTIVE identifica un grupo que ya no es el actual, pero aún puede
ser necesario para recuperación de instancia.
INACTIVE indica que ya no se necesita para esa recuperación;
en ARCHIVELOG también debe estar archivado antes de reutilizarse.

Tras el cambio adicional de mi prueba:

| Grupo | Secuencia | Miembros | Archivado | Estado |
|---|---:|---:|---|---|
| 1 | 19 | 2 | NO | CURRENT |
| 2 | 17 | 2 | YES | INACTIVE |
| 3 | 18 | 2 | NO | ACTIVE |

Los rechazos realmente observados fueron:

- ORA-01623 al intentar borrar el grupo CURRENT.
- ORA-01609 al intentar borrar un miembro del grupo CURRENT.
- ORA-00350 al intentar borrar otro grupo porque necesitaba archivarse.

No obtuve ORA-01567: mi entorno tenía tres grupos y Oracle rechazó
la tercera operación por otro requisito previo. Por tanto, no
presento esta ejecución como una demostración del límite mínimo
de dos grupos.


### 16. Describe la cadena de causas del escenario de la FRA llena, desde ORA-19815 hasta que la base deja de aceptar cambios.

ORA-19815 advierte de presión sobre el espacio disponible de la FRA.
En mi experimento el límite se redujo a 2 MB cuando ya había
aproximadamente 9 MB usados: el aviso indicó 100 % y cero espacio
restante.

Al solicitar el archivado de la secuencia 21 aparecieron
ORA-16038 y ORA-19809: ARCn no pudo crear el archivado porque
se había superado el límite de la FRA.

En ARCHIVELOG, un grupo pendiente de archivar no puede reutilizarse.
Si continúan generándose cambios hasta que no queda un grupo
reutilizable, el cambio de log puede quedar esperando con
log file switch (archiving needed), y las operaciones que
necesitan generar redo quedan bloqueadas.

Mi salida demostró el fallo de archivado, no que todas las sesiones
llegaran a bloquearse ni un ORA-00257.

El script restableció el límite a 4096 MB. Las secuencias 21 y 22
aparecieron archivadas y la FRA terminó con 10,9 MB usados.
Se resolvió un límite lógico insuficiente, no un disco físico lleno.


### 17. Explica, con los pasos 1 a 4 de tu evidencia 12, la frase «lectores no bloquean a escritores».

La sesión A modificó la fila 101 a EGRESADO sin confirmar.
Una consulta normal de B obtuvo ACTIVO, la versión confirmada
anterior, reconstruida mediante undo. No necesitó esperar a que
A terminara ni leyó su modificación sin confirmar.

La transacción de A, SID 52, consumía un bloque y un registro
de undo. Se observaron un bloqueo TM en modo 3 y un TX en modo 6.

Cuando B ejecutó SELECT ... FOR UPDATE WAIT 3 sobre la misma fila,
recibió ORA-00054 y ORA-40097. Esa sentencia ya no era solo una
lectura consistente: solicitaba un bloqueo incompatible con
la transacción de A.

La frase se aplica aquí a las consultas normales; no significa
que SELECT FOR UPDATE nunca bloquee ni espere.


### 18. ¿Por qué un DELETE genera más undo que un INSERT? ¿Por qué el ROLLBACK también genera redo?

Para deshacer un INSERT basta la información necesaria para retirar
las filas y entradas de índice creadas. Para deshacer un DELETE
hay que poder reconstruir las filas eliminadas y sus entradas
de índice.

En mi prueba de 10000 pedidos:

| Operación | Bloques de undo | KB en bloques de undo | Redo total KB | Redo del ROLLBACK KB |
|---|---:|---:|---:|---:|
| INSERT | 142 | 1136 | 4795 | 355 |
| UPDATE | 71 | 568 | 1258 | 751 |
| DELETE | 427 | 3416 | 6627 | 4701 |

El DELETE fue el más costoso de estas operaciones concretas.
No significa que cualquier DELETE sea siempre más caro que
cualquier UPDATE, con independencia de sus columnas e índices.

ROLLBACK también modifica bloques al aplicar los cambios inversos.
Esas modificaciones generan redo. Deshacer no borra el redo
que ya se había generado.

Además, el redo protege los cambios en los propios bloques de undo:
en recuperación deben poder reconstruirse antes de deshacer
las transacciones no confirmadas.


### 19. Con tu evidencia 13: ¿dónde está la garantía de durabilidad justo después del COMMIT? ¿Y después del checkpoint?

En esta prueba, justo después del COMMIT la garantía estaba en
el redo persistido por LGWR en los redo logs online, no en que
todos los bloques modificados estuvieran ya en los datafiles.

Durante el intervalo UPDATE + COMMIT se registraron:
7035 KB de redo, 8 escrituras de LGWR, 1 commit y 0 bloques
escritos desde caché. Todavía había 231 buffers sucios de la tabla.

Después del checkpoint, los buffers sucios de la tabla bajaron
a 0 y se registraron 557 bloques escritos desde caché.
Esos 557 corresponden a toda la instancia, no únicamente
a los 231 buffers de la tabla.

El checkpoint hace avanzar el estado persistido de los datafiles
y reduce el trabajo pendiente de recuperación; no es lo que
convierte por primera vez el COMMIT en durable.

El protocolo write-ahead logging exige persistir el redo asociado
antes de escribir el bloque modificado en su datafile.


### 20. Simulacro A: explica roll forward y roll back con las filas 102 y 103 y las líneas del alert log.

Antes de la caída, la fila 102 se cambió a EGRESADO y se confirmó.
La fila 103 se cambió a INACTIVO sin confirmar.

Tras SHUTDOWN ABORT y el siguiente arranque, el alert log mostró
Beginning crash recovery, lectura de 1920 KB de redo,
326 bloques que necesitaban recuperación, aplicación de 1,13 MB
de redo y Completed crash recovery.

El roll forward rehace los cambios necesarios desde el checkpoint,
incluidos los que permiten reconstruir el undo.
El roll back utiliza el undo para deshacer lo no confirmado.

La consulta posterior mostró:
- 102 = EGRESADO: sobrevivió la transacción confirmada.
- 103 = ACTIVO: se deshizo la modificación no confirmada.

La instancia abrió con la secuencia de log 24.
Después se devolvió la fila 102 a ACTIVO.


### 21. Simulacros C y D: tu RTO y tu RPO en cada uno. ¿Por qué son tan distintos?

En C, el script midió 129 segundos en el tramo de restauración
de la copia completa. La ventana entre la copia y el fallo fue
de 4 segundos: expresa los cambios que podrían quedar fuera
al volver a la copia, no un recuento de transacciones perdidas.

En D, se midieron 18 segundos desde archivo fuera de línea
hasta en línea, y 19 segundos desde el fallo.
El RPO observado para la fila de control fue 0: la fila 104
conservó EGRESADO, confirmado después del backup.

C restauró toda la base y volvió al estado del respaldo.
D restauró el archivo 16 y aplicó redo para incorporar cambios
posteriores. En D hubo que reabrir FREEPDB1, que estaba MOUNTED.

La comparación temporal no es idéntica:
C informa del tramo de restauración, mientras D ofrece también
el tiempo desde el fallo. Aun con esa limitación, la prueba muestra
la diferencia entre restaurar toda la base y reparar un archivo.


### 22. Clasifica cada error ORA- del bloque 5 de tu runbook: incidente real, efecto del laboratorio o ruido conocido.

| Error observado | Clasificación e interpretación |
|---|---|
| ORA-00202 sobre control03.ctl, 20:22 | Efecto del simulacro B: identifica la copia eliminada deliberadamente y después repuesta. |
| ORA-205 durante ALTER DATABASE MOUNT, 20:22 | Representación de ORA-00205 en ese mensaje; efecto del fallo de montaje provocado en B. |
| ORA-01110 sobre el archivo 16, 20:57 | Efecto del simulacro D: identifica academia01.dbf, eliminado deliberadamente. |
| ORA-63999, 20:57 | Efecto del fallo de medios de D y del cierre de FREEPDB1. |
| ORA-01113 sobre el archivo 22, 20:58 | Registro histórico durante la reapertura en el contexto de D. La PDB acabó READ WRITE y P.2 dio TODO OK; no demuestra por sí solo un incidente nuevo pendiente. |
| ORA-00800 [Set Priority Failed], LGWR/VKTM | Aviso de configuración del entorno, no provocado por el borrado de archivos. Requiere revisar trazas para precisar la causa; no se declara resuelto ni inocuo solo porque el chequeo termine con código 0. |

El alert log conserva sucesos anteriores. La clasificación debe
contrastarse con el estado actual y las pruebas funcionales,
no interpretar cada mensaje histórico como un fallo activo.

## 2. Retos y puntos de control

#### Simulacro A — Caída de instancia

La instancia se detuvo mediante SHUTDOWN ABORT y recuperó
automáticamente al arrancar.

Tras el arranque:
- La fila 102 conservó EGRESADO, cambio confirmado antes de la caída.
- La fila 103 mostró ACTIVO: el cambio no confirmado se deshizo.

El alert log registró Beginning crash recovery, lectura de
1920 KB de redo, 326 bloques de datos que necesitaban recuperación,
aplicación de 1,13 MB de redo y Completed crash recovery.
La instancia abrió con la secuencia de log 24.

El script ejecutó después la reparación de la fila 102 a ACTIVO.
Código de salida: 0.

No se observó pérdida del cambio confirmado de control:
RPO observado = 0 para la transacción comprobada.

Tiempo de recuperación: no medido con la evidencia revisada.
La limitación y la mejora de instrumentación se recogen en la tabla
y retrospectiva conjunta de los simulacros.

### Parte B — Filas por bloque de PEDIDO

Enunciado: calcular con DBMS_ROWID.ROWID_BLOCK_NUMBER cuántas filas
hay en los bloques de PEDIDO (mínimo, media y máximo), compararlo
con NUM_ROWS / BLOCKS y explicar por qué los bloques no contienen
todos el mismo número de filas.

Resultado:
- Filas totales: 1000000.
- Bloques con filas: 5220.
- Mínimo: 2 filas por bloque.
- Media: 191,57 filas por bloque con filas.
- Máximo: 200 filas por bloque.
- Estadísticas: NUM_ROWS = 1000000 y BLOCKS = 5320.
- BFR estadístico: 187,97.
- Código de salida: 0.

Interpretación:
La media directa utiliza solamente los 5220 bloques que contienen
filas. El cálculo estadístico utiliza 5320 bloques, por lo que su
denominador es mayor y el resultado es menor. No son exactamente
la misma medida.

La ocupación no es uniforme: influyen la longitud variable de las
filas y los bloques que quedan parcialmente llenos durante la carga.
El resultado observado es compatible con ello, aunque el recuento
por sí solo no identifica la causa concreta de cada bloque.

Evidencia: lab5/evidencia/script/20261116T095128Z_01-bfr-pedido.script.log

#### Simulacro B — Pérdida de un control file

Se realizó una parada limpia y se eliminó:
`/opt/oracle/oradata/FREE/control03.ctl`.

El siguiente STARTUP inició la instancia, pero no pudo montar
la base. Mostró ORA-00205 y V$INSTANCE.STATUS = STARTED:
la instancia había alcanzado NOMOUNT, no MOUNT.

El alert log identificó el archivo ausente mediante ORA-00202
y mostró ORA-27037, al no poder obtener su estado en el sistema
operativo.

Con la base sin montar se repuso control03.ctl copiando otra
copia sana, conservada tras la misma parada limpia.
Después se completaron ALTER DATABASE MOUNT y ALTER DATABASE OPEN.

V$CONTROLFILE volvió a mostrar las tres copias.
La comprobación final indicó:
docker=healthy y cdb/pdb=READWRITE/READWRITE.
Código de salida: 0.

No fue necesario restaurar datafiles ni volver a una copia
histórica de la base. La reparación utilizó la multiplexación.

No se esperaba pérdida de transacciones confirmadas, al conservar
copias actuales del control file y no retroceder los datos.
Esta salida no incluye una comprobación específica de filas
para medir de forma independiente esa ausencia de pérdida.

Tiempo de recuperación: no medido con la evidencia revisada.
La limitación y la mejora de instrumentación se recogen en la tabla
y retrospectiva conjunta de los simulacros.


### Parte C — Interpretación de los gráficos iniciales

| Índice | Hojas | Ocupación viva media | Entradas borradas | Hojas vacías |
|---|---:|---:|---:|---:|
| PK_PEDIDO | 1875 | 99,9 % | 0 | 0 |
| IX_PED_CLIENTE | 2216 | 89,7 % | 0 | 0 |

Los dos mapas son uniformes: PK_PEDIDO muestra # en todos los tramos
e IX_PED_CLIENTE muestra =. No aparece el patrón de izquierda vacía
y derecha llena que identificaría un patrón cola.

Evidencias de la ejecución:
- evidencia/script/20261116T101118Z_02-anatomia-indice.script.log
- evidencia/script/20261116T101118Z_02-grafico-PK_PEDIDO.script.log
- evidencia/script/20261116T101118Z_02-grafico-IX_PED_CLIENTE.script.log
- evidencia/config/20261116T101118Z_02-volcado-indice.trc.txt

#### Predicción y comprobación de UX_CLI_EMAIL

Con 100000 entradas, 30 bytes estimados por entrada y 7996 bytes
útiles por hoja, cabrían floor(7996 / 30) = 266 entradas por hoja.

Sin ajustar el espacio libre, se necesitarían ceil(100000 / 266)
= 376 hojas. Con un factor de ramificación máximo de 543:

h = 1 + ceil(log_543(376)) = 2.

La predicción simplificada es altura 2. Sin embargo, el diccionario
de mi ejecución ya mostró altura 3 y 501 hojas. El modelo no reproduce
necesariamente el árbol real: supone para este índice el mismo factor
de ramificación que IX_PED_CLIENTE, aunque las claves tienen diferente
tamaño y distribución.

La comprobación con ANALYZE INDEX ... VALIDATE STRUCTURE mostró:

| Medida | Resultado |
|---|---:|
| Altura | 3 |
| Bloques de hoja | 501 |
| Bloques de rama | 3 |
| Entradas | 100000 |
| Bytes medios por entrada | 35,89 |
| Ocupación | 90 % |
| Entradas borradas | 0 |

La altura medida es 3, frente a la predicción simplificada de 2.
Las entradas reales ocupan 35,89 bytes de media, no los 30 supuestos.
Además, el factor de ramificación 543 utilizado en la predicción
procedía de IX_PED_CLIENTE: no es una capacidad medida para las ramas
de UX_CLI_EMAIL. Por eso la predicción no reproduce la altura real.

El gráfico mostró 501 hojas: 500 en el tramo de ocupación 80–89 %
y una en el tramo 0–9 %. La ocupación viva media fue del 89,6 %,
sin entradas borradas ni hojas vacías.

El mapa agregado fue uniforme, con símbolos =. No muestra un patrón
cola. La hoja poco ocupada aparece en el histograma, aunque no se
distingue en el mapa porque este agrupa las hojas en 64 tramos.

En comparación, la primera hoja de PK_CLIENTE tenía 578 entradas
y solo 8 bytes libres. Ambos índices tienen 100000 entradas, pero
sus claves son distintas: PK_CLIENTE utiliza identificadores numéricos
y UX_CLI_EMAIL utiliza correos de texto. El tamaño y el orden de las
claves influyen en su estructura y ocupación.

El reto terminó con código de salida 0.

#### Simulacro C — Borrado de tabla y restauración completa

El script creó previamente una copia de 1,3 GB:

`backups/20261116T202648Z_lab5-pre-simulacro`.

Antes del fallo, ACA_MATRICULAS contenía 60000 filas.

En la primera prueba se ejecutó DROP TABLE sin PURGE.
La tabla y sus índices aparecieron en la papelera, y
FLASHBACK TABLE ... TO BEFORE DROP recuperó la tabla.
El recuento posterior volvió a ser de 60000 matrículas.

En la segunda prueba se ejecutó DROP TABLE ... PURGE.
La consulta posterior devolvió ORA-00942, resultado esperado:
la tabla ya no existía y no podía recuperarse mediante la papelera.

Se restauró la copia completa lab5-pre-simulacro.
FREEPDB1 volvió a READ WRITE y ACA_MATRICULAS recuperó
sus 60000 filas.

Métricas:
- Tiempo de restauración medido por el script: 129 segundos.
- Ventana entre la copia y el fallo: 4 segundos.
- Código de salida: 0.

Los 129 segundos corresponden al tramo de restauración cronometrado,
no necesariamente a todo el tiempo transcurrido desde el borrado.

La restauración devolvió toda la base al estado de la copia:
cualquier cambio posterior a ella habría quedado fuera del
estado recuperado. La ventana de 4 segundos expresa esa exposición
temporal; no cuantifica transacciones de negocio realmente perdidas.

La prueba demuestra la diferencia entre recuperar una tabla
con la papelera y restaurar toda la base por el daño de una
sola tabla. La segunda opción afecta también al estado de las
demás tablas.

### Parte D — ¿Haría cubriente el índice de Q9?

No añadiría columnas a IX_PED_FECHA para esta consulta: recuperar
los 20 pedidos más recientes ya cuesta solo 5 lecturas lógicas,
mientras que PEDIDO ocupa 41,6 MB y cubrir todas sus columnas
exigiría mantener un índice más ancho.

El plan fue COUNT STOPKEY > VIEW > TABLE ACCESS BY INDEX ROWID
PEDIDO > INDEX FULL SCAN DESCENDING IX_PED_FECHA.
La prueba devolvió 20 filas, sin lecturas físicas, y terminó con código 0.

Esta decisión se basa en el bajo coste medido; no he creado ni medido
un índice cubriente alternativo para Q9.

#### Simulacro D — Pérdida y recuperación de un datafile

El camino observado requirió reabrir FREEPDB1:
tras reparar el archivo, la PDB estaba MOUNTED y el script
ejecutó su apertura. La comprobación posterior mostró READ WRITE.

Después de RESTORE y RECOVER, la fila 104 apareció en EGRESADO,
valor confirmado después de la copia RMAN. Por tanto, el estado
recuperado incorporó redo posterior al backup.

El RPO observado para la transacción de control fue 0:
el cambio confirmado sobrevivió a la pérdida del datafile.

Métricas del script:
- Archivo fuera de línea hasta en línea: 18 segundos.
- Tiempo desde el fallo: 19 segundos.
- Código de salida: 0.

El script ejecutó después la devolución de la fila 104 a ACTIVO.
El recuento final de ACA_ESTUDIANTES fue de 20000 filas.

A diferencia del simulacro C, que restauró toda la base en
129 segundos y volvió al estado de la copia, este procedimiento
recuperó el archivo afectado e incorporó los cambios posteriores
mediante redo.

La comparación temporal tiene un límite: los 129 segundos de C
corresponden al tramo de restauración, mientras que D ofrece
tanto el tramo de reparación (18 segundos) como el tiempo
desde el fallo (19 segundos).
El archivo afectado fue el datafile 16:
`/opt/oracle/oradata/FREE/FREEPDB1/academia01.dbf`.

El backup RMAN terminó antes del fallo, con etiqueta
LAB5_SIMULACRO_D, y se guardó en la FRA. También se generó
un autobackup.

El diagnóstico mostró:
- ORA-01116: no se pudo abrir el archivo de base de datos.
- ORA-01110: identificó el número 16 y su ruta.
- ORA-27041: fallo al abrir el archivo en el sistema operativo.
- Linux Error 2: el archivo no existía.

Antes de reparar, FREEPDB1 ya estaba MOUNTED.
El script indicó el camino de cierre por fallo de medios
asociado a ORA-63999; el fragmento de alert log mostrado
no incluye directamente ese código.

RMAN restauró el datafile 16 en su ruta y completó
media recovery. Después se puso el archivo en línea y
se abrió de nuevo FREEPDB1.

La consulta final mostró READ WRITE y la fila 104 en EGRESADO,
confirmando la recuperación del cambio posterior al backup.

### Parte E — Curva del punto de equilibrio

![Curva del punto de equilibrio](lab5/evidencia/config/04-curva-equilibrio.png)

El índice con CF malo supera el coste del recorrido completo entre
el 0,5 % y el 1 %; el de CF bueno, entre el 50 % y el 100 %.
El optimizador cambia antes, entre el 0,1 % y el 0,2 %, porque estima
costes y no compara únicamente las lecturas lógicas medidas.
Los intervalos reflejan los puntos probados, no cruces exactos.

### Parte F — Sargabilidad: resultados medidos

| Prueba | Lecturas iniciales | Lecturas finales |
|---|---:|---:|
| Q1: función sobre EMAIL → función sobre el dato recibido | 1486 | 4 |
| Q2: aritmética sobre FECHA_PEDIDO → columna despejada | 5285 | 323 |
| Q3: código postal numérico → literal de texto | 5232 | 106 |
| Q5: OR sin índice en teléfono → ambas ramas indexadas | 1486 | 6 |
| Q5: alternativa UNION con ambas ramas indexadas | 1486 | 6 |
| Q11: EXTRACT → rango de fechas | 5232 | 5232 |

En Q3, el plan de la consulta original mostró
TO_NUMBER("CODIGO_POSTAL") = 30001: la conversión se aplicaba a la
columna. La comparación con un literal de texto permitió utilizar
el índice temporal IX_PED_CP.

Q4a (%ez) y Q4b (Gonz%) no son reescrituras equivalentes:
buscan conjuntos distintos. Q4b permitió un rango por índice,
pero acumuló 2024 lecturas, frente a las 1523 del recorrido de Q4a.

En Q5, tanto la solución OR con ambas ramas indexadas como UNION
necesitaron 6 lecturas. No atribuyo la mejora de UNION únicamente
a la reescritura: en esa prueba ya existía el índice de teléfono.

Q11 mantuvo TABLE ACCESS FULL y 5232 lecturas en ambas versiones.
Una condición sargable permite considerar el índice, pero no obliga
a elegirlo cuando se solicita una parte grande de la tabla.

La ejecución terminó con código 0 y dejó los 7 índices originales.

### Reto F — Revisión de código con medidas

Consulta revisada:

SELECT *
FROM tiendasur.cliente
WHERE SUBSTR(telefono, 1, 3) = '600'
   OR UPPER(apellidos) = 'GIL';

#### Comentario de revisión del Pull Request

La consulta aplica funciones a TELEFONO y APELLIDOS, por lo que
un índice normal sobre esas columnas no proporciona directamente
una búsqueda por las expresiones utilizadas.

Propongo reescribir el teléfono como:

WHERE telefono LIKE '600%'
   OR UPPER(apellidos) = 'GIL'

No sustituyo UPPER(apellidos) = 'GIL' por apellidos = 'Gil':
sin una regla de normalización que lo justifique, cambiaría
la búsqueda para otras combinaciones de mayúsculas y minúsculas.

Para conservar la semántica se probó temporalmente un índice
sobre TELEFONO y otro funcional sobre UPPER(APELLIDOS).
No se modificó V005.

| Escenario | Filas | Lecturas lógicas | Lecturas físicas | Tiempo ms |
|---|---:|---:|---:|---:|
| Original sin índices del reto | 981 | 1487 | 0 | 62,0 |
| Reescrita sin índices del reto | 981 | 1487 | 0 | 44,6 |
| Reescrita con ambas ramas indexadas | 981 | 1568 | 1 | 72,0 |

Las dos primeras versiones hicieron TABLE ACCESS FULL.
La tercera utilizó una expansión del OR con UNION-ALL y
accesos INDEX RANGE SCAN a IX_RF_TELEFONO e IX_RF_APE_UPPER,
seguidos de accesos a CLIENTE por ROWID.

La verificación mediante MINUS en ambos sentidos devolvió
cero diferencias entre los conjuntos de ID_CLIENTE.

La reescritura del teléfono no redujo las lecturas sin índices.
Con ambas ramas indexadas, se realizaron 81 lecturas lógicas más
que con el recorrido completo: 1568 frente a 1487.

Por tanto, no aprobaría estos dos índices para esta consulta
basándome en esta prueba: no demostraron ahorro de lecturas
y añadirían mantenimiento a las escrituras.

El tiempo aislado tampoco prueba una mejora estable.
Se conservan las medidas observadas, incluida una lectura física
en el escenario indexado, sin atribuirle una causa no comprobada.

Aprobaría la reescritura del prefijo por claridad y por permitir
considerar un acceso por rango si la carga futura lo justifica,
sin prometer una mejora inmediata.

#### Limpieza y evidencia

Se eliminaron únicamente IX_RF_TELEFONO e IX_RF_APE_UPPER.
La comprobación final mostró:
- Índices temporales restantes: 0.
- Índices de TiendaSur: 9.
- Código de salida: 0.

Script: scripts/lab5/05-reto-revision.sql.
La evidencia se conserva en el registro *_05-reto-revision.script.log.

### Parte G — Protocolo de diseño y coste de escritura

Evidencia:
`evidencia/script/20261116T121534Z_06-indices.script.log`.

Se completaron los escenarios heredado, propuesta del compañero
y V005. La ejecución terminó con código 0.

#### Protocolo aplicado

1. Necesidad: la carga Q2, Q3, Q7, Q8, Q9 y Q12 utilizó
   IX_PED_FECHA, IX_PED_CP, IX_PED_CLI_FEC e IX_PED_ESTADO.
   No utilizó IX_PED_CANAL, IX_PED_CLIENTE, IX_PED_FEC_CLI
   ni IX_PED_IMPORTE durante la observación.
2. Viabilidad: el porcentaje medio por clave sirve como primera
   aproximación, pero no sustituye a la distribución real ni a las
   medidas. ESTADO tiene cuatro valores, pero P representa el 2 %,
   no el 25 % medio. Q12 utilizó su índice con 147 lecturas.
3. Escritura: los INSERT pasaron de 10,2 a 20,4 cambios de bloque
   por fila con la propuesta. V005 limitó el coste a 12,2.
4. Redundancia: IX_PED_CLIENTE era prefijo de IX_PED_CLI_FEC;
   IX_PED_FECHA era prefijo de IX_PED_FEC_CLI. Se eligió qué conservar
   según la carga, no borrando automáticamente el índice más corto.
5. Ciclo de vida: IX_PED_IMPORTE quedó INVISIBLE y VALID antes de
   retirarlo. Q2 siguió realizando 335 lecturas con IX_PED_FECHA.

#### Costes aceptados con V005

UPDATE estado pasó de 2 a 8,1 cambios de bloque por fila:
además de la tabla y su undo, cambia la entrada del índice cubriente
que contiene ESTADO y desaparece la entrada del índice parcial
cuando el pedido pasa de P a E.

UPDATE importe mantuvo aproximadamente 6 cambios de bloque por fila.
Antes se mantenía IX_PED_IMPORTE; con V005 se mantiene
IX_PED_CLI_FEC_CUB, que también contiene IMPORTE.
El redo no fue idéntico: pasó de 754 a 812 bytes por fila.

DELETE mantuvo 10,1 cambios de bloque por fila pese a haber
5 índices: las filas antiguas borradas en esta prueba no estaban
en P y no tenían entrada en IX_PED_PENDIENTES.

#### Diseño final

PEDIDO quedó con:
- PK_PEDIDO.
- IX_PED_FECHA.
- IX_PED_CLI_FEC_CUB.
- IX_PED_PENDIENTES.
- IX_PED_CP.

CLIENTE quedó con:
- PK_CLIENTE.
- UX_CLI_EMAIL.
- IX_CLI_PAIS_CIUDAD.
- UX_CLI_DNI.

Los 9 índices finales aparecen VISIBLE.

La salida de esta parte demuestra la aplicación de V005 y su coste
DML. No contiene una nueva medición de todas las consultas de lectura
tras V005, por lo que no atribuyo a este registro cifras de lectura
del diseño final que no se hayan medido aquí.

### Parte H — Divisiones, patrón cola y remedios

- IX_AZAR: 595 divisiones, ninguna 90/10, 596 hojas y 75,4 %
  de ocupación viva.
- IX_CRECIENTE: 398 divisiones, todas 90/10, 399 hojas y 99,9 %
  de ocupación viva.
- IX_INVERTIDA: 511 divisiones, ninguna 90/10, 512 hojas y 77,9 %
  de ocupación viva.
- Consulta por rango: 4 lecturas con el índice normal y 878 con
  recorrido completo en la tabla con índice REVERSE.
- Patrón cola: 425 hojas, 224 sin entradas vivas y 226 lecturas
  para recuperar un único mensaje.
- COALESCE: 201 hojas y 2 lecturas; el segmento permaneció en 4 MB.
- SHRINK SPACE posterior: 1,69 MB y 2 lecturas.
- REBUILD ONLINE posterior: 223 hojas, 2 MB y 2 lecturas.

El 80 % de espacio usado de IX_COLA no equivalía a un 80 % de
ocupación útil: descontando las entradas borradas, la ocupación
viva era del 47,1 %. El mapa permitió localizar el problema
en el extremo izquierdo.

El gráfico final corresponde al estado posterior a REBUILD ONLINE:
89,7 % de ocupación viva, sin hojas vacías y sin entradas borradas.

La ejecución terminó con código 0 y confirmó la eliminación
del esquema de pruebas LAB5_PRUEBAS.

### Parte I — SCN y checkpoints

#### Avance del SCN

CURRENT_SCN pasó de 6428975 a 6428977 entre las dos consultas.
El SCN puede avanzar aunque no ejecute operaciones manuales,
porque la base mantiene actividad interna.

Después del checkpoint, el checkpoint de la base era 6428985
y CURRENT_SCN era 6429005. No representan lo mismo:
el primero identifica el checkpoint registrado y el segundo
el SCN actual cuando se realizó la consulta.

#### PDB$SEED

Los archivos mostrados con CON_ID = 2 mantuvieron el checkpoint
2098101, coincidente entre control file y cabecera.
PDB$SEED está en solo lectura y no tiene que avanzar al mismo
checkpoint que los archivos de lectura y escritura.

#### Estimación de recuperación

La consulta a V$INSTANCE_RECOVERY devolvió:

| Magnitud | Valor |
|---|---:|
| TARGET_MTTR | 0 |
| ESTIMATED_MTTR | 13 segundos |
| RECOVERY_ESTIMATED_IOS | 4 |
| ACTUAL_REDO_BLKS | 338 |
| FAST_START_MTTR_TARGET | 0 |
| LOG_CHECKPOINT_INTERVAL | 0 |
| LOG_CHECKPOINT_TIMEOUT | 1800 segundos |

ESTIMATED_MTTR = 13 es una estimación de recuperación de instancia,
no un tiempo medido mediante una caída ni el RTO completo del servicio.

ACTUAL_REDO_BLKS = 338 representa los bloques de redo que Oracle
estima que se requieren para la recuperación en ese momento.
No es el total de redo generado por las Partes B a H ni un recuento
de bloques de datos sucios.

La consulta se hizo después del checkpoint, pero la actividad
de la instancia continúa. No atribuyo esos 338 bloques a una
operación concreta sin una medición adicional.

Una carga mayor puede aumentar el trabajo pendiente de recuperación,
pero no permite afirmar que diez veces más carga implique
exactamente diez veces más tiempo.

FAST_START_MTTR_TARGET permite expresar un objetivo de recuperación
en segundos. En esta ejecución vale 0: no se ha fijado un objetivo
positivo mediante ese parámetro. Esto no significa que no existan
checkpoints ni que la recuperación tarde cero segundos.

La ejecución terminó con código 0.

### Parte J — Contenido y multiplexación de los control files

#### J.1. Estado inicial y contenido

La consulta a V$CONTROLFILE mostró dos copias iniciales:

- /opt/oracle/oradata/FREE/control01.ctl
- /opt/oracle/oradata/FREE/control02.ctl

Ambas tenían bloques de 16384 bytes y FILE_SIZE_BLKS = 1146.
La columna STATUS aparecía vacía, sin indicar INVALID.

V$CONTROLFILE_RECORD_SECTION mostró, entre otras, las secciones
DATAFILE, TABLESPACE, FILENAME, LOG HISTORY y ARCHIVED LOG.
En esta ejecución aparecieron 22 registros usados en DATAFILE,
20 en TABLESPACE y 15 tanto en LOG HISTORY como en ARCHIVED LOG.

Estos recuentos describen registros de las secciones internas:
no deben interpretarse automáticamente como un inventario de
archivos actuales ni como un diagnóstico del modo ARCHIVELOG.

CONTROL_FILE_RECORD_KEEP_TIME estaba configurado en 7 días.
Este parámetro se refiere a la conservación mínima de registros
reutilizables antes de su reutilización, no a una política de
retención de los archivos físicos de backup o de redo archivado.

Se generó la copia lógica:
`/opt/oracle/oradata/FREE/controlfile_lab5.trc`.

La traza contiene un script CREATE CONTROLFILE; no es una copia
binaria del control file ni una copia de los datos de la base.
Permanece dentro del volumen y no se incorpora a Git.

#### J.2. Tercera copia

El script realizó esta secuencia:

1. Amplió CONTROL_FILES en el SPFILE para incluir control03.ctl.
2. Ejecutó SHUTDOWN IMMEDIATE.
3. Copió un control file sano con la base parada, conservando permisos.
4. Arrancó la instancia y comprobó las tres copias del control file.

### Parte K — Grupos, miembros y cambios de redo

#### Estado inicial y multiplexación

La instancia tenía tres grupos de redo de 200 MB, cada uno con
un único miembro:

- Grupo 1: redo01.log.
- Grupo 2: redo02.log.
- Grupo 3: redo03.log.

Se añadió un segundo miembro a cada grupo:
redo01b.log, redo02b.log y redo03b.log.

Los nuevos miembros aparecieron inicialmente como INVALID.
Después de los dos cambios de log del script, los miembros
nuevos de los grupos 2 y 3 dejaron de mostrar ese estado,
pero redo01b.log todavía aparecía como INVALID.

El mensaje del script «ninguno queda INVALID» no coincidía
con la tabla real. Con tres grupos, los dos cambios realizados
no habían completado la vuelta al grupo 1.

Se realizó un cambio adicional y se comprobó el resultado:

| Grupo | Secuencia | Miembros | Archivado | Estado |
|---|---:|---:|---|---|
| 1 | 19 | 2 | NO | CURRENT |
| 2 | 17 | 2 | YES | INACTIVE |
| 3 | 18 | 2 | NO | ACTIVE |

La consulta final a V$LOGFILE mostró los seis miembros sin
INVALID ni STALE. Tanto la ejecución principal como la
verificación adicional terminaron con código 0.

#### Grupos frente a miembros

Los grupos se utilizan sucesivamente: LGWR escribe en el grupo
CURRENT y pasa a otro al producirse un log switch.

Los miembros de un mismo grupo son copias del mismo redo.
Añadir miembros mejora la redundancia, pero no aumenta la
capacidad lógica del grupo: cada grupo sigue siendo de 200 MB.

### Parte L — ARCHIVELOG, FRA y fallo controlado de archivado

#### L.1. Configuración y comprobación

La base ya estaba en ARCHIVELOG antes de esta parte.

El intento deliberado de configurar DB_RECOVERY_FILE_DEST antes
de DB_RECOVERY_FILE_DEST_SIZE produjo ORA-02097 y ORA-19802.
Ambos mensajes correspondían al mismo intento: faltaba definir
el tamaño de la FRA antes de asignar su ruta.

El script corrigió el orden y configuró:

- DB_RECOVERY_FILE_DEST_SIZE: 4 GB.
- DB_RECOVERY_FILE_DEST: /opt/oracle/oradata/fra.

No hizo falta reiniciar porque la base ya estaba en ARCHIVELOG.

La comprobación mostró Archive Mode, archivado automático Enabled
y destino USE_DB_RECOVERY_FILE_DEST. Aparecieron los procesos
ARC0, ARC1, ARC2 y ARC3.

Los nuevos archivados de las secuencias 19 y 20 tenían nombres
OMF o1_mf_... y ARC = YES. La FRA contenía 2 archivados y
aproximadamente 9 MB usados de un límite de 4096 MB.

La ejecución de L.1 terminó con código 0.

#### L.2. FRA llena, provocada y resuelta

Estado inicial: límite de 4096 MB y 9 MB usados.

El script redujo temporalmente el límite a 2 MB. Después ejecutó
un UPDATE de 20000 filas, aunque asignando el mismo valor,
y solicitó el archivado del redo actual.

La operación ALTER SYSTEM ARCHIVE LOG CURRENT produjo:

- ORA-16038: no se pudo archivar el grupo 3, secuencia 21.
- ORA-19809: se superó el límite del área de recuperación.
- ORA-00312: identificación de los dos miembros del grupo afectado.

Los mensajes ORA-00312 nombraban redo03.log y redo03b.log;
no demostraban corrupción de esos archivos.

El alert log confirmó ORA-19815: el límite temporal de
2097152 bytes estaba al 100 %, sin espacio restante.
También registró ORA-19809.

Antes de resolverlo, la secuencia 21 aparecía ACTIVE y sin archivar,
mientras la secuencia 22 era CURRENT.

#### Resolución y verificación

El script restableció el límite a 4096 MB. El archivado pudo continuar:

- Secuencia 21: ARCHIVED = YES.
- Secuencia 22: ARCHIVED = YES.
- Secuencia 23: CURRENT, ARCHIVED = NO.

Que la secuencia actual todavía no esté archivada no indica
por sí solo un fallo.

La FRA terminó con 10,9 MB usados y un límite de 4096 MB.
La ejecución de L.2 terminó con código 0.

El experimento demostró un límite lógico insuficiente de la FRA,
no que el disco físico estuviera lleno. Los 4 GB configurados
son un límite de uso, no una reserva física de espacio.

#### Interpretación operativa

Si el archivador no puede guardar un grupo pendiente, ese grupo
no puede reutilizarse en ARCHIVELOG. Si la situación continúa
hasta agotar los grupos reutilizables, la actividad que necesita
generar redo puede quedar esperando.

La salida muestra el fallo de archivado y su resolución.
No muestra un ORA-00257 ni demuestra que todas las sesiones
de aplicación llegaran a bloquearse.

La solución aplicada fue ampliar el límite, disponiendo de espacio
físico suficiente. En producción también se revisaría la retención
y se gestionarían los archivos con RMAN, sin borrarlos directamente
con rm.

La configuración final quedó en ARCHIVELOG, con FRA de 4 GB.
### Parte M — Undo, lectura consistente y coste de redo

#### M.1. Dos sesiones sobre la misma fila

La sesión A (SID 52) modificó la fila 101 de ACTIVO a EGRESADO
y mantuvo abierta la transacción antes de confirmar.

Mientras A no había confirmado, una consulta normal de B devolvió
ACTIVO. B no leyó el cambio sin confirmar: obtuvo la versión
consistente anterior mediante el undo.

La transacción de A consumía 1 bloque y 1 registro de undo.
Se observaron un bloqueo TM en modo 3 sobre ACA_ESTUDIANTES
y un bloqueo TX en modo 6.

Al solicitar la misma fila con SELECT ... FOR UPDATE WAIT 3,
B no pudo adquirir el bloqueo y recibió ORA-00054 y ORA-40097.
Era el resultado esperado: consultar una versión consistente
no equivale a poder bloquear la fila modificada por otra transacción.

Después del COMMIT de A, una nueva consulta de B devolvió EGRESADO.
La consulta AS OF TIMESTAMP de hace 40 segundos devolvió ACTIVO.
Finalmente, la reparación lógica dejó la fila 101 en ACTIVO.

La gestión de undo era AUTO, con UNDO_TABLESPACE = UNDOTBS1
y UNDO_RETENTION = 900 segundos. Los intervalos mostrados de
V$UNDOSTAT tenían retención ajustada de 900 segundos y ningún
ORA-01555 registrado.

UNDO_RETENTION no demuestra por sí solo una garantía absoluta:
si no está activada RETENTION GUARANTEE y falta espacio,
Oracle puede reutilizar undo no expirado. Esta prueba no consultó
la propiedad de garantía del tablespace.

La ejecución de M.1 terminó con código 0.

#### M.2. Coste de 10000 operaciones

| Operación | Bloques de undo | KB en bloques de undo | Redo total KB | Redo que describe undo KB | Redo del ROLLBACK KB |
|---|---:|---:|---:|---:|---:|
| INSERT | 142 | 1136 | 4795 | 2012 | 355 |
| UPDATE | 71 | 568 | 1258 | 540 | 751 |
| DELETE | 427 | 3416 | 6627 | 3262 | 4701 |

Los KB de undo se obtienen multiplicando los bloques usados
por su tamaño de 8 KB. No equivalen necesariamente a bytes
de contenido útil de registros de undo.

El INSERT necesita información para eliminar las filas y entradas
de índice recién insertadas, sin conservar una imagen anterior
de una fila que no existía.

El UPDATE de esta prueba modifica CANAL, columna no indexada:
se conserva la información anterior necesaria para deshacer
ese cambio. Fue la operación con menos undo y redo de las tres.

El DELETE necesita información para reconstruir las filas
eliminadas y sus entradas de índice. En esta prueba tuvo
el mayor consumo de undo y la mayor generación de redo.

Estas diferencias dependen de las operaciones y los índices
concretos del banco: no significan que todo UPDATE sea siempre
más barato que cualquier INSERT o DELETE.

#### El undo también necesita protección

La columna «redo que describe el undo» forma parte del redo total;
no se suma otra vez. Los cambios en bloques de undo también
se describen en el redo.

El ROLLBACK genera redo adicional porque deshacer modifica bloques.
Se midieron 355 KB al deshacer el INSERT, 751 KB al deshacer
el UPDATE y 4701 KB al deshacer el DELETE.

Por tanto, deshacer las operaciones no elimina el redo que ya
generaron ni convierte el experimento en una operación sin coste.

En recuperación de instancia, el redo permite reconstruir los
cambios necesarios, incluidos los de undo; después, el undo
permite deshacer las transacciones no confirmadas.

La ejecución de M.2 terminó con código 0.

### Parte N — LGWR, DBWn y write-ahead logging

La prueba comenzó con un checkpoint y comprobó que no quedaban
buffers sucios de la tabla observada. Después ejecutó un UPDATE
de 20000 filas, asignando el mismo valor, confirmó y finalmente
forzó otro checkpoint.

| Intervalo | Redo KB | Escrituras LGWR | Commits | Bloques escritos desde caché | Buffers sucios de la tabla al final |
|---|---:|---:|---:|---:|---:|
| UPDATE de 20000 filas + COMMIT | 7035 | 8 | 1 | 0 | 231 |
| ALTER SYSTEM CHECKPOINT | 13 | 1 | 0 | 557 | 0 |

Las columnas de actividad representan incrementos entre medidas.
La columna de buffers sucios representa el estado de la tabla
en cada punto, no un incremento.

#### COMMIT y LGWR

Durante el UPDATE y su confirmación se generaron 7035 KB de redo,
se registraron 8 escrituras de LGWR y 1 commit.

No se registraron bloques escritos desde caché en ese intervalo,
y al terminar todavía había 231 buffers sucios de la tabla.
Por tanto, el COMMIT no esperó a que esos bloques se escribieran
en los datafiles.

Los 7035 KB y las 8 escrituras corresponden al intervalo completo:
no son el coste aislado de la instrucción COMMIT ni significan
que un commit siempre produzca ocho escrituras.

#### Checkpoint y DBWn

Durante el checkpoint se registraron 557 bloques escritos desde
caché y los buffers sucios de la tabla pasaron de 231 a 0.

Los 557 bloques no deben atribuirse únicamente a esos 231 buffers:
las estadísticas de escritura son de toda la instancia, mientras
que el recuento de buffers sucios está filtrado por la tabla.

El intervalo del checkpoint también registró 13 KB de redo y
una escritura de LGWR. La actividad de fondo y otros trabajos
de la instancia pueden contribuir a esas cifras.

DBWn escribe los bloques de datos. CKPT registra la información
del checkpoint en el control file y en las cabeceras de los
datafiles; no sustituye a DBWn en la escritura de bloques de tabla.

#### Write-ahead logging y durabilidad

Antes de escribir un bloque modificado en su datafile, debe
haberse persistido el redo asociado a esos cambios.
Ese orden es el protocolo write-ahead logging.

Esto no significa que DBWn solo pueda escribir después del COMMIT:
puede escribir bloques con cambios de transacciones no confirmadas,
siempre que el redo necesario esté protegido.

Tampoco significa que DBWn solo escriba al ejecutar un checkpoint
manual; también trabaja durante el funcionamiento normal.

Si la instancia cae después de confirmar pero antes de escribir
los bloques de datos, la recuperación puede rehacer los cambios
a partir del redo. El undo permite deshacer lo no confirmado.

La prueba mostró actividad y buffers sucios pese a asignar el
mismo valor: un UPDATE sin cambio lógico no debe suponerse gratuito.

La ejecución terminó con código 0.

### Parte O — Comparación y retrospectiva de los simulacros

| Simulacro | Recuperación comprobada | Tiempo observado | Pérdida de datos |
|---|---|---|---|
| A: caída de instancia | Arranque y recuperación automática con redo y undo | No medido con la evidencia revisada | El cambio confirmado de la fila 102 sobrevivió; el no confirmado de la 103 se deshizo |
| B: control file perdido | Reposición desde una copia sana y MOUNT/OPEN | No medido con la evidencia revisada | No se retrocedieron los datos; no hubo una comprobación específica de transacciones |
| C: tabla borrada con PURGE | Restauración completa de la copia previa | 129 s en el tramo de restauración | Ventana de exposición de 4 s desde la copia; no se cuantificaron transacciones de negocio perdidas |
| D: datafile perdido | RESTORE y RECOVER del archivo 16; reapertura de FREEPDB1 | 18 s de reparación y 19 s desde el fallo | RPO observado 0 para el cambio de control de la fila 104 |

Los tiempos de A y B quedan como una limitación de la medición:
no los deduzco de los nombres de los archivos ni de la duración
de otros simulacros. La mejora es registrar explícitamente
la hora del fallo y la de recuperación verificada del servicio.

#### Hallazgos y mejoras propuestas

- A: una confirmación puede sobrevivir aunque los bloques de datos
  aún necesiten recuperación. El alert log mostró 326 bloques que
  requerían recuperación. Mejoraría el procedimiento añadiendo
  marcas de tiempo y una comprobación explícita tras la reparación
  final de la fila 102.

- B: conservar otras dos copias del control file no permitió
  completar MOUNT mientras faltaba una ruta configurada.
  Mejoraría la captura de evidencias guardando las horas de fallo
  y reapertura, además del diagnóstico del archivo ausente.

- C: recuperar una sola tabla mediante una copia completa exigió
  restaurar toda la base durante 129 segundos. Mejoraría el
  procedimiento evaluando una recuperación de tabla con RMAN
  cuando sea viable, para evitar retroceder el resto de la base.

- D: la PDB estaba MOUNTED y hubo que reabrirla después de recuperar
  el archivo. El cambio posterior al backup sobrevivió gracias
  al redo. Mantendría como comprobaciones obligatorias el estado
  READ WRITE, la consulta funcional y la ausencia de errores
  pendientes antes de cerrar el incidente.

Los cuatro scripts terminaron con código 0.
La copia completa del simulacro C y la recuperación RMAN de D
demostraron restauraciones reales, no solo creación de backups.

### Parte P — Comprobación de salud y verificación final

P.1 se ejecutó con la cuenta de solo lectura C##OPS_RO y terminó
con código 0.

La instancia estaba OPEN y la base y FREEPDB1 en READ WRITE,
con ARCHIVELOG. Ningún tablespace apareció por encima del 80 %.
La FRA tenía 103 MB usados de 4096 MB, aproximadamente el 2,5 %.

Se comprobaron tres control files y ningún grupo de redo con
un solo miembro. Había un backup RMAN DATAFILE FULL completado,
de 38 MB y 4 segundos; ese registro no equivale a un backup
completo de toda la base.

El uso observado fue de 95 procesos sobre un límite de 200
y 123 sesiones sobre 322. No se registraron errores de
snapshot too old ni de falta de espacio de undo.
La consulta más larga registrada fue de 1539 segundos.

#### Clasificación del alert log

- ORA-00202 y ORA-205 de las 20:22: huella del control file
  eliminado deliberadamente en el simulacro B.
- ORA-01110 sobre el archivo 16 y ORA-63999 de las 20:57:
  huella del fallo de medios provocado en D.
- ORA-01113 sobre el archivo 22 durante la reapertura:
  mensaje histórico en el contexto del simulacro D.
  La PDB terminó READ WRITE y la verificación funcional posterior
  fue correcta; no se deduce un incidente nuevo solo de ese registro.
- ORA-00800 [Set Priority Failed] para LGWR y VKTM:
  aviso de configuración del entorno que requiere revisar las
  trazas para precisar su causa. No se confunde con los fallos
  deliberados ni se considera resuelto por obtener código 0.

Los índices señalados en los otros esquemas aparecieron
«sin estadísticas». No se mostraron índices inválidos o invisibles
en ese bloque. La ausencia de estadísticas solo debe considerarse
esperada si se confirma que los objetos correspondientes están vacíos.

#### Verificación automática P.2

16-verificacion-final.sh terminó con:
RESULTADO: TODO OK.
Código de salida: 0.

Se verificaron:
- Backup del Lab 4 íntegro.
- 100000 clientes y 1000000 de pedidos en TiendaSur.
- LAB_TOOLS.MEDIR válido y los cinco índices esperados en PEDIDO.
- DNI único, sin índices invisibles ni esquema LAB5_PRUEBAS.
- Tres control files, redo multiplexado y ARCHIVELOG.
- FRA configurada con 4294967296 bytes en el SPFILE.
- Filas 101, 102 y 104 devueltas a ACTIVO.
- 60000 matrículas restauradas.
- Existencia de backups RMAN completados.
- Una única PDB de usuario y CDB abierta.
- Acceso de C##OPS_RO al alert log.
- Evidencias 00 a 15 presentes.
- config/.env y backups/ fuera de Git.

El resultado valida las comprobaciones del script, no sustituye
la revisión de las respuestas, los retos y la seguridad del historial.

### Reto P — Consulta de alerta por ocupación de la FRA

Se creó scripts/lab5/15-alerta-fra.sql y se ejecutó mediante
scripts/ops/ro.sh con la cuenta de solo lectura.

La consulta devuelve una fila únicamente cuando:
SPACE_LIMIT > 0 y SPACE_USED >= 0,85 × SPACE_LIMIT.

Muestra la ruta de la FRA, MB usados, límite, porcentaje usado
y espacio potencialmente recuperable.

Resultado observado:
- 0 filas seleccionadas.
- Código de salida: 0.

Por tanto, en el momento de la consulta no se cumplía el umbral
de alerta. Esta salida no proporciona el porcentaje exacto de uso.

La ejecución comprobó el camino sin alerta. No se forzó el
umbral modificando la FRA, por lo que no se afirma haber probado
el camino positivo contra una FRA real al 85 %.

La consulta define una condición para monitorización:
no envía notificaciones ni realiza acciones correctoras.

## 3. Simulacro de examen S1–S26

Para cada pregunta: letra o letras elegidas, una frase de justificación
y la Parte del laboratorio que lo demuestra.

| Pregunta | Respuesta | Justificación y Parte |
|---|---|---|
| S1 | B | Un CF cercano al número de filas indica muchos cambios de bloque al recorrer el índice: casi una visita a un bloque diferente por entrada. Parte E: IX_PED_CLIENTE tuvo CF 999041 para 1000000 de filas. |
| S2 | A y C | Un índice funcional puede indexar UPPER(email); si los datos se guardan en minúsculas, email = LOWER(:e) permite aprovechar el índice normal sin añadir otro. Partes D y F. |
| S3 | B | Al comparar VARCHAR2 con un número, Oracle aplica TO_NUMBER a la columna. Parte F: el predicado del plan mostró TO_NUMBER("CODIGO_POSTAL") y la comparación con texto redujo las lecturas de 5232 a 106. |
| S4 | B | Los bitmaps encajan en columnas de baja cardinalidad de un almacén con carga separada de las consultas, evitando el escenario de DML concurrente intensivo. Parte D: prueba de combinación de cuatro bitmaps. |
| S5 | B | INDEX SKIP SCAN puede aprovechar el índice compuesto aunque no se filtre por la primera columna, especialmente si esta tiene pocos valores distintos. Parte D, consulta Q6. |
| S6 | B | INVISIBLE permite observar la carga sin que el optimizador utilice normalmente el índice, manteniéndolo disponible para volver a hacerlo VISIBLE. Parte G: prueba con IX_PED_IMPORTE. |
| S7 | A y C | COALESCE resuelve el recorrido de hojas sin entradas vivas; SHRINK SPACE permite además recuperar espacio del segmento. Parte H: 226 a 2 lecturas tras COALESCE y 4 a 1,69 MB tras el SHRINK posterior. Operar en línea no significa ausencia absoluta de esperas o bloqueos breves. |
| S8 | B | REVERSE reparte claves secuenciales entre hojas, pero impide el acceso por rango ordenado de la clave original. Parte H: 4 lecturas con el índice normal y 878 con recorrido completo en la tabla con REVERSE. |
| S9 | C | Un UPDATE de una columna que no participa en índices no tiene que mantener entradas de todos ellos por el mero hecho de existir. Parte G: el coste depende de las columnas indexadas afectadas. |
| S10 | B | El factor de ramificación determina cuántos hijos caben en cada

## 4. Simulacros — RTO, RPO y retrospectivas

| Simulacro | Tiempo de recuperación observado | RPO / pérdida observada | Evidencia |
|---|---|---|---|
| A — Caída de instancia | No medido con la evidencia revisada | 0 para el cambio confirmado de la fila 102; la modificación no confirmada de 103 se deshizo | lab5/evidencia/script/20261116T201755Z_14a-caida-instancia.script.log |
| B — Control file perdido | No medido con la evidencia revisada | No se retrocedieron los datos; sin comprobación específica de transacciones | lab5/evidencia/script/20261116T202243Z_14b-perdida-controlfile.script.log |
| C — Tabla borrada | 129 s de restauración | Ventana de exposición de 4 s desde la copia; pérdida de transacciones de negocio no cuantificada | lab5/evidencia/script/20261116T202642Z_14c-simulacro-restauracion.script.log |
| D — Datafile perdido | 18 s de reparación; 19 s desde el fallo | 0 para el cambio de control posterior al backup | lab5/evidencia/script/20261116T205728Z_14d-perdida-datafile.script.log |

Los tiempos de A y B no se han inferido de los nombres de los logs.
La falta de cronometraje explícito es una limitación pendiente
respecto al requisito de medir los cuatro simulacros.

## 5. Retrospectiva — FRA llena

### Resumen e impacto

En el escenario controlado de L.2, se redujo el límite de la FRA
de 4096 a 2 MB cuando ya había aproximadamente 9 MB usados.
La solicitud de archivado de la secuencia 21 falló.

Se comprobó un fallo de archivado. No se midió una interrupción
general de todas las sesiones ni se observó ORA-00257.

### Secuencia observada

1. FRA inicial: 4096 MB de límite y 9 MB usados.
2. Reducción temporal del límite a 2 MB.
3. Generación de redo y solicitud de archivado.
4. ORA-16038 y ORA-19809; ORA-19815 en el alert log.
5. Restablecimiento del límite a 4096 MB.
6. Secuencias 21 y 22 archivadas; FRA final de 10,9 MB usados.

### Causa y resolución

La causa fue el límite lógico artificialmente insuficiente,
no la falta demostrada de espacio físico en disco.
Se resolvió restituyendo el tamaño y verificando el archivado.
No se borraron archivos con rm.

### Qué funcionó

El script restauró la configuración dentro de la misma ejecución,
permitió verificar la recuperación del archivado y terminó con código 0.

### Mejoras propuestas

- Alertar antes de llegar al límite y comprobar también el disco físico.
- Revisar retención, backups y eliminación gestionada mediante RMAN.
- Registrar tiempos explícitos de detección y recuperación.
- Comprobar siempre el tamaño final tras una prueba controlada.

### Relación con el caso L.3 del enunciado

El caso L.3 describe cargas repetidas de TiendaSur que llenaron
la FRA con redo archivado. Comparte el mecanismo de bloqueo
del archivado, pero su causa fue acumulación de archivos,
mientras que mi L.2 redujo deliberadamente el límite.
No he realizado una reproducción independiente de L.3.

## 6. Verificación y cierre

La ejecución técnica de P.2 terminó con TODO OK y código 0.
Evidencia:
`lab5/evidencia/script/20261116T211802Z_16-verificacion-final.script.log`.

Las preguntas de comprobación 1–22 y la tabla S1–S26 están
respondidas. La tabla del simulacro es una resolución revisada,
no un intento autónomo cronometrado.

Los tiempos de recuperación de los simulacros A y B no se
midieron con la evidencia revisada. Esta limitación se recoge
en la tabla y retrospectiva conjunta.

Siguen pendientes:
- Revisión y realización de los retos que requieren medidas adicionales.
- Control de seguridad de archivos e historial.
- Revisión final de la documentación.
- Push, Pull Request, revisión y merge.
- Etiqueta lab5-final y copia final de la base.

El resultado TODO OK valida las comprobaciones del script,
pero no sustituye el cierre documental ni el flujo de entrega.

### Reto I — MTTR y carga de escritura

Se consultó V$INSTANCE_RECOVERY desde CDB$ROOT en tres momentos:
tras un checkpoint inicial, después de una carga de escritura con
COMMIT y tras un checkpoint final.

La carga consistió en actualizar TELEFONO con su propio valor
en TIENDASUR.CLIENTE, limitando el UPDATE a 20000 filas.
La salida conservada no muestra SQL%ROWCOUNT, por lo que no se
afirma un recuento exacto de filas actualizadas.

| Momento | ESTIMATED_MTTR (s) | ACTUAL_REDO_BLKS | RECOVERY_ESTIMATED_IOS |
|---|---:|---:|---:|
| A. Tras checkpoint inicial | 11 | 0 | 7 |
| B. Tras UPDATE y COMMIT | 11 | 0 | 413 |
| C. Tras checkpoint final | 11 | 0 | 3 |

RECOVERY_ESTIMATED_IOS representa el número de búferes sucios
en caché. Tras la carga pasó de 7 a 413 y, tras el checkpoint
final, descendió a 3.

ESTIMATED_MTTR permaneció en 11 segundos en las tres muestras.
Por tanto, la prueba muestra una variación de búferes sucios,
pero no un aumento observable del MTTR estimado.

ACTUAL_REDO_BLKS permaneció en cero. Este indicador representa
redo requerido para recuperación en el instante observado,
no el redo total generado por la carga.

No se ejecutó un checkpoint manual entre A y B, pero tampoco
se deshabilitó la actividad automática de escritura/checkpoint.
Las muestras corresponden a la instancia y pueden incluir
actividad de fondo, no exclusivamente la sesión de prueba.

No se provocó un fallo: los 11 segundos son una estimación,
no una duración de recuperación medida.

Script: scripts/lab5/08-reto-mttr.sql.
Evidencia: registro *_08-reto-mttr.script.log.
Código de salida: 0.

### Reto M — Coste de las operaciones y sus ROLLBACK en la FRA

Con la base en ARCHIVELOG se midió SPACE_USED de
V$RECOVERY_FILE_DEST, se ejecutó de nuevo la prueba
12-undo-y-redo.sql y se forzó ALTER SYSTEM ARCHIVE LOG CURRENT.

La prueba ejecuta INSERT, UPDATE y DELETE de 10000 pedidos
y deshace cada operación mediante ROLLBACK.

Aunque la salida utiliza la etiqueta KB, el script divide
entre 1024, por lo que las cantidades corresponden a KiB.

| Operación | Redo operación (KiB) | Redo ROLLBACK (KiB) | Total (KiB) |
|---|---:|---:|---:|
| INSERT | 3947 | 339 | 4286 |
| UPDATE | 1258 | 751 | 2009 |
| DELETE | 6620 | 4701 | 11321 |
| Total | 11825 | 5791 | 17616 |

El redo total medido suma aproximadamente 17,20 MiB.
Los valores individuales están redondeados por el script.

No se suma de nuevo la columna «del cual describe el undo»:
es una parte del redo total de cada operación.

El DELETE fue el más caro en esta ejecución:
427 bloques de undo, frente a 138 del INSERT y 71 del UPDATE.
Además, deshacer el DELETE produjo 4701 KiB de redo.
ROLLBACK no elimina el redo ya generado y también genera redo.

#### Crecimiento observado de la FRA

- SPACE_USED inicial: 133227008 bytes.
- SPACE_USED final: 227620352 bytes.
- Incremento: 94393344 bytes, equivalentes a 90,02 MiB.

El crecimiento de la FRA fue mayor que el redo medido
en la sesión. Las magnitudes tienen distinto alcance:
SPACE_USED contabiliza archivos de recuperación, mientras
que las medidas del script corresponden al redo de las
operaciones de la sesión y de sus ROLLBACK.

ARCHIVE LOG CURRENT fuerza el cambio y archivado del log
actual y puede incluir logs anteriores pendientes.
El archivado puede incorporar redo generado antes de la
medida inicial de SPACE_USED, además de actividad concurrente.

No se realizó un archivado de referencia antes de la medida
inicial ni se capturaron las secuencias archivadas antes y
después. Por tanto, no se atribuyen los 90,02 MiB exclusivamente
a esta carga ni se cuantifica la contribución de cada causa.

La conclusión es que deshacer los cambios no evita su coste
en redo ni el espacio de archivado asociado.

Script: scripts/lab5/12-reto-fra-redo.sql.
Evidencia: registro *_12-reto-fra-redo.script.log.
Código de salida: 0.
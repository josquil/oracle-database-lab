# Reto G — Evaluación de V006 para Q11

## Propuesta

Índice candidato:
TIENDASUR.IX_PED_FEC_IMP_Q11 (FECHA_PEDIDO, IMPORTE).

Consulta evaluada:

SELECT SUM(importe)
FROM tiendasur.pedido
WHERE fecha_pedido >= DATE '2025-01-01'
  AND fecha_pedido < DATE '2026-01-01';

Se escribió la propuesta como V006 en una rama experimental.
No se modificó V005.

## 1. Necesidad

Q11 calcula el importe de ventas de un año.
El rango contiene 333333 de los 1000000 de pedidos: 33,33 %.

La referencia mostró que Q11 ya podía resolverse sin acceder
a la tabla: usaba INDEX FAST FULL SCAN de IX_PED_CLI_FEC_CUB.

Por tanto, el candidato no aporta por primera vez cobertura.
Intenta reducir el volumen leído mediante un índice más estrecho.

No se ha justificado en este experimento la frecuencia de Q11.
No se asume una frecuencia para aprobar la propuesta.

## 2. Viabilidad y beneficio de lectura

| Medida | Antes | Con V006 |
|---|---:|---:|
| Lecturas lógicas Q11 | 5046 | 3340 |
| Lecturas físicas | 0 | 0 |
| Tiempo observado (ms) | 119,6 | 87,8 |
| Índice utilizado | IX_PED_CLI_FEC_CUB | IX_PED_FEC_IMP_Q11 |
| Acceso | INDEX FAST FULL SCAN | INDEX FAST FULL SCAN |

Ahorro observado: 1706 lecturas lógicas, aproximadamente 33,8 %.

El candidato no produjo un INDEX RANGE SCAN.
Se recorrió el índice mediante INDEX FAST FULL SCAN.
No se atribuye el ahorro a leer únicamente las entradas del año.

Los tiempos corresponden a estas ejecuciones, no a una
distribución de latencias ni a una mejora estable demostrada.

## 3. Coste de escritura y espacio

Medidas obtenidas con 06-medir-dml.sql, usando los mismos
lotes de 2000 operaciones antes y después.

| Operación | Bloques modificados/fila antes | Con V006 |
|---|---:|---:|
| INSERT | 12,3 | 14,4 |
| UPDATE estado | 8,1 | 8,1 |
| UPDATE importe | 6,0 | 10,1 |
| DELETE | 10,1 | 12,1 |

| Operación | Redo bytes/fila antes | Con V006 |
|---|---:|---:|
| INSERT | 1708 | 2020 |
| UPDATE estado | 1034 | 1034 |
| UPDATE importe | 812 | 1298 |
| DELETE | 1274 | 1507 |

El índice añade mantenimiento a INSERT, DELETE y cambios
de IMPORTE. El UPDATE exclusivo de ESTADO no mostró incremento.

Espacio asignado:
- IX_PED_CLI_FEC_CUB: 40 MiB.
- IX_PED_FECHA: 22 MiB.
- IX_PED_FEC_IMP_Q11: 27 MiB adicionales.

## 4. Redundancia y solapamiento

IX_PED_FECHA (FECHA_PEDIDO) es prefijo izquierdo del candidato
(FECHA_PEDIDO, IMPORTE).

Existe solapamiento, pero no se ha demostrado que sustituir
IX_PED_FECHA conserve el rendimiento de Q2, Q8 y Q9.
No se propone borrarlo basándose exclusivamente en Q11.

IX_PED_CLI_FEC_CUB empieza por ID_CLIENTE y contiene también
FECHA_PEDIDO e IMPORTE. Ya cubre los datos necesarios para Q11,
aunque requiere más lecturas en la ejecución medida.
El candidato no sustituye su función para el historial de cliente.

## 5. Ciclo de vida y decisión

Decisión: no incorporar V006 por ahora.

La mejora de lectura es real en la prueba, pero no basta para
justificar un índice adicional sin conocer la frecuencia de Q11
y el balance de la carga. El coste de escritura sí está medido.

Si Q11 se convierte en una consulta crítica o frecuente,
se reabrirá la propuesta con una ventana de carga representativa,
monitorización de uso y evaluación del posible reemplazo de
IX_PED_FECHA, incluyendo las consultas que dependen de él.

Una eventual retirada de un índice desplegado se evaluaría
primero mediante INVISIBLE y observación antes de DROP.

## Limpieza

Se eliminó exclusivamente IX_PED_FEC_IMP_Q11.
Comprobación final:
- Candidatos restantes: 0.
- Índices de PEDIDO: 5, exactamente los de V005.
- Todos VISIBLE y VALID.
- Código de salida del cierre: 0.

## Descripción propuesta del Pull Request

Título:
experiment(db): evaluate Q11 covering index and defer adoption

Base:
chore/7-oracle-dba-workflow-ii

Resumen:
- Propone V006 con un índice sobre (FECHA_PEDIDO, IMPORTE).
- Compara Q11 y los cuatro tipos de operación DML.
- Reduce lecturas de Q11 de 5046 a 3340.
- Añade 27 MiB y aumenta el coste de INSERT, UPDATE de IMPORTE
  y DELETE.
- Documenta el solapamiento con IX_PED_FECHA.
- Retira el índice de la base al finalizar la prueba.

Decisión solicitada:
Conservar el experimento como evidencia y no fusionar V006
en el estado actual. Refs #7.

Limitaciones:
No se ha establecido la frecuencia de Q11, no se ha evaluado
toda la carga con sustitución de IX_PED_FECHA y no se han
medido percentiles de latencia.
MD
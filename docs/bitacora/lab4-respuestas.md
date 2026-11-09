P1. Un DBA ejecuta SHUTDOWN IMMEDIATE y copia todos los datafiles, control files y redo logs online. ¿Qué
afirmaciones son correctas sobre esta copia? (Elige dos.)
A. Es una copia consistente: al restaurarla no necesita recuperación con redo.
B. Solo es válida si la base estaba en modo ARCHIVELOG.
C. Es una copia inconsistente porque las transacciones en curso se perdieron.
D. Puede restaurarse y abrirse directamente con STARTUP.
E. Debe restaurarse con RMAN obligatoriamente.

Respuesta: A y D ya que SHUTDOWN IMMEDIATE hace un rollback automático y sincroniza el mismo número de cambios en las cabeceras de todos los datafiles y control files haciendo que la copia sea consistente. Como la copia es consistente, si se realizara un STARTUP al destruirse una base de datos, los archivos copiados en sus rutas originales, no requerirían comandos adicionales.

P2. Un tablespace de usuario tiene su datafile en un disco que se va a retirar. La base es Standard Edition y puede
tener una breve indisponibilidad de ese tablespace. ¿Qué secuencia es correcta?
A. ALTER DATABASE MOVE DATAFILE con la base abierta.
B. ALTER TABLESPACE ... OFFLINE; copiar el archivo con el sistema operativo; ALTER TABLESPACE ... RENAME
DATAFILE; ALTER TABLESPACE ... ONLINE.
C. ALTER TABLESPACE ... RENAME DATAFILE con el tablespace ONLINE; Oracle copia el archivo.
D. SHUTDOWN ABORT; mover el archivo; STARTUP.

Respuesta: B ya que primero se aísla el tablespace con OFFLINE, luego se copia o mueve el archivo físicamente mediante el sistema operativo. Luego se actualiza la ruta en el control file con RENAME DATAFILE y por último se pone el tablespace accesible con ONLINE. 

P3. Un DBA consulta v$instance y v$database en una base abierta. ¿Qué dos afirmaciones son correctas? (Elige dos.)
A. STARTUP_TIME de v$instance cambia cada vez que se arranca la instancia.
B. DBID de v$database cambia cada vez que se recrea el contenedor.
C. CREATED de v$database indica cuándo se creó la base, no cuándo se arrancó.
D. Una instancia puede montar dos bases de datos a la vez si tienen distinto DBID.
E. v$database solo se puede consultar con la base en OPEN.

Respuesta: A y C ya que la vista v$instance muestra información de la instancia (memoria y procesos), por lo que su columna STARTUP_TIME se actualiza cada vez que se hace un STARTUP. Por el contrario, la vista v$database muestra información física de la base de datos (los archivos), por lo que su columna CREATED indica la fecha permanente en la que se creó la base de datos, independiente de cuándo se haya arrancado.

P4.  La instancia está en estado NOMOUNT. ¿Qué dos operaciones puede realizar el DBA en este estado? (Elige dos.)
A. Consultar v$parameter.
B. Consultar dba_users.
C. Recrear el control file con CREATE CONTROLFILE.
D. Cambiar la base a modo ARCHIVELOG.
E. Renombrar el datafile del tablespace SYSTEM.

Respuesta: A y C, porque en el estado NOMOUNT, la instancia ya ha arrancado en la memoria leyendo el archivo de parámetros (SPFILE/PFILE), por lo que vistas de memoria como v$parameter ya están disponibles. Además, como en este estado el control file todavía no se ha intentado abrir, es el momento exacto en el que el DBA debe estar para recrearlo mediante CREATE CONTROLFILE si este se hubiera perdido.

P5.  ¿En qué etapa debe estar la base para ejecutar ALTER DATABASE ARCHIVELOG?
A. NOMOUNT
B. MOUNT
C. OPEN READ WRITE
D. OPEN RESTRICTED

Respuesta: B, para activar el modo ARCHIVELOG (ALTER DATABASE ARCHIVELOG), la base de datos debe estar obligatoriamente en estado MOUNT tras un cierre limpio. Esto se debe a que Oracle necesita guardar esta nueva configuración en el control file (que se abre en la fase MOUNT), pero los datafiles deben seguir inaccesibles para los usuarios (no puede estar OPEN) para garantizar que no hay transacciones a medias durante el cambio.


P6.  Un DBA ejecuta ALTER SYSTEM SET open_cursors = 500; en una instancia que arrancó con SPFILE. ¿Cuál es el
resultado?
A. El cambio se aplica solo en memoria.
B. El cambio se aplica en memoria y en el SPFILE.
C. El cambio se aplica solo en el SPFILE.
D. Falla porque falta la cláusula SCOPE.

Respuesta: B, ya que al ejecutar ALTER SYSTEM SET sobre un parámetro dinámico (como open_cursors) en una instancia que ha arrancado con un SPFILE, y omitir la cláusula SCOPE, Oracle asume por defecto SCOPE=BOTH. Esto significa que el cambio se aplica inmediatamente en la memoria de la instancia en ejecución y, al mismo tiempo, se guarda en el SPFILE para que el valor persista en reinicios futuros.

P7. Conectado a FREEPDB1, un DBA ejecuta ALTER SYSTEM SET processes = 300 SCOPE = SPFILE;. ¿Qué ocurre?
A. Se aplica solo a FREEPDB1 en el próximo arranque.
B. Se aplica a toda la instancia en el próximo arranque.
C. Falla con ORA-65040 porque PROCESSES no es modificable a nivel de PDB.
D. Falla con ORA-02095 porque PROCESSES es estático.

Respuesta: C, parámetro PROCESSES define el límite de procesos a nivel del sistema operativo para toda la instancia en una arquitectura Multitenant (CDB/PDB). Como se está intentando modificar mientras se está conectado directamente a la PDB FREEPDB1, por lo que va a saltar el error de operación no permitida desde una base de datos ORA-65040.

P8. ¿Qué dos sentencias permiten recuperar una instancia que no arranca por un valor erróneo escrito en el SPFILE?
(Elige dos.)
A. STARTUP PFILE='/ruta/init_bueno.ora'
B. ALTER SYSTEM RESET ... SCOPE = MEMORY
C. CREATE SPFILE FROM PFILE='/ruta/init_bueno.ora'
D. ALTER DATABASE OPEN RESETLOGS
E. SHUTDOWN ABORT

Respuesta: A y C, si SPDFILE tiene un error y la instancia se niega a arrancar, se puede solucionar arrancando temporalmente la instancia e indicándole que use un archivo de texto de respaldo sano (STARTUP PFILE), o se puede sobrescribir directamente el SPFILE dañado recreándolo a partir de ese PFILE sano (CREATE SPFILE FROM PFILE).

P9.  Una instancia tiene MEMORY_TARGET = 0, SGA_TARGET = 2G y DB_CACHE_SIZE = 512M. ¿Qué afirmación
es correcta?
A. El buffer cache tendrá exactamente 512 MB siempre.
B. ASMM gestiona la SGA y el buffer cache nunca bajará de 512 MB.
C. AMM gestiona SGA y PGA juntas.
D. DB_CACHE_SIZE se ignora porque SGA_TARGET está fijado.

Respuesta: B, tener MEMORY_TARGET=0 y configurar un valor en SGA_TARGET, se activará la gestión automática de la memoria compartida (ASMM). Cuando ASMM está activo y se le asigna manualmente un tamaño a un componente dinámico como el DB_CACHE_SIZE, Oracle no lo ignora ni lo deja fijo, sino que lo interpreta como el tamaño mínimo garantizado. El buffer cache podrá crecer si hay memoria libre en la SGA, pero nunca bajará de esos 512 MB.

P10.  ¿Qué dos estructuras forman parte de la PGA de un proceso servidor dedicado? (Elige dos.)
A. El área de ordenación (sort area) de una consulta con ORDER BY.
B. El shared pool.
C. El log buffer.
D. La información de sesión (session memory) en servidor dedicado.
E. El buffer cache.

Respuesta: A y D, PGA o Program Global Area es una zona de memoria privada y exclusiva para un único proceso de servidor. En ella se crean las áreas de trabajo (SQL Work Areas) para operaciones pesadas, como el área de ordenación (sort area) que usan los ORDER BY. Además, en una arquitectura de servidor dedicado, la PGA también almacena la memoria de estado de la sesión (variables de login, cursores abiertos).

P11. Un usuario ejecuta COMMIT. ¿Qué proceso debe completar su escritura antes de que el COMMIT devuelva el
control?
A. DBWn
B. CKPT
C. LGWR
D. ARCn
E. SMON

Respuesta: C, al ejecutar un COMMIT el proceso LGWR (Log Writer) está obligado a escribir inmediatamente todos los registros de esa transacción desde la memoria (Log Buffer) a los archivos físicos en disco (Redo Logs). Oracle no devuelve el control de la sesión al usuario hasta que el LGWR confirma que la escritura ha terminado. Esto es lo que garantiza que, si se va la luz un milisegundo después, los datos no se pierdan.

P12. ¿Qué dos procesos de background son obligatorios en cualquier instancia de Oracle? (Elige dos.)
A. ARC0
B. PMON
C. RECO solo si hay database links
D. SMON
E. CJQ0

Respuesta: B y D, PMON (Process Monitor) y SMON (System Monitor) son procesos de background absolutamente vitales y obligatorios para que cualquier instancia de Oracle pueda existir. PMON se encarga de limpiar la memoria y liberar los bloqueos si la conexión de un usuario se cae inesperadamente, mientras que SMON es el responsable de recuperar la base de datos de forma automática al arrancar tras una caída abrupta (crash recovery).


8. Preguntas de comprobación.


8.1.1. Respaldo
  1. ¿Por qué la copia de la Parte B es consistente? ¿Qué pasaría si se tomara con la base abierta?
Es consistente porque se tomó tras un SHUTDOWN IMMEDIATE, lo que obliga a Oracle a hacer rollback de transacciones incompletas y sincronizar el mismo número de cambio (SCN) en todos los datafiles y control files. Si se tomara abierta, cada archivo se copiaría en un instante distinto (SCNs diferentes), quedando inconsistente y requiriendo aplicar redo logs para poder abrirla. (Evidencia: El script de backup ejecuta un shutdown limpio antes de copiar los archivos).
  2. ¿Para qué sirven manifiesto.txt y SHA256SUMS? ¿Qué comprueba restaurar-estado.sh antes de tocar nada?
El manifiesto.txt es un registro documental que explica qué contiene la copia y cómo se tomó. SHA256SUMS contiene las "huellas dactilares" (hashes) criptográficas de cada archivo. El script restaurar-estado.sh comprueba esos hashes para garantizar que ningún archivo se ha corrompido antes de sobreescribir la base de datos viva. (Evidencia: 10-verificacion-final.script.log comprueba que el backup está íntegro verificando el SHA256).
  3. Define RPO y RTO con los datos de tu propia copia.
El RPO (Recovery Point Objective) es el punto en el tiempo máximo al que tolero volver si hay un fallo; en mi caso, el instante exacto de mi backup: 20261108T180610Z. El RTO (Recovery Time Objective) es el tiempo máximo que tardaría en restaurar el servicio; en mi entorno, son los escasos minutos que tarda el script restaurar-estado.sh en copiar los archivos de vuelta y levantar el contenedor. (Evidencia: Nombre de la carpeta de backup backups/20261108T180610Z_lab3-final).
8.1.2. Diagnóstico y correcciones
  4. ¿Dónde creó Oracle los datafiles de V000 y por qué? ¿Qué parámetro habría evitado el problema?
Los creó fuera del volumen persistente de Docker (en la ruta por defecto del binario de Oracle) porque el script V000 no especificó la ruta en los CREATE TABLESPACE. Esto se habría evitado configurando el parámetro db_create_file_dest (OMF), que obliga a Oracle a colocar cualquier datafile nuevo en /opt/oracle/oradata. (Evidencia: Salida del script de verificación mostrando 10 archivos originales fuera de ruta).
  5. ¿Por qué ALTER TABLESPACE ... RENAME DATAFILE no basta para mover un archivo?
Porque ese comando solo actualiza el diccionario de datos de Oracle (el control file) para decirle dónde debe ir a buscar el archivo a partir de ahora, pero no mueve físicamente el fichero en el disco. Hay que moverlo a mano con el sistema operativo (comandos cp o mv).
  6. ¿Por qué no se edita V000 y se crea V003? ¿Por qué invalidar una contraseña es mejor que borrarla del archivo?
No se edita V000 por el principio de inmutabilidad (infraestructura como código): lo que ya se ejecutó en producción no se toca, se arregla con un parche nuevo (V003). Invalidar la contraseña (o bloquear la cuenta) es mejor porque la borramos del texto plano del repositorio de Git, impidiendo que cualquiera que lea el código la robe, pero manteniendo la seguridad en la base de datos. (Evidencia: 10-verificacion-final.script.log confirma 0 cuentas ADMIN_ con contraseña).
  7. ¿Qué demuestra la prueba de persistencia y por qué se ejecuta después de reubicar?
Demuestra que los datos sobreviven a la destrucción y recreación del contenedor Docker. Se ejecuta justo después de reubicar los datafiles para confirmar que ahora sí están dentro de la carpeta mapeada al volumen del host, ya que si siguieran en la capa efímera del contenedor, la base de datos habría fallado al arrancar.
8.1.3. Instancia y arranque
  8. Con tus evidencias: tres datos que pertenecen a la instancia y tres que pertenecen a la base de datos.
Pertenecen a la instancia (memoria y procesos): el parámetro open_cursors=300, los 87 procesos de background, y la memoria consumida (SGA). Pertenecen a la base de datos (archivos físicos): el estado READWRITE, los 5 tablespaces de negocio y los usuarios creados como C##OPS_RO. (Evidencia: Valores capturados en el script 10-verificacion-final.sh y 09-procesos.sql).
  9. ¿Qué lee Oracle en NOMOUNT, en MOUNT y en OPEN? Relaciónalo con ORA-01507 y ORA-01219.
En NOMOUNT lee el SPFILE/PFILE para levantar la memoria. En MOUNT lee el Control File. En OPEN abre los Datafiles y Redo logs. Si en NOMOUNT intentas consultar datos estructurales, salta el ORA-01507 porque el control file aún no está abierto. Si en MOUNT intentas consultar tablas de usuario, salta el ORA-01219 porque los datafiles aún están cerrados.
  10. ¿Por qué FREEPDB1 se abre sola tras ALTER DATABASE OPEN? ¿Qué harías si no lo hiciera?
Se abre sola porque previamente guardamos su estado de arranque automático usando el comando ALTER PLUGGABLE DATABASE FREEPDB1 SAVE STATE. Si no lo hiciera, arrancaría en modo MOUNT y tendríamos que abrirla manualmente ejecutando ALTER PLUGGABLE DATABASE FREEPDB1 OPEN. (Evidencia: 10-verificacion-final.script.log confirma FREEPDB1 abierta READWRITE).
  11. Clasifica ORA-00800 y ORA-20013 del alert log: ¿alerta real o ruido conocido? Justifícalo.
Son ruido conocido en la versión Free 23ai/26ai. ORA-00800 es un aviso menor (soft warning) sobre límites de memoria, y ORA-20013 tiene que ver con la limpieza de procesos internos avanzados (AQ) que no afectan al funcionamiento transaccional del laboratorio. Se pueden ignorar.
8.1.4. Parámetros
  12. Diferencia entre v$parameter y v$spparameter con el ejemplo de db_files de tu evidencia.v$parameter muestra el valor que está usando la instancia ahora mismo en la memoria RAM, mientras que v$spparameter muestra el valor guardado en el archivo físico SPFILE para el próximo reinicio. (Evidencia: En la validación vimos que db_files ya no estaba en el SPFILE (FALSE) tras el RESET, aunque la instancia actual siguiera funcionando con el valor antiguo en memoria).
  13. ¿Qué hace SCOPE=BOTH y cuál es el SCOPE por defecto con SPFILE?SCOPE=BOTH aplica el cambio de un parámetro inmediatamente en la memoria de la instancia y, además, lo guarda en el SPFILE para que sea persistente en futuros reinicios. Si la instancia arrancó con SPFILE y omites el SCOPE, el comportamiento por defecto es BOTH.
  14. ¿Por qué PROCESSES rechaza el cambio en memoria aunque v$parameter lo marque IMMEDIATE?
Porque el parámetro PROCESSES define el número máximo de semáforos y estructuras que Oracle le pide al sistema operativo (Linux) en el momento de arrancar. Una vez arrancada la instancia, no se puede pedir más espacio al SO en caliente, por lo que exige un SCOPE=SPFILE y un reinicio para aplicarse.
  15. ¿Para qué sirve versionar el PFILE? Explica "configuration drift".
Servir el PFILE (formato texto) en Git nos permite tener un historial de qué parámetros han cambiado en el servidor a lo largo del tiempo. El "configuration drift" (deriva de configuración) ocurre cuando un DBA cambia parámetros en caliente en producción pero olvida documentarlos en el repositorio, haciendo que el código y la realidad diverjan y causando desastres si hay que recrear el servidor desde cero.
8.1.5. Memoria y procesos
  16. ¿Qué modelo de gestión de memoria usa tu instancia? Justifícalo con tres parámetros.
Usa ASMM (Automatic Shared Memory Management). Se justifica porque MEMORY_TARGET = 0 (lo que desactiva el modelo superior AMM), SGA_TARGET tiene un valor mayor a cero (activando ASMM), y parámetros como DB_CACHE_SIZE pueden tener un valor definido que Oracle tratará como un mínimo garantizado, autoajustando el resto.
  17. Explica las cifras de tu experimento de caché: lecturas lógicas, físicas y tasa de acierto.
En la primera ejecución (lectura en frío), hubo lecturas físicas altas porque Oracle tuvo que ir al disco mecánico/SSD a buscar los bloques, logrando una tasa de acierto baja en caché. En la segunda ejecución (lectura en caliente), las lecturas físicas fueron cero porque todos los bloques ya estaban en la memoria RAM (Buffer Cache), logrando lecturas 100% lógicas y una tasa de acierto total, siendo la consulta casi instantánea.
  18. ¿Por qué no se suma el RSS de los procesos para saber la memoria de la instancia?
Porque el RSS (Resident Set Size) que muestra Linux incluye partes de memoria compartida (SGA) que están mapeadas en ese proceso. Si sumamos el RSS de los 59 procesos, estaríamos sumando la misma SGA 59 veces, dando un resultado irreal de gigabytes que no refleja el consumo real del servidor. (Evidencia: El proceso db_lgwr_FREE marcaba 99 MB de RSS, en gran parte correspondientes a la SGA compartida).
  19. Relaciona el SPID de LGWR de v$process con el PID de /proc. ¿Por qué docker top muestra otro número?
El SPID de Oracle corresponde exactamente al PID del sistema operativo Linux desde la perspectiva de dentro del contenedor. (Evidencia: El SPID del LGWR en 09-procesos.sql era 2128, y el script 09-procesos-so.sh confirmó que el PID Linux interno era también 2128). docker top muestra otro número porque lo ejecuta desde el host (tu máquina física), que mapea ese proceso a un espacio de nombres distinto con un PID host diferente.
  20. ¿Qué hace PMON y qué hace SMON? Pon un ejemplo de cada uno.
PMON (Process Monitor) limpia tras procesos fallidos; por ejemplo, si un usuario apaga su PC de golpe sin hacer commit, PMON detecta que la conexión murió, hace rollback y libera las filas bloqueadas. SMON (System Monitor) hace recuperación a nivel de sistema; por ejemplo, si se va la luz del servidor, al volver a arrancar, SMON lee los Redo Logs y arregla la base de datos automáticamente (crash recovery).
8.1.6. Seguridad y trabajo profesional
  21. ¿Por qué C##OPS_RO y no SYSTEM para observar? ¿Qué no puede hacer C##OPS_RO?
Por el principio de mínimo privilegio. SYSTEM tiene poder absoluto y un error tecleando podría borrar datos de negocio. C##OPS_RO es un perfil de Solo Lectura. No puede insertar, borrar datos, modificar esquemas, ni otorgar privilegios a otros, lo que lo hace perfecto y seguro para monitorización.
  22. ¿Qué dos vías de exposición de contraseñas corrige este laboratorio respecto al Lab 3?
Corrige la exposición en el código fuente de los scripts SQL (evitando guardar texto plano usando IDENTIFIED BY VALUES o bloqueando las cuentas en V003), y corrige la exposición de variables de entorno en el repositorio ignorando el archivo config/.env mediante .gitignore para que no se suba a GitHub.
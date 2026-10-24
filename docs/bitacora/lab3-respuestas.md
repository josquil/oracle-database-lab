**1. ¿Qué diferencia hay entre una imagen y un contenedor? Usa como ejemplo lo que hiciste en los ejercicios G2 y G4.**
Una imagen es la plantilla de solo lectura (como una receta), mientras que el contenedor es la instancia viva en ejecución de esa imagen (el plato cocinado). En el G2 (`hello-world`), usamos una imagen que arrancó un contenedor, imprimió un mensaje y terminó. En el G4 (`alpine`), entramos de forma interactiva a un contenedor vivo basado en esa imagen base.

**2. En el Ejercicio G5 el archivo nota.txt desapareció y en el G6 no. Explica por qué.**
En el G5, el archivo se escribió dentro del sistema de archivos temporal del contenedor, el cual se destruye por completo al borrar el contenedor con `docker rm`. En el G6, el archivo se guardó en un volumen persistente gestionado por Docker, que sobrevive de forma independiente al ciclo de vida del contenedor.

**3. ¿Qué diferencia hay entre docker ps y docker ps -a, y qué significa STATUS = Exited (0)?**
`docker ps` muestra únicamente los contenedores que están en marcha, mientras que `docker ps -a` muestra todos los contenedores (incluyendo los detenidos). `STATUS = Exited (0)` significa que el contenedor terminó su proceso principal de forma normal y sin errores.

**4. En -p 8181:8181, ¿qué número corresponde a tu equipo y cuál al contenedor? ¿Qué pasaría con -p 80:8080 en el ejercicio de nginx?**
El primer número (izquierda) es el puerto del equipo anfitrión (host) y el segundo (derecha) es el del contenedor. Si pusiéramos `-p 80:8080`, estaríamos enviando el tráfico de nuestro puerto 80 al puerto 8080 del contenedor, y como nginx escucha en el puerto 80, la página no cargaría.

**5. ¿Por qué un contenedor de Oracle se queda en marcha y el de hello-world termina solo?**
Un contenedor vive exactamente el mismo tiempo que vive su proceso principal. `hello-world` ejecuta un proceso que imprime texto y finaliza, mientras que Oracle mantiene el motor de base de datos corriendo en segundo plano indefinidamente, por lo que el contenedor no se detiene.

**6. ¿Qué es el digest de una imagen y por qué lo registramos si ya sabemos que usamos :latest?**
El digest es la huella digital única e inmutable (sha256) de una versión concreta de la imagen. Lo registramos como evidencia porque la etiqueta `:latest` va cambiando con el tiempo, y guardar el digest es la única forma de garantizar la reproducibilidad y saber exactamente qué versión exacta se instaló hoy.

**7. ¿Qué comando borraría realmente los datos de Oracle? ¿Por qué docker rm oralab-26ai no lo hace?**
El comando que borraría los datos es `docker volume rm oralab-26ai-data`. Hacer `docker rm oralab-26ai` solo borra el contenedor (el proceso), pero gracias a que montamos un volumen en `/opt/oracle/oradata`, los datos viven fuera del contenedor y no se ven afectados por su borrado.

**8. ¿Por qué este laboratorio se hace dentro del repositorio oracle-database-lab, con Issue, branch y Pull Request, en vez de en una carpeta aparte?**
Porque en un entorno profesional la preparación de la infraestructura se trata como cualquier otro cambio de código versionado. Hacerlo en el repositorio mantiene el historial, la protección de la rama `main` y asegura que todo el proceso (scripts y evidencias) quede documentado, revisable y reproducible por cualquier otro compañero.

**9. ¿Qué diferencia hay entre source 00-config.sh y bash 00-config.sh? ¿Por qué usamos source?**
Ejecutar `bash script.sh` abre una terminal "hija" que se cierra al terminar, perdiendo todas las variables creadas. Usamos `source` porque ejecuta el script en nuestra terminal actual, permitiendo que las variables (como los nombres y puertos) queden guardadas en memoria y disponibles para los siguientes comandos.

**10. Explica cada parte del nombre 20260915T091230Z_02-docker.script.log.**
- `20260915T091230Z`: Es la marca de tiempo: año(2016), mes (09), día (15), hora (09), minutos (12), segundos (30) y tipo de horario UTC (z).
- `02`: Es el número exacto del paso.
- `docker`: Descripción breve en formato kebab-case(sin espacios ni tildes.
- `script.log`: El sufijo que indica una salida de la terminal.

**11. ¿Para qué sirve .gitattributes y qué error evita?**
Sirve para decirle a Git que normalice los finales de línea automáticamente al formato de Linux (LF) para todos los usuarios. Esto evita que scripts editados en Windows (que usa CRLF) fallen al ejecutarse en el contenedor Linux con errores extraños como `$'\r': command not found`.

**12. ¿Por qué en este Pull Request elegimos Create a merge commit en lugar de Squash and merge?**
Porque en este laboratorio cada commit corresponde a una parte diferente y tiene valor por sí mismo (demuestra cuándo y cómo se verificó cada herramienta). Usar un *merge commit* clásico conserva todo ese historial paso a paso, mientras que *squash* lo aplastaría todo en un solo mensaje gigante perdiendo el detalle.

**13. Describe las cuatro capas de la estrategia de contraseñas (Parte D) y qué pasaría si te saltas la primera.**
Las cuatro capas son:
1. Añadir el archivo a `.gitignore` para que Git no lo rastree.
2. Crear una plantilla versionada sin contraseñas reales (`.env.example`).
3. Crear el archivo local real (`config/.env`) que Git nunca verá.
4. Cargar las variables en memoria con `source` en lugar de escribirlas en la terminal.
Si te saltas la primera capa, el archivo con tu contraseña real se subiría al repositorio de GitHub, quedando expuesto para siempre, lo que en una empresa es un incidente grave de seguridad.

**14. ¿Por qué no escribimos la contraseña directamente en el comando docker run, aunque el script no se suba a Git?**
Porque todo lo que tecleamos se guarda automáticamente en el archivo de historial de la terminal (`~/.bash_history`) en texto plano. Usando una variable como `$ORACLE_PWD`, en el historial solo queda registrado el nombre de la variable y no el secreto real.

**15. Si descubres tu contraseña en un commit ya publicado, ¿basta con borrarla en un commit nuevo? ¿Qué debes hacer?**
No basta con borrarla, porque cualquiera podría recuperarla navegando hacia atrás en el historial de Git. Lo que se debe hacer es cambiarla inmediatamente (rotar el secreto) recreando el contenedor con una nueva contraseña y avisar al responsable para que limpie la rama si es necesario.

**16. ¿Por qué no usamos SPOOL ni @archivo.sql con sqlplus dentro del contenedor, y qué hicimos en su lugar?**
No usamos `SPOOL` porque escribiría el archivo dentro del sistema de archivos aislado del contenedor (y no en nuestro repositorio). Tampoco usamos `@archivo.sql` porque buscaría ese archivo dentro del contenedor, donde no existe. En su lugar, usamos redirección de entrada `<` para enviarle el archivo desde nuestro equipo, y `tee` para guardar la salida en nuestro repositorio.

**17. ¿Qué hace WHENEVER SQLERROR EXIT SQL.SQLCODE al inicio de V000 y V001, y qué pasaría sin esa linea?**
Hace que si cualquier sentencia SQL falla, el script se detenga inmediatamente en ese punto devolviendo un código de error. Sin esta línea, `sqlplus` ignoraría el error y seguiría ejecutando el resto de las instrucciones sobre un entorno roto o a medias, lo que podría causar datos inconsistentes.

**18. ¿Qué es una migración y por qué V000 y V001 no se deben editar una vez aplicadas?**
Una migración es un script SQL versionado y numerado que sirve para llevar la base de datos de un estado al siguiente de forma ordenada. No se deben editar porque ya han sido aplicadas a la base de datos; si necesitamos corregir o añadir algo, la práctica profesional es crear una nueva migración (como V002).

**19. ¿Por qué en SQL Developer se usa el servicio FREEPDB1 y no FREE ni un SID?**
Se usa `FREEPDB1` porque es el servicio directo de la base de datos conectable (PDB) de trabajo, donde realmente vamos a crear nuestras tablas y usuarios. Usar el servicio `FREE` o un SID nos conectaría al contenedor raíz de la base de datos (CDB), que está reservado solo para tareas de administración global.

**20. ¿Qué aporta SQLcl frente a SQL*Plus, y por qué un DBA debe dominar ambas?**
SQLcl aporta comodidades modernas como autocompletado, historial de comandos, formato automático de tablas (como `ansiconsole`) y conexiones guardadas. Un DBA profesional debe dominar ambas porque, aunque SQLcl es mejor para el día a día, SQL*Plus viene instalado por defecto en absolutamente todos los servidores Oracle del mundo, y es la herramienta de emergencia cuando no hay otra cosa disponible.

**21. ¿Por qué el curso pasa de Git Bash a Ubuntu en WSL 2? Da al menos dos problemas concretos de Git Bash que desaparecen en Ubuntu.**
Pasamos a Ubuntu porque la infraestructura empresarial real (como Docker y Oracle) corre sobre Linux, y WSL 2 nos da un entorno nativo sin capas de emulación. Dos problemas concretos de Git Bash que desaparecen son: 1) Git Bash traduce las rutas como `/opt/...` a rutas de Windows y rompe los comandos de Docker. 2) No incluye utilidades básicas de administración de sistemas como `free`, `ss` o `htop`.

**22. ¿Por qué clonamos el repositorio en ~/oracle-database-lab y no trabajamos sobre la carpeta de Windows (/mnt/c/...)? ¿y por qué recomendamos bash frente a zsh para los scripts del curso?**
Clonamos en Linux (`~`) porque trabajar sobre el disco de Windows cruzando sistemas de archivos hace que Docker y Git vayan muy lentos, se pierden los permisos de ejecución de Linux y reaparecen los problemas con los finales de línea. Recomendamos `bash` porque es el estándar por defecto en la inmensa mayoría de servidores; escribir los scripts en `bash` garantiza que funcionarán exactamente igual en tu equipo que en producción.

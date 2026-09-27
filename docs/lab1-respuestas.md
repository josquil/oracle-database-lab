1. ¿Cuál es la diferencia entre Working Directory, Staging Area y Local Repository? Da un ejemplo de unarchivo pasando por las tres.
Working Directory: es la carpeta donde editamos los archivos.
Staging Area: puntero a exactamente qué archivos irán en el próximo guardado.
Local Repository: es el archivo histórico, la carpeta .git donde se guardan los commits.

2. Si modificas un archivo pero no haces git add, ¿aparece ese cambio en tu próximo commit? Explica porqué.
No, ese cambio no aparecerá en el próximo commit. El comando git commit únicamente confirma lo que ya está metido en la Staging Area. Si no se hace git add antes, el archivo se queda como sin preparar y git lo ignorará al crear el commit.

3. ¿Por qué git status no mostraba las carpetas vacías que creaste en la Parte C? ¿Qué truco usamos parasolucionarlo?
No salían en git solo versiona archivos no las carpetas. Por eso lo de .gitkeep dentro de la carpeta para forzarlo.

4. Explica con tus palabras qué es HEAD.
El HEAD nos dice en qué commit estamos y en qué rama estamos.

5. ¿Qué diferencia hay entre crear una branch con git switch -c y crear una carpeta nueva con mkdir?¿Cómo lo comprobamos en la Parte G?
Mkdir crea una carpeta nueva. En cambio, git switch -c crea una rama , y una rama no es una carpeta, sino el historial de commits dentro de la infraestructura de .git.Lo comprobamos en el ejercicio G porque, al crear la nueva rama y hacer ls -la, estaban exactamente los mismos archivos  y directorios de antes, sin ninguna carpeta nueva.


6. Durante el conflicto de la Parte H, ¿qué representaba el contenido entre <<<<<<< HEAD y =======? ¿Yentre ======= y >>>>>>>?
El bloque debajo de < < < < HEAD y hasta ===== representaba la versión del código que ya teníamos nosotros en nuestra rama actual main. El contenido entre ==== y > > > fix/readme-subtitle era la versión que venía de la otra rama que estábamos intentado fusionar.
7. ¿Por qué NO se debe hacer git commit --amend sobre un commit que ya se subió con git push?
Porque –amend hace desaparecer el commit anterior y crea uno nuevo con un hash diferente. Si ese commit ya lo habíamos subido a GitHub con git push, otro desarrollador podría habérselo descargado; al cambiar nosotros el historial provocamos una divergencia.
8. Si borras por accidente la carpeta .git de tu proyecto, ¿qué se pierde exactamente? ¿Se pierde tambiénel código fuente que está en el disco?
Si borramos la carpeta .git, perdemos toda la infraestructura de git: se borra el historial de versiones, los commits,las ramas, configuración. Pero no perdemos el código fuente ni los archivos del proyecto, estos siguen en Working Directory.
9. Explica con tus propias palabras la diferencia entre Git y GitHub, sin usar la palabra "nube".
Git es el programa local de control de versiones, se encuentra en nuestro sistema. GitHub es una plataforma que aloja repositorios de Git y de coolaboración.
10. ¿Por qué no se debe subir un archivo .env con contraseñas reales a un repositorio, aunque elrepositorio sea privado?
Porque nunca se deben subir archivos privados. Si subimos claves de apis quedarán registradas de forma permanente con los commits. Aunque sea privado, cualquier desarrollador con acceso (o si se hace público) tendría acceso a esas credenciales. Usamos .gitignore antes del primer commit.


11. Un compañero te dice: "hice push y ahora GitHub me rechaza el segundo push con 'non-fast-forward'". ¿Qué ha ocurrido probablemente y qué comando ejecutarías primero?
Lo que ha ocurrido es que en el repositorio de github hay nuevos commits que otro desarrollador aún no tiene en local, si hizo cambios desde la propia web o si otro subió código. El primer comando que tiene que ejecutar es git pull para traerselo todo, después ya podrá hacer su git push.

12. ¿Qué tipo de Conventional Commit (feat, fix, docs, test…) usarías para: añadir un índice derendimiento a una tabla, corregir una restricción mal definida, y actualizar el README?
Añadir un índice de rendimiento a una tabla: perf mejora de rendimiento.
Corregir una restricción mal definida: fix corrige un error.
Actualizar el README: docs cambios solo en documentación.

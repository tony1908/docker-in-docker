# Docker Compose Dentro De Docker

Este proyecto crea una imagen de Docker para que los alumnos puedan ejecutar `docker` y `docker compose` dentro de un contenedor.

La idea es que el alumno no necesite instalar Docker Compose directamente en su máquina. En su lugar, entra a este contenedor y desde ahí ejecuta los comandos de Docker y Docker Compose.

## Cómo Funciona

La imagen está basada en `docker:dind`, que significa Docker-in-Docker.

Cuando el contenedor arranca:

1. Se inicia un daemon de Docker dentro del contenedor usando `dockerd`.
2. El script de entrada espera hasta que Docker esté listo.
3. El alumno entra a una terminal dentro del contenedor.
4. Desde esa terminal puede ejecutar `docker`, `docker compose`, `docker build`, `docker run`, etc.

El flujo queda así:

```text
Máquina del alumno
  -> contenedor del curso
    -> Docker daemon interno
      -> contenedores creados por docker compose
```

Importante: como el contenedor necesita levantar su propio Docker daemon, debe ejecutarse con `--privileged`.

## Construir La Imagen

```bash
docker build -t docker-compose-in-docker:local .
```

También puedes usar:

```bash
make build
```

## Probar Que Funciona

```bash
docker run --rm --privileged docker-compose-in-docker:local docker compose version
```

O con el ejemplo incluido:

```bash
make check
```

Ese comando arranca el contenedor, verifica Docker, verifica Docker Compose y ejecuta el archivo `examples/hello/compose.yaml`.

El ejemplo levanta dos servicios:

- `db`: una base de datos PostgreSQL.
- `alpine`: un contenedor Alpine que instala el cliente de PostgreSQL y ejecuta una consulta contra `db`.

La salida esperada incluye algo como:

```text
Docker Compose version v5.1.3
alpine-1  | Alpine conectado a PostgreSQL
alpine-1  |     resultado
alpine-1  | ------------------
alpine-1  |  compose funciona
alpine-1  | (1 row)
alpine-1 exited with code 0
```

## Entrar Al Entorno Del Curso

```bash
docker run --rm -it --privileged \
  -v "$PWD:/workspace" \
  docker-compose-in-docker:local
```

También puedes usar:

```bash
make shell
```

Dentro del contenedor puedes ejecutar:

```bash
docker version
docker compose version
docker compose -f examples/hello/compose.yaml up --abort-on-container-exit --exit-code-from alpine
```

## Usar Tus Propios Archivos Compose

El comando anterior monta la carpeta actual en `/workspace`:

```bash
-v "$PWD:/workspace"
```

Eso permite que el alumno trabaje con los archivos del curso desde dentro del contenedor.

Por ejemplo, si tienes un archivo `compose.yaml` en la raíz del proyecto:

```bash
docker compose up
```

Si está en otra carpeta:

```bash
docker compose -f ruta/al/compose.yaml up
```

## Archivos Del Proyecto

- `Dockerfile`: define la imagen con Docker, Docker Compose, Bash, Git y Make.
- `entrypoint.sh`: inicia el Docker daemon interno y después ejecuta el comando solicitado.
- `Makefile`: comandos cortos para construir, probar y abrir una terminal.
- `examples/hello/compose.yaml`: ejemplo con Alpine y PostgreSQL para comprobar que Docker Compose funciona.

## Notas Para El Curso

- Este entorno es para prácticas y desarrollo, no para producción.
- El contenedor debe ejecutarse con `--privileged`.
- Los contenedores e imágenes creados dentro del entorno viven dentro del Docker daemon interno.
- Si borras el contenedor principal, también se borra el estado interno de Docker.
- Para conservar archivos del curso, móntalos con `-v "$PWD:/workspace"`.

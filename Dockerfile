# Imagen del contenedor que ejecuta tu código
FROM ubuntu:latest

RUN apt-get update \
    && apt-get install -y curl

RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata

RUN apt-get install jq -y

RUN apt-get install git -y

# Copias tu archivo de código de tu repositorio de acción a la ruta `/`del contenedor
COPY entrypoint.sh /entrypoint.sh

# Archivo del código a ejecutar cuando comienza el contedor del docker (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
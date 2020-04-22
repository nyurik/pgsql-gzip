FROM debian:latest

# These dependencies are needed regardless of the PostgreSQL version
# Use a separate layer to speed up the build
RUN set -eux  ;\
    DEBIAN_FRONTEND=noninteractive apt-get update -qq  ;\
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        fakeroot \
        pkg-config \
        debhelper \
        devscripts \
        zlib1g-dev \
        curl

# This argument will usually be set by the Makefile. Override example:
#  make deb-docker PG_MAJOR=11
ARG PG_MAJOR=12

RUN set -eux  ;\
    echo "**************************"  ;\
    echo " Building for PG_MAJOR=$PG_MAJOR"  ;\
    echo "**************************"  ;\
    curl --silent --show-error --location https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -  ;\
    sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(. /etc/os-release; echo $VERSION_CODENAME)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'  ;\
    DEBIAN_FRONTEND=noninteractive apt-get update -qq  ;\
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        postgresql-server-dev-$PG_MAJOR

WORKDIR /build/pgsql-gzip

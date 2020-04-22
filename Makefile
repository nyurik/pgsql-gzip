# Make sure we do not run any code when using deb-* target
ifeq (,$(findstring deb-,$(MAKECMDGOALS)))

# Detect pkg-config on the path
PKGCONFIG := $(shell type -p pkg-config || echo NONE)

ifeq ($(PKGCONFIG), NONE)
# Hard code paths if necessary
ZLIB_PATH = /usr
ZLIB_INC = -I$(ZLIB_PATH)/include
ZLIB_LIB = -L$(ZLIB_PATH)/lib -lz
else
# Use pkg-config to detect zlib if possible
ZLIB_INC = $(shell pkg-config zlib --cflags)
ZLIB_LIB = $(shell pkg-config zlib --libs)
endif

#DEBUG = 1

# These should not require modification
MODULE_big = gzip
OBJS = pg_gzip.o
EXTENSION = gzip
DATA = gzip--1.0.sql
REGRESS = gzip
EXTRA_CLEAN =

PG_CONFIG = pg_config

CFLAGS += $(ZLIB_INC)
LIBS += $(ZLIB_LIB)
SHLIB_LINK := $(LIBS)

ifdef DEBUG
COPT += -O0 -g
endif

PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

endif


.PHONY: deb
deb: clean
	pg_buildext updatecontrol
	dpkg-buildpackage -B

# Name of the PostgreSQL to build for
PG_MAJOR ?= 12

.PHONY: deb-docker
deb-docker:
	@echo "*** Using PG_MAJOR=$(PG_MAJOR)"
	docker build "--build-arg=PG_MAJOR=$(PG_MAJOR)" -t pgsql-gzip-$(PG_MAJOR) .
	# Create a temp dir that we will remove later. Otherwise docker will create a root-owned dir.
	mkdir -p "$$(pwd)/target/pgsql-gzip"
	docker run --rm -ti -u $$(id -u $${USER}):$$(id -g $${USER}) -v "$$(pwd)/target:/build" -v "$$(pwd):/build/pgsql-gzip" pgsql-gzip-$(PG_MAJOR) make deb
	rmdir "$$(pwd)/target/pgsql-gzip" || true

# A few helpers. These could probably be simplified with the makefile magic, but probably not worth it
.PHONY: deb-10
deb-10: PG_MAJOR=10
deb-10: deb-docker

.PHONY: deb-11
deb-11: PG_MAJOR=11
deb-11: deb-docker

.PHONY: deb-12
deb-12: PG_MAJOR=12
deb-12: deb-docker

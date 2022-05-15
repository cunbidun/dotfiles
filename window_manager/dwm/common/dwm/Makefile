# dwm version
VERSION = 6.3

# paths
PREFIX = /usr/local
MANPREFIX = ${PREFIX}/share/man

X11INC = /usr/X11R6/include
X11LIB = /usr/X11R6/lib

# Xinerama, comment if you don't want it
XINERAMALIBS  = -lXinerama
XINERAMAFLAGS = -DXINERAMA

# freetype
FREETYPELIBS = -lfontconfig -lXft
FREETYPEINC = /usr/include/freetype2

# This is needed for the swallow patch
XCBLIBS = -lX11-xcb -lxcb -lxcb-res

# Imlib2 (tag previews)
IMLIB2LIBS = -lImlib2

# includes and libs
INCS = -I${X11INC} -I${FREETYPEINC} -Iinclude -I.
LIBS = -L${X11LIB} -lX11 ${XINERAMALIBS} ${FREETYPELIBS} ${IMLIB2LIBS} ${XCBLIBS} ${KVMLIB}

# flags
CPPFLAGS = -D_DEFAULT_SOURCE -D_BSD_SOURCE -D_POSIX_C_SOURCE=200809L -DVERSION=\"${VERSION}\" ${XINERAMAFLAGS}
CFLAGS   = -std=c99 -pedantic -Wall -Wno-deprecated-declarations -Os ${INCS} ${CPPFLAGS}
LDFLAGS  = ${LIBS}

# compiler and linker
CC = cc

SRC = $(wildcard src/*.c)
OBJ = ${SRC:src/%.c=obj/%.o}

all: dwm

dwm: ${OBJ}
	${CC} -o $@ ${OBJ} ${LDFLAGS}

obj/%.o: src/%.c $(wildcard include/*.h)
	${CC} -c ${CFLAGS} $< -o $@

clean:
	rm -f dwm ${OBJ} 

install: all
	mkdir -p ${DESTDIR}${PREFIX}/bin
	cp -f dwm ${DESTDIR}${PREFIX}/bin
	chmod 755 ${DESTDIR}${PREFIX}/bin/dwm
	mkdir -p ${DESTDIR}${MANPREFIX}/man1
	sed "s/VERSION/${VERSION}/g" < docs/dwm.1 > ${DESTDIR}${MANPREFIX}/man1/dwm.1
	chmod 644 ${DESTDIR}${MANPREFIX}/man1/dwm.1

uninstall:
	rm -f ${DESTDIR}${PREFIX}/bin/dwm\
		${DESTDIR}${MANPREFIX}/man1/dwm.1

.PHONY: all clean install uninstall

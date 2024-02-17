# dwm - dynamic window manager
# See LICENSE file for copyright and license details.

include config.mk

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

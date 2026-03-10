# Top-level Makefile for Lua-Pro and LuaJIT

.PHONY: all pro jit clean

all: pro

pro:
	cd lua && $(MAKE) generic

jit:
	cd luajit && $(MAKE)

clean:
	cd lua && $(MAKE) clean
	cd luajit && $(MAKE) clean
	rm -f *.o

# To build Luajava with a specific engine:
# make luajava ENGINE=lua
# make luajava ENGINE=luajit
luajava:
	@if [ "$(ENGINE)" = "luajit" ]; then \
		echo "Building Luajava with LuaJIT..."; \
		cd luajava && $(CC) -shared -fPIC -o libluajava.so luajava.c -I../luajit/src -L../luajit/src -lluajit; \
	else \
		echo "Building Luajava with Pro VM..."; \
		cd luajava && $(CC) -shared -fPIC -o libluajava.so luajava.c -I../lua -L../lua -llua; \
	fi

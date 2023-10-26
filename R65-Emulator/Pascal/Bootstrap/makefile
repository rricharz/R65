
all: compile load

compile: compile.c
	gcc -o compile compile.c
	
load: load.c load.h runtime.c runtime.h bootstrap.c
	gcc -o load load.c runtime.c bootstrap.c

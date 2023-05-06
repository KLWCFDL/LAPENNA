IEL_HOME=../../..
include $(IEL_HOME)/Makefile.inc

CFLAGS   = -Wall
CLIBS    = -lm  -lz -ldl
INCLUDES=$(MACH_INC) $(R_INC)

static: libmodexec.a
 
libmodexec.a: modexec.c
	$(MPICC) -c $(INCLUDES) modexec.c
	ar -rcs libmodexec.a modexec.o

clean:
	rm -f *.o *.a  

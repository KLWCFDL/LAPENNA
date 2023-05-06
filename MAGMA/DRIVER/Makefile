IEL_HOME=../../..
include $(IEL_HOME)/Makefile.inc

CFLAGS   = -Wall
OMP      = -fopenmp
CLIBS    = -lm  -lz -ldl
CLIBS-AM = -L../MODULE-FILE -lmodexec
INCLUDES=$(MACH_INC) -I../MODULE-FILE
LDFLAGS=$(MACH_LIB) $(LIBCONFIG_LIB) $(CLIBS) 

all:    driverAM

driverAM: 
	$(MPICC) $(CFLAGS) $(INCLUDES)  -c driverAM.c 
	$(MPICC) $(OMP) -o driverAM driverAM.o  $(LDFLAGS) $(CLIBS-AM)
clean:
	rm -rf *.o driverAM Timers

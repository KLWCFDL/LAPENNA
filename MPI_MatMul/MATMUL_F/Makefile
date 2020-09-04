
FFLAGS = -g -Wall

matmul_F.a: matmul_F.c mpi_mm.f
	$(MPICC) -c $(INCLUDES) $(LIB) $(CFLAGS) matmul_F.c
	$(MPIF90) -c $(INCLUDES) $(FFLAGS) mpi_mm.f
	ar -rcs libmatmul_F.a matmul_F.o mpi_mm.o

mpi_mm.o: mpi_mm.f
	$(MPIF90) -c $(INCLUDES) $(FFLAGS) mpi_mm.f

matmul_F.o: matmul_F.c
	$(MPICC) -c $(INCLUDES) $(CFLAGS) matmul_F.c

clean:
	rm -f *.a *.o *.mod


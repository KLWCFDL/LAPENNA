/************************************************************************
 * This file has been written as a sample solution to an exercise in a
 * course given at the Edinburgh Parallel Computing Centre. It is made
 * freely available with the understanding that every copy of this file
 * must include this header and that EPCC takes no responsibility for
 * the use of the enclosed teaching material.
 * Authors:     Joel Malard, Alan Simpson
 * Contact:     epcc-tec@epcc.ed.ac.uk
 * Contents:    C source code.
 *
 * NOTE:
 * This file has been altered by Asim YarKhan of the Joint Institute for
 * Computational Science (jics@jics.utk.edu) for an MPI workshop.
 ************************************************************************/
/************************************************************************
 * Write an MPI "hello World!" program using the appropriate MPI calls.
 ************************************************************************/

#include        <stdio.h>
#include        <mpi.h>

int main(int argc, char *argv[])
{
  int rank, size;

  /* Initialize MPI */
  MPI_Init(&argc, &argv);
  
  /* Find out my rank in the global communicator MPI_COMM_WORLD*/
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);

  /* Insert code to do conditional work if my rank is 0 */
  if(rank == 0){
    printf("Hello World (from masternode)\n");

  } else{

  /* Insert code to print the output message "Hello World"*/
  printf("Hello WORLD!!! (from worker node)\n");

  }
  /* Exit and finalize MPI */
  MPI_Barrier(MPI_COMM_WORLD);
  MPI_Finalize();

  

}/* End Main */



        PROGRAM hello
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
C This file has been written as a sample solution to an exercise in a 
C course given at the Edinburgh Parallel Computing Centre. It is made
C freely available with the understanding that every copy of this file
C must include this header and that EPCC takes no responsibility for
C the use of the enclosed teaching material.
C Authors:    Alan Simpson, Joel Malard
C Contact:    epcc-tec@epcc.ed.ac.uk
C
C NOTE:        
C This file has been altered by Asim YarKhan of the Joint Institute for
C Computational Science (jics@jics.utk.edu) for an MPI workshop.
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

        IMPLICIT NONE

        include "mpif.h"

        INTEGER ierror, rank, size

C       Initialize MPI 
        CALL MPI_INIT(ierror)

C       Find out my rank in the global communicator MPI_COMM_WORLD
        CALL MPI_COMM_RANK(MPI_COMM_WORLD, rank, ierror)
C *-->  Insert code to do conditional work if my rank is 0 
        IF (rank.EQ.0) THEN

          WRITE(*,*)'Hello World (from the masternode)'

        ELSE

C *-->  Insert code to print the output message "Hellow World"
        WRITE(*,*) 'Hello WORLD!!! (from one of the workers)'
        END IF

C       Exit and finalize MPI 
        CALL MPI_FINALIZE(ierror)

        STOP
        END


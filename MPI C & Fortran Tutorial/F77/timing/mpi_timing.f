C--------------------------------------------------------------------->
C MPI Timing Program - FORTRAN Version
C FILE: mpi_timing.f
C DESCRIPTION:  MPI timing example code.  FORTRAN version.
C   In this example code, an MPI communication timing test is
C   The processor with mypid = 0 will send integer messages of
C   "length" elements to the processor with mypid = 1 "REPS" times.
C   Upon receiving the message a message of identical size is sent
C   back.Before and after timings are made for each rep and an 
C   average calculated when completed.  Also the Bandwidth is 
C   calculated.
C LAST REVISED: 3/15/99 Travis Kerr - for JICS Workshop
C--------------------------------------------------------------------->

      program timing
      include 'mpif.h'

c      IMPLICIT NONE

      external timing_fgettod

      integer REPS,MAXLENGTH
      parameter(REPS = 20)
      parameter(MAXLENGTH = 1000000)

      integer i,n,length
      integer inmsg(MAXLENGTH),outmsg(MAXLENGTH)
      integer mypid,mysize,ierr
      integer status(MPI_STATUS_SIZE)
      
      double precision start,finish,time
      double precision bw

C  *------------------->
C *---> Initialize MPI
C  *------------------->

      call MPI_INIT(ierr)

C  *--------------------------------------------------------->
C *---> Get my rank in the MPI_COMM_WORLD communicator group
C  *--------------------------------------------------------->

      call MPI_COMM_RANK(MPI_COMM_WORLD,mypid,ierr )

C  *---------------------------------------------------------->
C *---> Get the size of the MPI_COMM_WORLD communicator group
C  *---------------------------------------------------------->

      call MPI_COMM_SIZE(MPI_COMM_WORLD,mysize,ierr )

      if (mysize.ne.2) then
       print *, 'Error: Check environment variable MP_PROCS'
       go to 999
      endif

      length = 1

C  *------------------------------>
C *---> Synchronize the processes
C  *------------------------------>

      call MPI_BARRIER(MPI_COMM_WORLD,ierr)

C  *---------------------->
C *---> Task 0 processing
C  *---------------------->

      if (mypid.eq.0) then

       do 15 i=1,4

       time = 0.0e0

C  *--------------------------->
C *---> Round-trip timing test
C  *--------------------------->
       print *, ' '
       print *, ' '
       print *, 'Doing round trip test for:'
       print *, 'Message length = ',length,' integer value(s)'
       print *, 'Message size   = ',4*length,' Bytes'
       print *, 'Number of Reps = ',REPS

       start = MPI_WTIME()

       do 10 n=1,REPS

C  *------------------------------>
C *---> Send message to process 1
C  *------------------------------>

        call MPI_SEND(outmsg(1),length,MPI_INTEGER,1,0,MPI_COMM_WORLD,
     +                ierr)

C  *----------------------------------------------------->
C *---> Now wait to receive the ech reply from process 1
C  *----------------------------------------------------->

        call MPI_RECV(inmsg(1),length,MPI_INTEGER,1,0,MPI_COMM_WORLD,
     +                status,ierr)

   10  continue
        
       finish = MPI_WTIME()
       
C  *--------------------------------------------------------------->
C *---> Calculate round trip time average and bandwidth, and print
C  *--------------------------------------------------------------->

       time = finish - start

       write (*,100) time/REPS
  100  format ('*** Round Trip Avg = ',f8.6,'Sec')

        bw = 2.0*REPS*4.0*length/time

       write (*,110) bw
  110  format ('*** Approximate Bandwidth = ',f18.6,' Byte/Sec')

       write (*,120) bw*8/1000000
  120  format ('                          = ',f12.6,' Megabit/Sec')

       length = 100*length

   15  continue
      endif

C  *------------------------>
C *---> Task one processing
C  *------------------------>

      if (mypid .eq. 1) then
        do 35 i=1,4
        do 40 n=1, REPS

C  *----------------------------------->
C *---> Receive message from process 0
C  *----------------------------------->

         call MPI_RECV(inmsg(1),length,MPI_INTEGER,0,0,MPI_COMM_WORLD,
     +                 status,ierr)

C  *-------------------------------->
C *---> Return message to process 0
C  *-------------------------------->

         call MPI_SEND(outmsg(1),length,MPI_INTEGER,0,0,MPI_COMM_WORLD,
     +                 ierr )
  40    continue   

        length = 100*length

  35    continue

      endif

C  *----------------->
C *---> Finalize MPI
C  *----------------->

999   call MPI_FINALIZE(ierr)
      end

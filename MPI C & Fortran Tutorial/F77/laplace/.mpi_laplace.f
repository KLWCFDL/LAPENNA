**********************************************************
* Laplace Eqn 
* T is initially 0.0 everywhere except at boundaries where T=100.
*
*          T=100.0
*       _________                    ____|____|____|____    Y
*	|	|                   |    |    |    |    |   |
*	|	|                   |    |    |    |    |   |
* T=100.| T=0.0 | T=100.0           | 1  | 2  | 3  | 4  |   |
*	|	|                   |    |    |    |    |   |
*	|_______|                   |    |    |    |    |   |_______X
*         T=100.0                   |____|____|____|____|
*                                        |    |    |
* Use Central Differencing Method
* Each process only has subgrid.
* Each Processor works on a sub grid and then sends its
* Boundaries to neighbours
*
* /mpp/bin/cft77 laplace.par.f
* /mpp/bin/mppldr -lpvm3 -olap.par laplace.par.o
*
* Susheel Chitre PSC.... Feb 1994
***********************************************************

      program serial
      implicit none

      integer    NPROC,   NR,      NC,      NCL,          MXITER
      parameter (NPROC=4, NR=1000, NC=1000, NCL=NC/NPROC, MXITER=1000)

      integer    LEFT,     RIGHT,     ROOT
      parameter (LEFT=100, RIGHT=101, ROOT=0)

      include    'mpif.h'

      real*8     t(0:NR+1,0:NCL+1), told(0:NR+1,0:NCL+1), dt, dtg
      integer    i, j, iter, niter, mype, npes, ierr
      integer    status(MPI_STATUS_SIZE)

      call system('hostname')

      call MPI_Init(ierr)

      call MPI_Comm_size(MPI_COMM_WORLD, npes, ierr)
      call MPI_Comm_rank(MPI_COMM_WORLD, mype, ierr)

      call initialize( t )
      call set_bcs( t, mype, npes )

      do i=0, NR+1
         do j=0, NCL+1
            told(i,j) = t(i,j)
         enddo
      enddo

      if( mype .eq. ROOT ) then
         print*, 'How many iterations [100-1000]?'
         read*,   niter
         if( niter.gt.MXITER ) niter = MXITER
      endif
      
      call MPI_Bcast(niter, 1, MPI_INTEGER, ROOT, MPI_COMM_WORLD, ierr)
*
* Do Computation on Sub-grid for Niter iterations
*
************************************************************************
      Do 100 iter=1,niter
         
         Do j=1,NCL
            Do i=1,NR
               T(i,j) = 0.25 * ( Told(i+1,j)+Told(i-1,j)+
     $                           Told(i,j+1)+Told(i,j-1) )
            Enddo
         Enddo
*
* Copy
*
         dt = 0
         Do j=1,NCL
            Do i=1,NR
               dt        = max( abs(t(i,j) - told(i,j)), dt )
               Told(i,j) = T(i,j)
            Enddo
         Enddo

*
* Send data
*
         if (mype .lt. npes-1)
     ^      call MPI_Send(T(1,NCL), NR, MPI_REAL, mype+1, RIGHT,
     ^                                   MPI_COMM_WORLD, ierr)
         if (mype .ne. 0)
     ^      call MPI_Send(T(1,1  ), NR, MPI_REAL, mype-1, LEFT,
     ^                                   MPI_COMM_WORLD, ierr)
*
* Receive data
*
         if (mype .ne. 0)
     ^      call MPI_Recv(T(1,0),     NR, MPI_REAL, MPI_ANY_SOURCE,
     ^                             RIGHT, MPI_COMM_WORLD, status, ierr)
         if (mype .ne. npes-1)
     ^      call MPI_Recv(T(1,NCL+1), NR, MPI_REAL, MPI_ANY_SOURCE,
     ^                              LEFT, MPI_COMM_WORLD, status, ierr)

	write(6,3) iter, mype, dt, dtg

         call MPI_Reduce(dt, dtg, 1, MPI_REAL, MPI_MAX, ROOT,
     ^                                    MPI_COMM_WORLD, ierr)
	if(mype .eq. ROOT) then
	write(6,4) iter, mype, dt, dtg
	endif
*
* Print some Values
*
         If( mod(iter,100).eq.0 ) then
            if( mype.eq.0 ) then
               write(6,1) iter, mype, T(10,10), dtg
            endif
c
c            call barrier
c
c            if( mype.eq.npes-1 ) then
c               write(6,2) iter, mype, T(10,NCL-9)
c            endif
         endif

         call MPI_Barrier( MPI_COMM_WORLD, ierr )
*
* Go to Next time step
*
 100  CONTINUE

      call MPI_Finalize(ierr)

 1    format('Iter = ',i5,' PE = ',I4,' T(10,10)    = ',f20.8,
     ^       '  dt   = ',e10.3)
 2    format('Iter = ',i5,' PE = ',I4,' T(10,NCL-9) = ',f20.8)
 3    format('before reduce Iter = ',i5,' PE = ',I4,' dt  = ' ,e10.3,
     ^       '  dtg   = ',e10.3)
 4    format('after reduce Iter = ',i5,' PE = ',I4,' dt  = ' ,e10.3,
     ^       '  dtg   = ',e10.3)
*
* End of Program!
*
      END
*----------------------------------------------------------------------*
      subroutine initialize( t )
      implicit none

      integer    NPROC,   NR,      NC,      NCL,          MXITER
      parameter (NPROC=4, NR=1000, NC=1000, NCL=NC/NPROC, MXITER=1000)

      real*8     t(0:NR+1,0:NCL+1), told(0:NR+1,0:NCL+1)
      integer    i, j

      do i=0, NR+1
         do j=0, NCL+1
            t(i,j) = 0
         enddo
      enddo
      
      return

      end
*----------------------------------------------------------------------*
      subroutine set_bcs( t, mype, npes )
      implicit none

      integer    NPROC,   NR,      NC,      NCL,          MXITER
      parameter (NPROC=4, NR=1000, NC=1000, NCL=NC/NPROC, MXITER=1000)

      real*8     t(0:NR+1,0:NCL+1), told(0:NR+1,0:NCL+1)
      integer    i, j, mype, npes
*
*Left and Right Boundaries
*
      if( mype.eq.0 ) then
         do i=0,NR+1
            T(i,0    ) = 100.0
         enddo
      endif

      if( mype.eq.npes-1 ) then
         do i=0,NR+1
            T(i,NCL+1) = 100.0
         enddo
      endif
*
*Top and Bottom Boundaries
*
      do j=0,NCL+1
         T(0   ,j) = 100.0
         T(NR+1,j) = 100.0
      enddo

      return

      end

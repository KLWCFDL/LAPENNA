/**************************************************************************
* MPI Timing Program - C Version
* FILE: mpi_timing.c
* DESCRIPTION:  MPI timing example code.  C version.
*   In this example code, an MPI communication timing test is performed.
*   The processor with mypid = 0 will send integer messages of
*   "length" elements to the processor with mypid = 1 "REPS" times.
*   Upon receiving the message a message of identical size is sent
*   back.Before and after timings are made for each rep and an 
*   average calculated when completed.  Also the Bandwidth is 
*   calculated.
* LAST REVISED: 3/15/99 Travis Kerr - for JICS Workshop
**************************************************************************/

#include "mpi.h"
#include <stdio.h>
#include <sys/time.h>
#include <time.h>
#include <stdlib.h> 

#define	REPS 1000
#define MAXLENGTH 8000000

int main(argc,argv)
int argc;
char *argv[];

{
 int i,n,length;
 int *inmsg, *outmsg;
 int rtt, artt;
 int mypid,mysize;
 int rc;
 double start,finish,time;
 double bw;
 MPI_Status status;

   /*----------------*/
  /* Initialize MPI */
 /*----------------*/

 rc = MPI_Init(&argc,&argv);

   /*-------------------------------------------------------*/
  /* Get the size of the MPI_COMM_WORLD communicator group */
 /*-------------------------------------------------------*/

 rc|= MPI_Comm_size(MPI_COMM_WORLD,&mysize);

   /*------------------------------------------------------*/
  /* Get my rank in the MPI_COMM_WORLD communicator group */
 /*------------------------------------------------------*/

 rc|= MPI_Comm_rank(MPI_COMM_WORLD,&mypid);

 if (mysize != 2)
 {
  fprintf(stderr, "Error: Set environment variable MP_PROCS to 2\n");
  exit(1);
 }

 length = 1;
 inmsg = (int *) malloc(MAXLENGTH*sizeof(int));
 outmsg = (int *) malloc(MAXLENGTH*sizeof(int));

   /*---------------------------*/
  /* synchronize the processes */
 /*---------------------------*/

 rc = MPI_Barrier(MPI_COMM_WORLD);

   /*-------------------*/
  /* Task 0 processing */
 /*-------------------*/

 if (mypid == 0)
 {

    for (i=1; i<=4; i++)
    {

    time = 0.0000000000000;

   /*------------------------*/
  /* round-trip timing test */
 /*------------------------*/

     printf("\n\nDoing round trip test for:\n");
     printf("Message length = %d integer value(s)\n",length);
     printf("Message size   = %d Bytes\n",4*length);
     printf("Number of Reps = %d\n",REPS);


     start = MPI_Wtime();

     for (n=1; n<=REPS; n++)
     {

   /*---------------------------*/
  /* send message to process 1 */
 /*---------------------------*/

      rc = MPI_Send(&outmsg[0],length,MPI_INT,1,0,MPI_COMM_WORLD);

   /*---------------------------------------------------*/
  /* Now wait to receive the echo reply from process 1 */
 /*---------------------------------------------------*/

      rc = MPI_Recv(&inmsg[0],length,MPI_INT,1,0,MPI_COMM_WORLD,&status);

     }

     finish = MPI_Wtime();

   /*------------------------------------------------------------*/
  /* Calculate round trip time average and bandwidth, and print */
 /*------------------------------------------------------------*/

      time = finish - start;

      printf("*** Round Trip Avg = %f uSec\n", time/REPS);

      bw = 2.0*REPS*4.0*length/time;

      printf("*** Bandwidth = %f Byte/Sec\n",bw);
      printf("              = %f Megabit/Sec\n",bw*8.0/1000000.0);

      length = 100*length;

    } 
 }

   /*-------------------*/
  /* Task 1 processing */
 /*-------------------*/

 if (mypid == 1)
 {
    for (i=1; i<=4; i++)
    {

     for (n=1; n<=REPS; n++)
     {

   /*--------------------------------*/
  /* receive message from process 0 */
 /*--------------------------------*/

      rc = MPI_Recv(&inmsg[0],length,MPI_INT,0,0,MPI_COMM_WORLD,&status);

   /*-----------------------------*/
  /* return message to process 0 */
 /*-----------------------------*/

      rc = MPI_Send(&outmsg[0],length,MPI_INT,0,0,MPI_COMM_WORLD);
     }

     length = 100*length;

    }

 }

   /*--------------*/
  /* Finalize MPI */
 /*--------------*/

   MPI_Finalize();
   exit(0);
}

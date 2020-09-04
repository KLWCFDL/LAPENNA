/*------------------------------------------------------------------------
  MPI Example - Array Assignment - C Version
  FILE: mpi_array.c
  OTHER FILES: make.mpi_array.c
  DESCRIPTION: 
    In this simple example, the master task initiates numtasks-1 number of
    worker tasks.  It then distributes an equal portion of an array to each
    worker task.  Each worker task receives its portion of the array, and 
    performs a simple value assignment to each of its elements. The value 
    assigned to each element is simply that element's index in the array+1.
    Each worker task then sends its portion of the array back to the master
    task.  As the master receives back each portion of the array, selected 
    elements are displayed. 
  AUTHOR: Blaise Barney. Converted to MPI: George L. Gusciora (1/25/95)
  LAST REVISED: 12/14/95 Blaise Barney
-------------------------------------------------------------------------*/

#include "XXXXX" 		  /* Required MPI library */
#include <stdio.h>

#define	ARRAYSIZE	60000
#define MASTER		0         /* taskid of first process */

int main(argc,argv)
int argc;
char *argv[];
{
int	numtasks,           /* total number of MPI tasks in partition */
	numworkers,         /* number of worker tasks */
	taskid,	            /* task identifier */
	rc,                 /* return error code */
	dest,               /* destination task id to send message */
	index,              /* index into the array */
	i,                  /* loop variable */
   	arraymsg = 1,       /* setting a message type */
   	indexmsg = 2,       /* setting a message type */
	source,             /* origin task id of message */
	chunksize;          /* for partitioning the array */
float	data[ARRAYSIZE],    /* the intial array */
	result[ARRAYSIZE];  /* for holding results of array operations */
MPI_Status status;

/*------------------------ initializations -------------------------------
  Find out how many tasks are in this partition and what my task id is.
  Then define the number of worker tasks and the array partition size as
  chunksize. 
  Note:  For this example, the MP_PROCS environment variable should be set
  to an odd number...to insure even distribution of the array to numtasks-1
  worker tasks.
-------------------------------------------------------------------------*/

   /*-----------------*/
  /*  Initialize MPI */
 /*-----------------*/

   rc = XXXXXXXX(&argc,&argv);

   /*--------------------------------------------*/
  /*  Determine size of the global communicator */   
 /*--------------------------------------------*/

   rc|= XXXXXXXXXXXXX(XXXXXXXXXXXXXX,&numtasks);

   /*--------------------------------------------*/
  /*  Determine rank in the global communicator */   
 /*--------------------------------------------*/

   rc|= XXXXXXXXXXXXX(MPI_COMM_WORLD,XXXXXXX);

   if (rc != 0)
    printf ("error initializing MPI and obtaining task ID information\n");

   numworkers = numtasks-1;
   chunksize = (ARRAYSIZE / numworkers);

/**************************** master task ********************************/

   if (taskid == MASTER)
   {
      printf("\n*********** Starting MPI Example 1 ************\n");
      printf("MASTER: number of worker tasks will be= %d\n",numworkers);
      fflush(stdout);

   /*----------------------*/
  /* Initialize the array */
 /*----------------------*/

      for(i=0; i<ARRAYSIZE; i++) 
         data[i] =  0.0;
      index = 0;

   /*------------------------------------------------*/
  /* Send each worker task its portion of the array */
 /*------------------------------------------------*/

      for (dest=1; dest<= numworkers; dest++) 
      {
         printf("Sending to worker task %d\n",dest);
         fflush(stdout);

    /*--------------------------------------------------------------*/
   /* Send index value so that each processor knows where to start */
  /* in the data array.                                           */
 /*--------------------------------------------------------------*/

         XXXXXXXX(&index, X, XXXXXXX, dest, XXXXXXXX, XXXXXXXXXXXXXX);

    /*-----------------------------------------------------------*/
   /* Send each process a chunksize bit of data starting at the */
  /* index position.                                           */
 /*-----------------------------------------------------------*/

         MPI_XXXX(&data[XXXXX], XXXXXXXXX, MPI_FLOAT, dest, XXXXXXXX,
                  MPI_COMM_WORLD);
         index = index + chunksize;
      }

    /*------------------------------------------------------------*/
   /* Wait to receive back the results from each worker task and */
  /* print a few sample values.                                 */
 /*------------------------------------------------------------*/

      for (i=1; i<= numworkers; i++)
      {
         source = i;

    /*-----------------------------------------------------------*/
   /* Receive index value so that master knows which portion of */
  /* the results array the following data will be stored in.   */ 
 /*-----------------------------------------------------------*/

         MPI_XXXX(XXXXXX, 1, MPI_INT, XXXXXX, indexmsg, XXXXXXXXXXXXXX,
                  XXXXXXX);

   /*----------------------------------------*/
  /* Receive chunksize of the results array */
 /*----------------------------------------*/

         MPI_XXXX(XXXXXXX[index], XXXXXXXXX, XXXXXXXXX, source, arraymsg,
                  XXXXXXXXXXXXXX, &status);

   /*---------------------------------*/
  /* Print some sample result values */
 /*---------------------------------*/

         printf("---------------------------------------------------\n");
         printf("MASTER: Sample results from worker task = %d\n",source);
         printf("   result[%d]=%f\n", index, result[index]);
         printf("   result[%d]=%f\n", index+100, result[index+100]);
         printf("   result[%d]=%f\n\n", index+1000, result[index+1000]);
         fflush(stdout);
      }
      printf("MASTER: All Done! \n");
   }

/**************************** worker task ********************************/

   if (taskid > MASTER)
   {

      source = MASTER;

    /*------------------------------------------------------------------*/
   /* Receive index value from the master indicating start position in */
  /* data array.                                                      */
 /*------------------------------------------------------------------*/

      MPI_XXXX(XXXXXX, 1, MPI_INT, XXXXXX, indexmsg, MPI_COMM_WORLD,
               XXXXXXX);

   /*-------------------------------------------------*/
  /* Receive chunksize bit of data starting at index */
 /*-------------------------------------------------*/

      MPI_XXXX(&result[XXXXX], chunksize, XXXXXXXXX, source, XXXXXX,
               XXXXXXXXXXXXXX, &status);

   /*-----------------------------------------------------------*/
  /* Do a simple value assignment to each of my array elements */
 /*-----------------------------------------------------------*/

      for(i=index; i < index + chunksize; i++)
         result[i] = i + 1;

      dest = MASTER;

    /*------------------------------------------------------------------*/
   /* Send index value so that master knows which portion of data each */
  /* process was working on.                                          */ 
 /*------------------------------------------------------------------*/

      MPI_XXXX(&index, X, MPI_INT, XXXX, indexmsg, MPI_COMM_WORLD);

   /*-----------------------------------------------*/
  /* Send chunksize bit of results back to master  */
 /*-----------------------------------------------*/

      MPI_Send(XXXXXXX[index], XXXXXXXXX, MPI_FLOAT, XXXXXX, arraymsg,
               XXXXXXXXXXXXXX);
   }

   /*--------------*/
  /* Finalize MPI */
 /*--------------*/

   MPI_XXXXXXXX();
}

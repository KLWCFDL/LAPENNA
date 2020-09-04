  /**********************************************************/
 /* Example provided by Cornell University *****************/
/**********************************************************/

#include <stdio.h>
#include <sched.h>
#include "omp.h"
int main(int argc, char **argv) {
  int processor_name_len; 

omp_set_num_threads(2);
#pragma omp parallel
  {
     printf("Team member %d reporting from team of %d. CPU %d\n",
            omp_get_thread_num(),omp_get_num_threads(), sched_getcpu() );
  }

  printf("Master thread finished, goodbye.\n");

  return 0;
}

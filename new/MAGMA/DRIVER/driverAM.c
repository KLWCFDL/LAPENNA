/*
 * Copyright (c) 2015 University of Tennessee
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "IEL.h"
#include "libconfig.h"
#include "IEL_exec_info.h"
#include "modexec.h"
#include "tuple_server.h"

#define MOD_STRING_LENGTH 20

void ConfigFile(void);

int main(int argc, char* argv[])
{
  int rc, rank, num_modules, i, size;
  char mod_name[MOD_STRING_LENGTH];
  config_t cfg;
  config_setting_t *setting;

  MPI_Init(&argc, &argv);
  MPI_Comm_rank(MPI_COMM_WORLD,&rank);
  MPI_Comm_size(MPI_COMM_WORLD,&size);

  // ----------------- Timer ---------------------
  timestamp ("Begin", "driver.c", 1);
  // ----------------- Timer ---------------------

  IELAddModule(ielTupleServer, "ielTupleServer");

  if(rank == 0) {
    config_init(&cfg);
    if(argc < 2) {
      fprintf(stderr, "IEL ERROR: No config file specified\n");
      MPI_Abort(MPI_COMM_WORLD, 1);
    }

    if(!config_read_file(&cfg, argv[1])) {
      fprintf(stderr, "IEL ERROR: Cannot read config file [%s[\n", argv[1]);
      MPI_Abort(MPI_COMM_WORLD, 1);
    }

    if((setting = config_lookup(&cfg, "modules")) == NULL) {
      fprintf(stderr, "IEL ERROR: No modules entry in config file [%s]\n", argv[1]);
      MPI_Abort(MPI_COMM_WORLD, 1);
    }
    num_modules = config_setting_length(setting);

    MPI_Bcast(&num_modules, 1, MPI_INT, 0, MPI_COMM_WORLD);
  } else {

    MPI_Bcast(&num_modules, 1, MPI_INT, 0, MPI_COMM_WORLD);

  }

  for(i = 0; i < num_modules; i++) {
    snprintf(mod_name, MOD_STRING_LENGTH, "MODULE-%d", i);
    IELAddModule(&modexec, mod_name);
  }

  MPI_Barrier(MPI_COMM_WORLD);
  rc = IELExecutive(MPI_COMM_WORLD,argv[1]);

  // ----------------- Timer ---------------------
  timestamp ("End", "driver.c", -1);
  timer_finalize (rank);
  // ----------------- Timer ---------------------

  MPI_Finalize();

  return rc;
}


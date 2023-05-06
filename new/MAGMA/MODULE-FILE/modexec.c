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

#include"modexec.h"
#include"IEL_exec_info.h"
#include<unistd.h>
#include<stdlib.h>

extern char** environ;

int modexec(IEL_exec_info_t *exec_info) {
  int PID, status;
  int ret;
  int argc = IEL_ARGC(exec_info);
  char **argv = IEL_ARGV(exec_info);

  if(argc == 0) {
    fprintf(stderr, "IEL_EXEC: No file specified for exec.\n"
                    "IEL_EXEC: Check configuration file args array.\n"
                    "IEL_EXEC: Doing nothing...\n");
    return IEL_SUCCESS;
  }

  if((PID = fork()) == 0) {
    //child

    argv[argc] = NULL;
    ret = execvpe(argv[0], argv, environ);
    perror("execvpe");
    exit(1);
  } else {
    DBG("Hello from parent");
    //parent
    while(wait(&status) != PID);

    if(status == 0) {
      DBG("openDriverAM: SUCCESSFUL RUN [%s], Exit Code [%d], IN RANK ID - (%d) : DIR - (%d)", \
          argv[0], status, exec_info->IEL_rank, exec_info->module_rank);
    } else {
      printf(" =====> openDriverAM: FAILED run [%s] terminated with Exit code [%d], IN RANK ID - (%d) : DIR - (%d) \n", \
          argv[0], status, exec_info->IEL_rank, exec_info->module_rank);
    }
    fflush(stdout);
  }
  return IEL_SUCCESS;
}



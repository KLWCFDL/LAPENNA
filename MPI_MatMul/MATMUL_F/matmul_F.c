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

#include "IEL_exec_info.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern void fortran_routine(IEL_fort_info_t *finfo);

int matmul_F(IEL_exec_info_t *exec_info) {
  int i;
  IEL_fort_info_t *finfo = malloc(sizeof(IEL_fort_info_t));
  *finfo = reduceFortInfo(exec_info);
  fortran_routine(finfo);
  IEL_fort_info_finalize(finfo);

  return IEL_SUCCESS;
}

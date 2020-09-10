#include <stdio.h>

/*
 * A simple introduction to programming in CUDA. This program prints "Hello
 * World from GPU! from 10 CUDA threads running on the GPU.
 */

/*
 The qualifier "__global__" tells the compiler that the function will be called
 from the CPU and executed on the GPU
*/
__global__ void helloFromGPU()
{ /**/
  printf("Hello World from GPU!\n");
}

int main(int argc, char **argv)
{
  printf("Hello World from CPU!\n");

  helloFromGPU<<<1, 10>>>();

  cudaDeviceReset();
  return 0;
}

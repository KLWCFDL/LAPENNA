#include <stdio.h>

/*
 * This program performs scalar addition "a+b=c" on the GPU.
 */

__global__ void add(int *a, int *b, int *c)
{ /**/
  *c = *a + *b;
}

int main(void)
{
  int a, b, c;           // host copies of a, b, c
  int *d_a, *d_b, *d_c;  // memory locations of device copies of a, b, c
  int size = sizeof(int);

  // Allocate space for device copies of a, b, c
  cudaMalloc((void **)&d_a, size);
  cudaMalloc((void **)&d_b, size);
  cudaMalloc((void **)&d_c, size);

  // Setup input values
  a = 2;
  b = 7;
  // Copy inputs to device
  cudaMemcpy(d_a, &a, size, cudaMemcpyHostToDevice);
  cudaMemcpy(d_b, &b, size, cudaMemcpyHostToDevice);
  // Launch add() kernel on GPU
  add<<<1, 1>>>(d_a, d_b, d_c);
  // Copy result back to host
  cudaMemcpy(&c, d_c, size, cudaMemcpyDeviceToHost);

  // Cleanup
  cudaFree(d_a);
  cudaFree(d_b);
  cudaFree(d_c);

  printf("%i + %i = %i\n", a, b, c);

  return 0;
}

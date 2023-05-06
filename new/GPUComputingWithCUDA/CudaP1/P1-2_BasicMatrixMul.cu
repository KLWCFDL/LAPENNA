#include <stdio.h>

#define N 10

/*
 * This example helps to visualize the relationship between thread/block IDs and
 * offsets into data. For each CUDA thread, this example displays the
 * intra-block thread ID, the inter-block block ID, the global coordinate of a
 * thread, the calculated offset into input data, and the input data at that
 * offset.
 */

__global__ void matrixMult(int *a, int *b, int *c, int width)
{
  int k, sum = 0;
  int col = threadIdx.x + blockDim.x * blockIdx.x;
  int row = threadIdx.y + blockDim.y * blockIdx.y;
  if (col < width && row < width) {
    for (k = 0; k < width; k++)
      sum += a[row * width + k] * b[k * width + col];
    c[row * width + col] = sum;
  }
}

int main()
{
  int a[N][N], b[N][N], c[N][N];
  int *dev_a, *dev_b, *dev_c;
  int size = N * N * sizeof(int);

  cudaMalloc((void **)&dev_a, size);
  cudaMalloc((void **)&dev_b, size);
  cudaMalloc((void **)&dev_c, size);

  cudaMemcpy(dev_a, a, size, cudaMemcpyHostToDevice);
  cudaMemcpy(dev_b, b, size, cudaMemcpyHostToDevice);

  dim3 dimGrid(1, 1);
  dim3 dimBlock(N, N);

  matrixMult<<<dimGrid, dimBlock>>>(dev_a, dev_b, dev_c, N);
  cudaMemcpy(c, dev_c, size, cudaMemcpyDeviceToHost);

  cudaFree(dev_a);
  cudaFree(dev_b);
  cudaFree(dev_c);
}

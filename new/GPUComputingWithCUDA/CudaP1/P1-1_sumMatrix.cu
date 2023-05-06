#include <stdio.h>

/*
 * This example demonstrates a simple vector sum on the GPU and on the host.
 * sumArraysOnGPU splits the work of the vector sum across CUDA threads on the
 * GPU. A 2D thread block and 2D grid are used. sumArraysOnHost sequentially
 * iterates through vector elements on the host.
 */

/*Initializes a random array of floats*/
void initialData(float *ip, const int size)
{
  int i;

  for (i = 0; i < size; i++) {
    ip[i] = (float)(rand() & 0xFF) / 10.0f;
  }

  return;
}

/*Sums two matricies on CPU to check the GPU results*/
void sumMatrixOnHost(float *A, float *B, float *C, const int nx, const int ny)
{
  float *ia = A;
  float *ib = B;
  float *ic = C;

  for (int iy = 0; iy < ny; iy++) {
    for (int ix = 0; ix < nx; ix++) {
      ic[ix] = ia[ix] + ib[ix];
    }

    ia += nx;
    ib += nx;
    ic += nx;
  }

  return;
}

/*determines if two floats are within epsilon of each other*/
void checkResult(float *hostRef, float *gpuRef, const int N)
{
  double epsilon = 1.0E-8;
  bool match = 1;

  for (int i = 0; i < N; i++) {
    if (abs(hostRef[i] - gpuRef[i]) > epsilon) {
      match = 0;
      printf("host %f gpu %f\n", hostRef[i], gpuRef[i]);
      break;
    }
  }

  if (match)
    printf("Arrays match.\n\n");
  else
    printf("Arrays do not match.\n\n");
}

// sums a portion of the matrix on the GPU given it's thread id
__global__ void sumMatrixOnGPU2D(float *MatA, float *MatB, float *MatC, int nx,
                                 int ny)
{
  unsigned int ix = threadIdx.x + blockIdx.x * blockDim.x;
  unsigned int iy = threadIdx.y + blockIdx.y * blockDim.y;
  unsigned int idx = iy * nx + ix;

  if (ix < nx && iy < ny)
    MatC[idx] = MatA[idx] + MatB[idx];
}

int main(int argc, char **argv)
{
  printf("%s Starting...\n", argv[0]);

  // set up device
  int dev = 0;
  cudaDeviceProp deviceProp;
  cudaGetDeviceProperties(&deviceProp, dev);
  printf("Using Device %d: %s\n", dev, deviceProp.name);
  cudaSetDevice(dev);

  // set up data size of matrix
  int nx = 1 << 14;
  int ny = 1 << 14;

  int nxy = nx * ny;
  int nBytes = nxy * sizeof(float);
  printf("Matrix size: nx %d ny %d\n", nx, ny);

  // malloc host memory
  float *h_A, *h_B, *hostRef, *gpuRef;
  h_A = (float *)malloc(nBytes);
  h_B = (float *)malloc(nBytes);
  hostRef = (float *)malloc(nBytes);
  gpuRef = (float *)malloc(nBytes);

  // initialize data at host side
  initialData(h_A, nxy);
  initialData(h_B, nxy);

  memset(hostRef, 0, nBytes);
  memset(gpuRef, 0, nBytes);

  // add matrix at host side for result checks
  sumMatrixOnHost(h_A, h_B, hostRef, nx, ny);

  // malloc device global memory
  float *d_MatA, *d_MatB, *d_MatC;
  cudaMalloc((void **)&d_MatA, nBytes);
  cudaMalloc((void **)&d_MatB, nBytes);
  cudaMalloc((void **)&d_MatC, nBytes);

  // transfer data from host to device
  cudaMemcpy(d_MatA, h_A, nBytes, cudaMemcpyHostToDevice);
  cudaMemcpy(d_MatB, h_B, nBytes, cudaMemcpyHostToDevice);

  // invoke kernel at host side
  int dimx = 32;
  int dimy = 32;
  dim3 block(dimx, dimy);
  dim3 grid((nx + block.x - 1) / block.x, (ny + block.y - 1) / block.y);

  sumMatrixOnGPU2D<<<grid, block>>>(d_MatA, d_MatB, d_MatC, nx, ny);
  cudaDeviceSynchronize();
  // check kernel error
  cudaGetLastError();

  // copy kernel result back to host side
  cudaMemcpy(gpuRef, d_MatC, nBytes, cudaMemcpyDeviceToHost);

  // check device results
  checkResult(hostRef, gpuRef, nxy);

  // free device global memory
  cudaFree(d_MatA);
  cudaFree(d_MatB);
  cudaFree(d_MatC);

  // free host memory
  free(h_A);
  free(h_B);
  free(hostRef);
  free(gpuRef);

  // reset device
  cudaDeviceReset();

  return (0);
}

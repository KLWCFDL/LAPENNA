
#include "image_io.h"
#include <cassert>
#include <cstdlib>
#include <cudnn.h>
#include <iostream>

/*The implementation of a basic convolution operation with cuDNN
 *reference:http://www.goldsborough.me/cuda/ml/cudnn/c++/2017/10/01/14-37-23-convolutions_with_cudnn/
 *https://gist.github.com/goldsborough/865e6717e64fbae75cdaf6c9914a130d
 */

#define checkCUDNN(expression)                               \
  {                                                          \
    cudnnStatus_t status = (expression);                     \
    if (status != CUDNN_STATUS_SUCCESS) {                    \
      std::cerr << "Error on line " << __LINE__ << ": "      \
                << cudnnGetErrorString(status) << std::endl; \
      std::exit(EXIT_FAILURE);                               \
    }                                                        \
  }

int main(int argc, const char *argv[])
{
  if (argc < 2) {
    std::cerr << "usage: conv <image> [gpu=0] [sigmoid=0]" << std::endl;
    std::exit(EXIT_FAILURE);
  }

  int gpu_id = (argc > 2) ? std::atoi(argv[2]) : 0;
  std::cerr << "GPU: " << gpu_id << std::endl;

  bool with_sigmoid = (argc > 3) ? std::atoi(argv[3]) : 0;
  std::cerr << "With sigmoid: " << std::boolalpha << with_sigmoid << std::endl;

  int width, height, c;
  float *image = read_image(argv[1], &c, &height, &width);

  cudaSetDevice(gpu_id);

  cudnnHandle_t cudnn;
  cudnnCreate(&cudnn);

  cudnnTensorDescriptor_t input_descriptor;
  checkCUDNN(cudnnCreateTensorDescriptor(&input_descriptor));
  checkCUDNN(cudnnSetTensor4dDescriptor(input_descriptor,
                                        /*format=*/CUDNN_TENSOR_NCHW,
                                        /*dataType=*/CUDNN_DATA_FLOAT,
                                        /*batch_size=*/3,
                                        /*channels=*/3,
                                        /*image_height=*/height,
                                        /*image_width=*/width));

  cudnnFilterDescriptor_t kernel_descriptor;
  checkCUDNN(cudnnCreateFilterDescriptor(&kernel_descriptor));
  checkCUDNN(cudnnSetFilter4dDescriptor(kernel_descriptor,
                                        /*dataType=*/CUDNN_DATA_FLOAT,
                                        /*format=*/CUDNN_TENSOR_NCHW,
                                        /*out_channels=*/3,
                                        /*in_channels=*/3,
                                        /*kernel_height=*/3,
                                        /*kernel_width=*/3));

  cudnnConvolutionDescriptor_t convolution_descriptor;
  checkCUDNN(cudnnCreateConvolutionDescriptor(&convolution_descriptor));
  checkCUDNN(cudnnSetConvolution2dDescriptor(convolution_descriptor,
                                             /*pad_height=*/1,
                                             /*pad_width=*/1,
                                             /*vertical_stride=*/1,
                                             /*horizontal_stride=*/1,
                                             /*dilation_height=*/1,
                                             /*dilation_width=*/1,
                                             /*mode=*/CUDNN_CROSS_CORRELATION,
                                             /*computeType=*/CUDNN_DATA_FLOAT));

  int batch_size{0}, out_channels{0}, out_height{0}, out_width{0};
  checkCUDNN(cudnnGetConvolution2dForwardOutputDim(
      convolution_descriptor, input_descriptor, kernel_descriptor, &batch_size,
      &out_channels, &out_height, &out_width));

  std::cerr << "Output Image: " << batch_size << " x " << out_height << " x "
            << out_width << " x " << out_channels << std::endl;

  cudnnTensorDescriptor_t output_descriptor;
  checkCUDNN(cudnnCreateTensorDescriptor(&output_descriptor));
  checkCUDNN(cudnnSetTensor4dDescriptor(output_descriptor,
                                        /*format=*/CUDNN_TENSOR_NCHW,
                                        /*dataType=*/CUDNN_DATA_FLOAT,
                                        /*batch_size=*/3,
                                        /*channels=*/3,
                                        /*image_height=*/out_height,
                                        /*image_width=*/out_width));

  cudnnConvolutionFwdAlgo_t convolution_algorithm;
  checkCUDNN(cudnnGetConvolutionForwardAlgorithm(
      cudnn, input_descriptor, kernel_descriptor, convolution_descriptor,
      output_descriptor, CUDNN_CONVOLUTION_FWD_PREFER_FASTEST,
      /*memoryLimitInBytes=*/0, &convolution_algorithm));

  size_t workspace_bytes{0};
  checkCUDNN(cudnnGetConvolutionForwardWorkspaceSize(
      cudnn, input_descriptor, kernel_descriptor, convolution_descriptor,
      output_descriptor, convolution_algorithm, &workspace_bytes));
  std::cerr << "Workspace size: " << (workspace_bytes / 1048576.0) << "MB"
            << std::endl;
  assert(workspace_bytes > 0);

  void *d_workspace{nullptr};
  cudaMalloc(&d_workspace, workspace_bytes);

  int image_bytes =
      batch_size * out_channels * out_height * out_width * sizeof(float);

  printf("batch size: %i\n", batch_size);

  float *d_input{nullptr};
  cudaMalloc(&d_input, image_bytes);
  cudaMemcpy(d_input, image, image_bytes, cudaMemcpyHostToDevice);

  float *d_output{nullptr};
  cudaMalloc(&d_output, image_bytes);
  cudaMemset(d_output, 0, image_bytes);

  // clang-format off
  float edges = -1;
  float corners = -1;
  const float kernel_template[3][3] = {
    {corners, edges, corners},
    {edges, 8, edges},
    {corners, edges, corners}
  };
  // clang-format on

  float h_kernel[3][3][3][3];
  for (int kernel = 0; kernel < 3; ++kernel) {
    for (int channel = 0; channel < 3; ++channel) {
      for (int row = 0; row < 3; ++row) {
        for (int column = 0; column < 3; ++column) {
          h_kernel[kernel][channel][row][column] = kernel_template[row][column];
        }
      }
    }
  }

  float *d_kernel{nullptr};
  cudaMalloc(&d_kernel, sizeof(h_kernel));
  cudaMemcpy(d_kernel, h_kernel, sizeof(h_kernel), cudaMemcpyHostToDevice);

  const float alpha = 1.0 / 3.0, beta = 0.0f;  // why do we need to divide by 3?

  checkCUDNN(cudnnConvolutionForward(
      cudnn, &alpha, input_descriptor, d_input, kernel_descriptor, d_kernel,
      convolution_descriptor, convolution_algorithm, d_workspace,
      workspace_bytes, &beta, output_descriptor, d_output));

  if (with_sigmoid) {
    cudnnActivationDescriptor_t activation_descriptor;
    checkCUDNN(cudnnCreateActivationDescriptor(&activation_descriptor));
    checkCUDNN(cudnnSetActivationDescriptor(
        activation_descriptor, CUDNN_ACTIVATION_SIGMOID, CUDNN_PROPAGATE_NAN,
        /*relu_coef=*/0));
    checkCUDNN(cudnnActivationForward(cudnn, activation_descriptor, &alpha,
                                      output_descriptor, d_output, &beta,
                                      output_descriptor, d_output));
    cudnnDestroyActivationDescriptor(activation_descriptor);
  }

  float *h_output = new float[image_bytes];
  cudaMemcpy(h_output, d_output, image_bytes, cudaMemcpyDeviceToHost);

  write_image(argv[1], h_output, out_channels, out_height, out_width);

  delete[] h_output;
  cudaFree(d_kernel);
  cudaFree(d_input);
  cudaFree(d_output);
  cudaFree(d_workspace);

  cudnnDestroyTensorDescriptor(input_descriptor);
  cudnnDestroyTensorDescriptor(output_descriptor);
  cudnnDestroyFilterDescriptor(kernel_descriptor);
  cudnnDestroyConvolutionDescriptor(convolution_descriptor);

  cudnnDestroy(cudnn);
}

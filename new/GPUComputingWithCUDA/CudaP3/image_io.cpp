#include "image_io.h"
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

using namespace std;

// image index
int get_i_index(int C, int H, int W, int c, int h, int w)
{
  return (h * W * C + w * C + c);
}

// tensor index
int get_t_index(int N, int C, int H, int W, int n, int c, int h, int w)
{
  return (c * N * H * W + n * H * W + h * W + w);  // cnhw why?
}

float clamp(float value)
{
  float max = 1.0;
  float min = 0.0;
  if (value > max)
    return max;
  if (value < min)
    return min;
  return value;
}

float *read_image(string file, int *C, int *H, int *W)
{
  unsigned int n, c, h, w;
  stbi_uc *i = stbi_load(file.c_str(), W, H, C, 3);

  float *f_i = (float *)malloc(3 * (*C) * (*H) * (*W) * sizeof(float));

  // make 3 copies of the image
  for (n = 0; n < 3; n++) {
    for (c = 0; c < *C; c++) {
      for (h = 0; h < *H; h++) {
        for (w = 0; w < *W; w++) {
          int t_index = get_t_index(3, *C, *H, *W, n, c, h, w);
          int i_index = get_i_index(*C, *H, *W, c, h, w);

          f_i[t_index] = i[i_index] / 255.0;
        }
      }
    }
  }

  free(i);
  return f_i;
}

void write_image(string file, float *pixels, int C, int H, int W)
{
  unsigned int n, c, h, w;

  for (n = 0; n < 3; n++) {
    unsigned char *i =
        (unsigned char *)malloc(C * H * W * sizeof(unsigned char));
    for (c = 0; c < C; c++) {
      for (h = 0; h < H; h++) {
        for (w = 0; w < W; w++) {
          int t_index = get_t_index(3, C, H, W, n, c, h, w);
          int i_index = get_i_index(C, H, W, c, h, w);

          i[i_index] = clamp(pixels[t_index]) * 255;
        }
      }
    }
    string file_n = file;
    file_n = file_n.substr(0, file_n.size() - 4);
    file_n.append("_out_" + to_string(n) + ".jpg");
    stbi_write_jpg(file_n.c_str(), W, H, C, i, 100);
    free(i);
  }
}
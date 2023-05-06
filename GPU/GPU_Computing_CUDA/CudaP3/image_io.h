#include <string>
#include <vector>

float *read_image(std::string file, int *width, int *height, int *n);

void write_image(std::string file, float *pixels, int width, int height, int n);
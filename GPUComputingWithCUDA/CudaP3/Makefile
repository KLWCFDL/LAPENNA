CUDADIR = /opt/cuda/

INC := -I$(CUDADIR)targets/x86_64-linux/include/ -I$(CUDADIR)include -I$(CUDADIR)samples/common/inc/
LIB := -L$(CUDADIR)lib -L$(CUDADIR)lib64

CPP_SRC_FILES := $(wildcard *.cpp)
CPP_SRC_FILES := $(filter-out image_io.cpp, $(CPP_SRC_FILES))
CPP_EXECUTABLES := $(patsubst %.cpp, %, $(CPP_SRC_FILES))
CU_SRC_FILES := $(wildcard *.cu)
CU_EXECUTABLES := $(patsubst %.cu, %, $(CU_SRC_FILES))

all: $(CPP_EXECUTABLES) $(CU_EXECUTABLES)

$(CPP_EXECUTABLES): $(CPP_SRC_FILES)

$(CU_EXECUTABLES): $(CU_SRC_FILES) image_io.o

%: %.cu
	nvcc -std=c++11 $(LIB) $(INC) image_io.o $< -o $@ -lcudnn 

image_io.o: image_io.cpp
	g++  -c image_io.cpp

%: %.cpp
	g++ $< $(LIB) $(INC) -o $@ -lcudart -lcudnn -lcublas

clean:
	rm -f $(CPP_EXECUTABLES) $(CU_EXECUTABLES) image_io.o *out*

SRC_FILES := $(wildcard *.cu)
EXECUTABLES := $(patsubst %.cu, %, $(SRC_FILES))

all: $(EXECUTABLES)

$(EXECUTABLES): $(SRC_FILES)

%: %.cu
	nvcc $< -o $@

clean:
	rm -f $(EXECUTABLES) 
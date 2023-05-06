default: testing_dgemm
build: download_magma build_magma

MAGMA_DIR=magma-2.4.0
MAGMA_EXAMPLES=$(MAGMA_DIR)/testing

download_magma: 
	./download_magma.sh	

build_magma: 
	@echo "#############################################"
	@echo "# Building MAGMA. This make take some time. #"
	@echo "#############################################"
	cp MAGMA-MAKE.INC/make.inc.mkl-gcc $(MAGMA_DIR)/make.inc
	cd $(MAGMA_DIR); make

testing_dgemm:
	@echo "##########################################"
	@echo "# Building MAGMA example 'testing_dgemm' #"
	@echo "##########################################"
	cd $(MAGMA_EXAMPLES); make testing_dgemm
	cp $(MAGMA_EXAMPLES)/testing_dgemm .

#!/bin/sh

download_link=http://icl.utk.edu/projectsfiles/magma/downloads/magma-2.4.0.tar.gz

if ! ls ./magma-2.4.0 1> /dev/null 2>&1; then
	echo "#####################################################"
	echo "# MAGMA-MODULE/download_magma.sh: Downloading Magma #"
	echo "#####################################################"
	wget $download_link
	echo "###################################################"
	echo "# MAGMA-MODULE/download_magma.sh: Untarring Magma #"
	echo "###################################################"
	tar -xf magma-2.4.0.tar.gz
	rm magma-2.4.0.tar.gz
else 
	echo "################################################################"
	echo "# MAGMA-MODULE/download_magma.sh: magma-2.3.0 directory found, #"
        echo "# skipping download step                                       #"
	echo "################################################################"
fi

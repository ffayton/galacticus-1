Bootstrap: ffayton
From: gcc10:latest

%environment
    export GALACTICUS_EXEC_PATH=/usr/local/galacticus/
    export GALACTICUS_DATA_PATH=/usr/local/galacticus_datasets

%post
    NOW=`date`
    echo "export NOW=\"${NOW}\"" >> $SINGULARITY_ENVIRONMENT
    
    # install FGSL v0.9.4
    cd /opt
    wget https://www.lrz.de/services/software/mathematik/gsl/fortran/download/fgsl-0.9.4.tar.gz
    tar -vxzf fgsl-0.9.4.tar.gz
    cd fgsl-0.9.4
    ./configure --gsl /usr --f90 gfortran --prefix /usr/local
    make
    make test
    make install

    # install HDF5 v1.8.20
    cd /opt
    wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.20/src/hdf5-1.8.20.tar.gz
    tar -vxzf hdf5-1.8.20.tar.gz
    cd hdf5-1.8.20
    F9X=gfortran ./configure --prefix=/usr/local --enable-fortran --enable-production
    make
    make install

    # install FoX v4.1.0
    cd /opt
    wget https://github.com/andreww/fox/archive/4.1.0.tar.gz
    tar xvfz 4.1.0.tar.gz
    cd fox-4.1.0
    ./configure
    make
    make install

    # install ANN 1.1.2 (optional)
    cd /opt
    wget http://www.cs.umd.edu/~mount/ANN/Files/1.1.2/ann_1.1.2.tar.gz
    tar xvfz ann_1.1.2.tar.gz
    cd ann_1.1.2
    make linux-g++
    cp bin/* /usr/local/bin/
    
    # install Galacticus
    export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib64:/usr/lib64:/usr/local/lib
    export GALACTICUS_EXEC_PATH=/usr/local/galacticus/
    export GALACTICUS_DATA_PATH=/usr/local/galacticus_datasets
    cd /usr/local
    git clone https://github.com/galacticusorg/galacticus.git
    git clone https://github.com/galacticusorg/datasets.git galacticus_datasets
    cd /usr/local/galacticus
    make -j2 Galacticus.exe

%labels
    Author ffayton@carnegiescience.edu
    Version v0.0.1

%help
    This is demo container used for Galacticus.

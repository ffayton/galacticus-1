Bootstrap: library
From: ffayton/default/gcc10:latest

%environment
    export PATH=/usr/local/bin:$PATH
    export LD_LIBRARY_PATH=/usr/local/lib64:/usr/local/lib:$LD_LIBRARY_PATH
    export GALACTICUS_EXEC_PATH=/usr/local/galacticus/
    export GALACTICUS_DATA_PATH=/usr/local/galacticus_datasets

%post
    NOW=`date`
    echo "export NOW=\"${NOW}\"" >> $SINGULARITY_ENVIRONMENT
    export PATH=/usr/local/bin:$PATH
    export LD_LIBRARY_PATH=/usr/local/lib64:/usr/local/lib:$LD_LIBRARY_PATH
    yum install -y fftw
    
    if [ "$(gfortran -dumpversion)" == "10.0.1" ] ; then echo "GCC-10 being used to compile" ; else exit 1; fi
    
    # install FGSL v0.9.4
    cd /opt
    wget https://www.lrz.de/services/software/mathematik/gsl/fortran/download/fgsl-0.9.4.tar.gz
    tar -vxzf fgsl-0.9.4.tar.gz
    cd fgsl-0.9.4
    ./configure --gsl /usr --f90 gfortran --cc gcc --prefix /usr/local --bits 64
    make clean
    make
    make test
    make install

    # install HDF5 v1.8.20
    cd /opt
    wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.20/src/hdf5-1.8.20.tar.gz
    tar -vxzf hdf5-1.8.20.tar.gz
    cd hdf5-1.8.20
    ./configure --prefix=/usr/local --enable-fortran --enable-production F90=gfortran FC=gfortran CC=gcc CXX=g++
    if [ "$(gfortran -dumpversion)" == "10.0.1" ] ; then echo yes; fi
    make clean
    make
    make install

    # install FoX v4.1.0
    cd /opt
    wget https://github.com/andreww/fox/archive/4.1.0.tar.gz
    tar xvfz 4.1.0.tar.gz
    cd fox-4.1.0
    ./configure --prefix=/usr/local FC=/usr/local/bin/gfortran CC=/usr/local/bin/gcc CXX=/usr/local/bin/g++ F90=/usr/local/bin/gfortran
    if [ "$(gfortran -dumpversion)" == "10.0.1" ] ; then echo yes; fi
    make clean 
    make
    make install
    
    # install FFTW 3.3.4 (optional)
    cd /opt 
    wget ftp://ftp.fftw.org/pub/fftw/fftw-3.3.4.tar.gz 
    tar xvfz fftw-3.3.4.tar.gz 
    cd fftw-3.3.4 
    ./configure --prefix=/usr/local
    make -j2
    make install

    # install ANN 1.1.2 (optional)
    cd /opt
    wget http://www.cs.umd.edu/~mount/ANN/Files/1.1.2/ann_1.1.2.tar.gz
    tar xvfz ann_1.1.2.tar.gz
    cd ann_1.1.2
    if [ "$(gfortran -dumpversion)" == "10.0.1" ] ; then echo yes; fi
    export CXX=/usr/local/bin/g++
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
    if [ "$(gfortran -dumpversion)" == "10.0.1" ] ; then echo yes; fi
    make clean
    make -j2 Galacticus.exe

%labels
    Author ffayton@carnegiescience.edu
    Version v0.0.1

%help
    This is demo container used for Galacticus.

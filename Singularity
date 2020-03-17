Bootstrap: shub
From: ffayton/centos7_gcc10

%environment
    export LC_ALL=C
    export INSTALL_PATH=/usr/local
    export PATH=/usr/local/bin:$PATH
    export PERL_MM_USE_DEFAULT=1
    export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib64:/usr/lib64:/usr/local/lib
    export GALACTICUS_EXEC_PATH=/usr/local/galacticus/
    export GALACTICUS_DATA_PATH=/usr/local/galacticus_datasets

%post
    NOW=`date`
    echo "export NOW=\"${NOW}\"" >> $SINGULARITY_ENVIRONMENT
    echo "export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib64:/usr/lib64:/usr/local/lib
    export GALACTICUS_EXEC_PATH=/usr/local/galacticus/
    export GALACTICUS_DATA_PATH=/usr/local/galacticus_datasets" >> $SINGULARITY_ENVIRONMENT
    export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/lib64:/usr/local/lib
    export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib64:usr/lib64:/usr/local/lib
    export PATH=/usr/local/bin:$PATH
    yum -y install gsl-devel
    
    # install FGSL v0.9.4
    cd /opt
    wget https://www.lrz.de/services/software/mathematik/gsl/fortran/download/fgsl-0.9.4.tar.gz
    tar -vxzf fgsl-0.9.4.tar.gz
    cd fgsl-0.9.4
    ./configure --gsl /usr/local --f90 gfortran --prefix /usr/local
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
    FC=gfortran ./configure
    make
    make install

    # install FFTW 3.3.4 (optional)
    cd /opt
    wget ftp://ftp.fftw.org/pub/fftw/fftw-3.3.4.tar.gz
    tar xvfz fftw-3.3.4.tar.gz
    cd fftw-3.3.4
    ./configure --prefix=/usr/local
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
    
%files from build
    # copy the full installation directory, including the executable
    /usr/local/galacticus /usr/local/galacticus 
    
    # copy dynamically linked libraries
    /usr/local/lib64 /usr/local/lib64
    /usr/lib64 /usr/lib64
    /usr/local/lib /usr/local/lib
    
    # copy parameters template
    #COPY parameters/quickTest.xml /usr/local/galacticus/parameters/quickTest.xml
    /usr/local/galacticus/parameters/ /usr/local/galacticus/parameters/
    
    # script to execute the model with input arguments
    /usr/local/galacticus/scripts/run_galacticus.sh /usr/local/galacticus/run_galacticus.sh

%labels
    Author ffayton@carnegiescience.edu
    Version v0.0.1

%help
    This is demo container used for Galacticus.

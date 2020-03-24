Bootstrap: library
From: ffayton/default/galacticus_prebuild:latest

%environment
    export PATH=/usr/local/bin:/usr/local/galacticus:$PATH
    export LD_LIBRARY_PATH=/usr/local/lib64:/usr/local/lib:$LD_LIBRARY_PATH
    export GALACTICUS_EXEC_PATH=/usr/local/galacticus/
    export GALACTICUS_DATA_PATH=/usr/local/galacticus_datasets

%post
    NOW=`date`
    echo "export NOW=\"${NOW}\"
    export PATH=/usr/local/bin:/usr/local/galacticus:$PATH
    export LD_LIBRARY_PATH=/usr/local/lib64:/usr/local/lib:$LD_LIBRARY_PATH" >> $SINGULARITY_ENVIRONMENT
    export LD_LIBRARY_PATH=/usr/local/lib64:/usr/local/lib:$LD_LIBRARY_PATH
    export PATH=/usr/local/bin:/usr/local/galacticus:$PATH
    
    if [ "$(gfortran -dumpversion)" == "10.0.1" ] ; then echo "GCC-10 being used to compile" ; else exit 1; fi
    
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
    make -j16 Galacticus.exe

%labels
    Author ffayton@carnegiescience.edu
    Version v0.0.1

%help
    This is container is used to build Galacticus, https://github.com/galacticusorg/galacticus.git.

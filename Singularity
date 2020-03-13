Bootstrap: yum
OSVersion: 7
MirrorURL: http://mirror.centos.org/centos-%{OSVERSION}/%{OSVERSION}/os/$basearch/
Include: yum
Stage: build

%files
    / /usr/local/galacticus

%environment
    export LC_ALL=C
    export INSTALL_PATH=/usr/local
    export PATH=$INSTALL_PATH:$PATH
    export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib64
    export PERL_MM_USE_DEFAULT=1
    export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/lib64:/usr/local/lib

%post
    NOW=`date`
    echo "export NOW=\"${NOW}\"" >> $SINGULARITY_ENVIRONMENT
    ls -lrt /
    yum -y update
    yum -y install epel-release
    yum -y install vim wget make tar gzip bzip2 gsl texinfo\
    	mercurial openssh-clientsblas blas-devel lapack gcc-c++
    # install Perl modules
    yum install -y expat-devel perl-XML* \
        cpanm gcc perl perl-App-cpanminus perl-Config-Tiny \
	perl-YAML perl-Cwd perl-DateTime \
	perl-File* perl-LaTeX-Encode perl-NestedMap perl-Scalar-Util \
	perl-Data-Dumper perl-Term-ANSIColor \
	perl-Text-Table perl-Sort-Topological perl-Text-Template \
	perl-Sort-Topological perl-List-Uniq perl-Regexp-Common \
	perl-XML-Validator-Schema perl-List-MoreUtils \
	patch zlib-devel mercurial openssh-clients
    yum install centos-release-scl
    yum install devtoolset-8-gcc devtoolset-8-gcc-c++ devtoolset-8-gcc-gfortran
    scl enable devtoolset-8 -- bash
    
    # install GSL v1.15
    cd /opt 
    wget http://ftp.gnu.org/pub/gnu/gsl/gsl-1.15.tar.gz 
    tar xvfz gsl-1.15.tar.gz 
    cd gsl-1.15 
    ./configure --prefix=$INSTALL_PATH --disable-static 
    make 
    make check 
    make install
	
    # install FGSL v0.9.4
    cd /opt 
    wget https://www.lrz.de/services/software/mathematik/gsl/fortran/download/fgsl-0.9.4.tar.gz 
    tar -vxzf fgsl-0.9.4.tar.gz
    cd fgsl-0.9.4 
    ./configure --gsl $INSTALL_PATH --f90 gfortran --prefix $INSTALL_PATH 
    make 
    make test 
    make install
    
    # install HDF5 v1.8.20
    cd /opt 
    wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.20/src/hdf5-1.8.20.tar.gz
    tar -vxzf hdf5-1.8.20.tar.gz 
    cd hdf5-1.8.20 
    F9X=gfortran ./configure --prefix=$INSTALL_PATH --enable-fortran --enable-production 
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
    ./configure --prefix=$INSTALL_PATH 
    make
    make install
    
    # install ANN 1.1.2 (optional)
    cd /opt 
    wget http://www.cs.umd.edu/~mount/ANN/Files/1.1.2/ann_1.1.2.tar.gz 
    tar xvfz ann_1.1.2.tar.gz 
    cd ann_1.1.2 
    make linux-g++  
    cp bin/* /usr/local/bin/.

%labels
    Author ffayton@carnegiescience.edu
    Version v0.0.1

%help
    This is demo container used for Galacticus.

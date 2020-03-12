Bootstrap: yum
OSVersion: 7
MirrorURL: http://mirror.centos.org/centos-%{OSVERSION}/%{OSVERSION}/os/$basearch/
Include: yum
Stage: build

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
    yum -y update &&\
    yum -y install vim wget make 

    # Must install latest version of gcc from source
	cd /opt &&\
    wget ftp://ftp.gnu.org/gnu/gcc/gcc-8.2.0/gcc-8.2.0.tar.gz &&\
    tar xvfz gcc-8.2.0.tar.gz &&\
	cd gcc-8.2.0 &&\
	./contrib/download_prerequisites &&\
	sed -i~ -r s/"gfc_internal_error \(\"new_symbol\(\): Symbol name too long\"\);"/"printf \(\"new_symbol\(\): Symbol name too long\"\);"/ gcc/fortran/symbol.c

	yum install -y gcc-c++
	cd /opt &&\
    mkdir gcc-8.2.0-build &&\
    cd gcc-8.2.0-build &&\
    ../gcc-8.2.0/configure --prefix=$INSTALL_PATH --enable-languages=c,c++,fortran --disable-multilib &&\
    make &&\
    make install

	# install GSL v1.15 
	yum install -y texinfo
	cd /opt &&\
    wget http://ftp.gnu.org/pub/gnu/gsl/gsl-1.15.tar.gz &&\
    tar xvfz gsl-1.15.tar.gz &&\
    cd gsl-1.15 &&\
    ./configure --prefix=$INSTALL_PATH --disable-static &&\
	make &&\
	make check &&\
	make install
	
	# install FGSL v0.9.4
	cd /opt &&\
    wget https://www.lrz.de/services/software/mathematik/gsl/fortran/download/fgsl-0.9.4.tar.gz &&\
    tar -vxzf fgsl-0.9.4.tar.gz &&\
    cd fgsl-0.9.4 &&\
    ./configure --gsl $INSTALL_PATH --f90 gfortran --prefix $INSTALL_PATH &&\
    make &&\
    make test &&\
    make install

	# install fortran
	yum install -y gcc-gfortran

	# install HDF5 v1.8.20
	cd /opt &&\
    wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.20/src/hdf5-1.8.20.tar.gz &&\
    tar -vxzf hdf5-1.8.20.tar.gz &&\
    cd hdf5-1.8.20 &&\
    F9X=gfortran ./configure --prefix=$INSTALL_PATH --enable-fortran --enable-production &&\
    make &&\
    make install

	# install FoX v4.1.0
	cd /opt &&\
    wget https://github.com/andreww/fox/archive/4.1.0.tar.gz &&\
    tar xvfz 4.1.0.tar.gz &&\
    cd fox-4.1.0 &&\
    FC=gfortran ./configure &&\
    make &&\
    make install

	# install BLAS and LAPACK
	yum install -y blas blas-devel lapack

	# install FFTW 3.3.4 (optional)
	cd /opt &&\
    wget ftp://ftp.fftw.org/pub/fftw/fftw-3.3.4.tar.gz &&\
    tar xvfz fftw-3.3.4.tar.gz &&\
    cd fftw-3.3.4 &&\
    ./configure --prefix=$INSTALL_PATH &&\
    make &&\
    make install

	# install ANN 1.1.2 (optional)
	cd /opt &&\
    wget http://www.cs.umd.edu/~mount/ANN/Files/1.1.2/ann_1.1.2.tar.gz &&\
    tar xvfz ann_1.1.2.tar.gz &&\
    cd ann_1.1.2 &&\
    make linux-g++  &&\
    cp bin/* /usr/local/bin/.

	# install Perl modules
	yum install -y expat-devel
	yum install -y perl &&\
    yum install -y cpan
	cpan -i YAML
	cpan -i Cwd
	cpan -i DateTime
	cpan -i Data::Dumper
	cpan -i File::Copy
	cpan -i File::Slurp
	cpan -i LaTeX::Encode
	cpan -i NestedMap
	cpan -i Scalar::Util
	cpan -i Term::ANSIColor
	cpan -i Text::Table
	cpan -i XML::SAX::ParserFactory
	cpan -i XML::Simple
	cpan -i XML::Validator::Schema
	cpan -i Sort::Topological
	cpan -i Text::Template
	cpan -i List::Uniq
	cpan -i XML::SAX::Expat
	cpan -i XML::Simple
	cpan -i DateTime
	cpan -i Regexp::Common
	cpan -i File::Next
	cpan -i XML::Validator::Schema
	cpan -i List::MoreUtils

	# install Galacticus
	yum install -y patch zlib-devel
	yum install -y mercurial openssh-clients

	cd /usr/local &&\
    hg clone https://hg@bitbucket.org/galacticusdev/galacticus &&\
    cd galacticus &&\
    hg pull && hg update workflow
	#hg update v0.9.6

	#ln -s /usr/lib64/libblas.so.3 /usr/lib64/libblas.so

	cd /usr/local/galacticus &&\
    export GALACTICUS_EXEC_PATH=`pwd` &&\
    make Galacticus.exe   

	# install matheval v1.1.11 (optional)
	#	yum install -y guile-2.0 guile-2.0-dev
	#	cd /opt &&\
	#    wget https://ftp.gnu.org/gnu/libmatheval/libmatheval-1.1.10.tar.gz &&\
	#    tar xvfz libmatheval-1.1.10.tar.gz &&\
	#    cd libmatheval-1.1.10 &&\
	#    ./configure --prefix=$INSTALL_PATH/

# Install binary into final image
Bootstrap: library
From: centos:latest
Stage: final

%environment
    export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib64:/usr/lib64:/usr/local/lib
    # setup for running
    export GALACTICUS_EXEC_PATH=/usr/local/galacticus/
    export GALACTICUS_DATA_PATH=/usr/local/galacticus_datasets
%post
    # install system libraries that are needed at runtime
    yum -y update &&\
    yum -y install vim wget patch gcc-gfortran

    # download datasets    
    cd /usr/local &&\
    wget https://bitbucket.org/galacticusdev/datasets/get/default.tar.gz -O galacticus_datasets.tar.gz &&\
    mkdir galacticus_datasets &&\
    tar xvfz galacticus_datasets.tar.gz -C galacticus_datasets --strip-components 1
    yum install -y git

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

%runscript
    echo "Container was created $NOW"
    echo "Arguments received: $*"
    exec echo "$@"
    /usr/local/galacticus/run_galacticus.sh

%startscript
    nc -lp $LISTEN_PORT

%test
    grep -q NAME=\"CentOS\" /etc/os-release
    if [ $? -eq 0 ]; then
        echo "Container base is CentOS as expected."
    else
        echo "Container base is not CentOS."
    fi

%labels
    Author ffayton@carnegiescience.edu
    Version v0.0.1

%help
    This is demo container used for Galacticus.

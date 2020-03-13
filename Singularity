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
    yum -y install vim wget make tar gzip bzip2 gsl hg mercurial
   

%labels
    Author ffayton@carnegiescience.edu
    Version v0.0.1

%help
    This is demo container used for Galacticus.

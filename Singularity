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
    yum -y install vim wget make tar gzip bzip2 gsl \
    	mercurial openssh-clientsblas blas-devel lapack
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

%labels
    Author ffayton@carnegiescience.edu
    Version v0.0.1

%help
    This is demo container used for Galacticus.

#!/usr/bin/env perl
use strict;
use warnings;
use Cwd;
use lib $ENV{'GALACTICUS_EXEC_PATH'}."/perl";
use XML::Simple;
use Data::Dumper;
use Digest::MD5 qw(md5_base64);
use List::Uniq ':all';
use File::Slurp;
use Galacticus::Build::Directives;
use Galacticus::Build::SourceTree;
use Galacticus::Build::SourceTree::Process::FunctionClass::Utils;
use Storable;

# Build source digests for functionClass objects.
# Andrew Benson (06-February-2020)

# Get the name of the executable to compute source digests for.
die("Usage: sourceDigests.pl <sourceDirectory> <executable>")
    unless ( scalar(@ARGV) == 2 );
my $sourceDirectoryName = $ARGV[0];
my $executableName      = $ARGV[1];
# Include files to exclude from parameter search.
my @includeFilesExcluded = ( "fftw3.f03" );
# Specify a work directory.
my $workDirectoryName = $ENV{'BUILDPATH'}."/";
# Get an XML parser.
my $xml                     = new XML::Simple();
# Load the state storables file which lists all known functionClasses.
my $stateStorables = -e $workDirectoryName."stateStorables.xml" ? $xml->XMLin($workDirectoryName."stateStorables.xml") : undef();
# Extract names of functionClasses.
my @functionClasses = map {$_ =~ s/Class$//; $_} sort(keys(%{$stateStorables->{'functionClasses'}}));
# Build list of allowed names.
my @allowedNames = ( "functionClass", @functionClasses, @{$stateStorables->{'functionClassInstances'}} );
if ( exists($stateStorables->{'functionClassTypes'}->{'name'}) ) {
    push(@allowedNames,            $stateStorables->{'functionClassTypes'}->{'name'}   );
} else {
    push(@allowedNames,sort(keys(%{$stateStorables->{'functionClassTypes'}          })));
}
# Build a list of object file dependencies.
(my $dependencyFileName = $ENV{'BUILDPATH'}."/".$executableName) =~ s/\.exe/\.d/;
my @objectFiles = map { $_ =~ /^$ENV{'BUILDPATH'}\/(.+\.o)$/ ? $1 : () } read_file($dependencyFileName, chomp => 1);
# Initialize structure to hold record of parameters from each source file.
(my $blobFileName = $executableName) =~ s/\.exe/.md5.blob/;
my $digestsPerFile;
my $havePerFile = -e $ENV{'BUILDPATH'}."/".$blobFileName;
my $updateTime;
if ( $havePerFile ) {
    $digestsPerFile = retrieve($ENV{'BUILDPATH'}."/".$blobFileName);
    $updateTime     = -M       $ENV{'BUILDPATH'}."/".$blobFileName ;
}
# List of types which were updated.
my @updatedTypes;
# Open the source diretory, finding F90 and cpp files.
opendir(my $sourceDirectory,$sourceDirectoryName."/source");
while ( my $fileName = readdir($sourceDirectory) ) {
    # Skip junk files.
    next
	if ( $fileName =~ m/^\.\#/ );
    # Skip non-F90, non-cpp files
    next
	unless ( $fileName =~ m/\.(F90|cpp)$/ );
    # Find corresponding object file name.    
    (my $objectFileName = $fileName) =~ s/\.(F90|cpp)$/\.o/;
    # Skip non-dependency files.
    next
	unless ( grep {$_ eq $objectFileName} @objectFiles );
    # Construct full file name.
    my $fileToProcess = $sourceDirectoryName."/source/".$fileName;
    # Check if file is updated. If it is not, skip processing it. If it is, remove previous record of uses and rescan.
    (my $fileIdentifier = $fileToProcess) =~ s/\//_/g;
    $fileIdentifier =~ s/^\._??//;
    my $rescan = 1;
    if ( $havePerFile && exists($digestsPerFile->{$fileIdentifier}) ) {
	$rescan = 0
	    unless ( grep {-M $_ < $updateTime} &List::ExtraUtils::as_array($digestsPerFile->{$fileIdentifier}->{'files'}) );
    }
    if ( $rescan ) {
	delete($digestsPerFile->{$fileIdentifier})
    	    if ( $havePerFile && exists($digestsPerFile->{$fileIdentifier}) );
	push(@{$digestsPerFile->{$fileIdentifier}->{'files'}},$fileToProcess);
	# Find the dependency file.
	(my $dependencyFileName = $fileToProcess) =~ s/^.*\/([^\/]+)\.F90$/$ENV{'BUILDPATH'}\/$1\.d/;


	print "WTF ".$dependencyFileName."\n"
	    unless ( -e $dependencyFileName );

	open(my $dependencyFile,$dependencyFileName);
	while ( my $dependentFileName = <$dependencyFile> ) {
	    chomp($dependentFileName);
	    (my $dependencyRoot = $dependentFileName) =~ s/^.*\/([^\/]+)\.o$/source\/$1\./;
	    foreach my $suffix ( "F90", "Inc", "cpp", "c", "h" ) {
		if ( -e $dependencyRoot.$suffix ) {
		    push(@{$digestsPerFile->{$fileIdentifier}->{'files'}},$dependencyRoot.$suffix);
		    last;
		}
	    }
	}
	close($dependencyFile);
	# Walk the source code tree.
	my $tree  = &Galacticus::Build::SourceTree::ParseFile($fileToProcess);
	my $depth = 0;
	my $node  = $tree;
	while ( $node ) {
	    my $isImplementation = grep {$node->{'type'} eq $_} @functionClasses;
	    if ( $node->{'type'} eq "functionClass" || $node->{'type'} eq "functionClassType" || $node->{'type'} eq "sourceDigest" || $isImplementation ) {
		my $hashName = $node->{'directive'}->{'name'}.($node->{'type'} eq "functionClass" ? "Class" : "");
		# Find which class it extends.
		my @classDependencies;
		if ( $isImplementation ) {
		    my $classNode = $node;
		    (my $class, @classDependencies) = &Galacticus::Build::SourceTree::Process::FunctionClass::Utils::Class_Dependencies($classNode,$node->{'type'});
		    # For self-referencing types, remove the self-reference here.
		    @classDependencies = map {$_ eq $class->{'type'} ? () : $_} @classDependencies;
		} elsif ( $node->{'type'} eq "functionClassType" ) {
		    push(@classDependencies,"functionClass");
		} elsif ( $node->{'type'} eq "sourceDigest" ) {
		    # No dependency here.
		} else {
		    # functionClass directive.
		    if ( exists($node->{'directive'}->{'extends'}) ) {
			push(@classDependencies,$node->{'directive'}->{'extends'});
		    } else {
			push(@classDependencies,"functionClass");
		    }
		}
		# Store hash and dependencies.
		$digestsPerFile->{'types'}->{$hashName}->{'sourceMD5'} = &Galacticus::Build::SourceTree::Process::SourceDigest::Find_Hash([$fileName]);
		@{$digestsPerFile->{'types'}->{$hashName}->{'dependencies'}} = @classDependencies;
		push(@updatedTypes,$hashName);		
	    }
	    $node = &Galacticus::Build::SourceTree::Walk_Tree($node,\$depth);
	}		
    }
}
close($sourceDirectory);
# Manually add the base "functionClass" type.
my $functionClassFileName = "objects.function_class.F90";
if ( ! $updateTime || ( -M "source/".$functionClassFileName < $updateTime ) ) {
    $digestsPerFile->{'types'}->{'functionClass'}->{'sourceMD5'} = &Galacticus::Build::SourceTree::Process::SourceDigest::Find_Hash([$functionClassFileName]);
    @{$digestsPerFile->{'types'}->{'functionClass'}->{'dependencies'}} = ();
    delete($digestsPerFile->{'types'}->{'functionClass'}->{'compositeMD5'});
    push(@updatedTypes,"functionClass");
}
# Recursively remove the composite hash for this type, and any dependent type.
while ( scalar(@updatedTypes) > 0 ) {
    my $hashNameReset = pop(@updatedTypes);
    foreach my $hashName ( sort(keys(%{$digestsPerFile->{'types'}})) ) {
	push(@updatedTypes,$hashName)
	    if ( (! grep {$_ eq $hashName} @updatedTypes) && (grep {$_ eq $hashNameReset} @{$digestsPerFile->{'types'}->{$hashName}->{'dependencies'}}) );
    }    
    delete($digestsPerFile->{'types'}->{$hashNameReset}->{'compositeMD5'})
	if ( exists($digestsPerFile->{'types'}->{$hashNameReset}->{'compositeMD5'}) );
}
# Construct composite hashes which include the hashes of all dependencies.
my $resolved = 0;
while ( ! $resolved ) {
    $resolved = 1;
    my $updated  = 0;
    foreach my $hashName ( sort(keys(%{$digestsPerFile->{'types'}})) ) {
	# If a composite MD5 is already computed for this type, skip it.
	next
	    if ( exists($digestsPerFile->{'types'}->{$hashName}) && exists($digestsPerFile->{'types'}->{$hashName}->{'compositeMD5'}) );
	# Check if all dependencies are resolved.
	if ( grep {exists($digestsPerFile->{'types'}->{$_}) && ! exists($digestsPerFile->{'types'}->{$_}->{'compositeMD5'})} @{$digestsPerFile->{'types'}->{$hashName}->{'dependencies'}} ) {
	    # Not all dependencies yet have a resolved compositeMD5 - record that we're not yet resolved and skip this type.
	    $resolved = 0;
	} else {
	    # Dependencies are resolved - compute our composite MD5;
	    $updated   = 1;
	    my $hasher = Digest::MD5->new();
	    $hasher->add($digestsPerFile->{'types'}->{$hashName}->{'sourceMD5'});
	    foreach my $dependency ( @{$digestsPerFile->{'types'}->{$hashName}->{'dependencies'}} ) {
		next
		    unless ( grep {$_ eq $dependency} @allowedNames );
		$hasher->add($digestsPerFile->{'types'}->{$dependency}->{'compositeMD5'});
	    }
	    $digestsPerFile->{'types'}->{$hashName}->{'compositeMD5'} = $hasher->b64digest();
	}
    }
    die("sourceDigest.pl: failed to resolve dependencies")
	if ( ! $resolved && ! $updated );
}
# Output the per file digest data.
store($digestsPerFile,$ENV{'BUILDPATH'}."/".$blobFileName);
# Output the results.
(my $outputFileName = $executableName) =~ s/\.exe/.md5s.c/;
open(my $outputFile,">".$ENV{'BUILDPATH'}."/".$outputFileName);
foreach my $hashName ( sort(keys(%{$digestsPerFile->{'types'}})) ) {
    print $outputFile "char ".$hashName."MD5[]=\"".$digestsPerFile->{'types'}->{$hashName}->{'compositeMD5'}."\";\n"
}
close($outputFile);

exit;

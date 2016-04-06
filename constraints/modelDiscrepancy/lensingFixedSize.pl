#!/usr/bin/env perl
my $galacticusPath;
if ( exists($ENV{"GALACTICUS_ROOT_V094"}) ) {
    $galacticusPath = $ENV{"GALACTICUS_ROOT_V094"};
    $galacticusPath .= "/" unless ( $galacticusPath =~ m/\/$/ );
} else {
    $galacticusPath = "./";
}
unshift(@INC, $galacticusPath."perl"); 
use strict;
use warnings;
require Galacticus::Options;
require Galacticus::Constraints::DiscrepancyModels;

# Run calculations to determine the model discrepancy arising from the use of the
# fixed size in gravitational lensing calculations.
# Andrew Benson (18-September-2014)

# Get arguments.
die("Usage: lensingFixedSize.pl <configFile> [options]")
    unless ( scalar(@ARGV) >= 1 );
my $configFile = $ARGV[0];
# Create a hash of named arguments.
my %arguments = 
    (
     make => "yes",
     plot => "no"
    );
&Options::Parse_Options(\@ARGV,\%arguments);

# Specify models to run.
my $models = 
{
    default =>
    {
	label      => "defaultSizes",
	parameters =>
	    [
	     # Use default size for lensing.
	     {
		 name  => "analysisMassFunctionsGravitationalLensingSize",
		 value => 1.0e-3
	     }
	    ]
    },
    alternate =>
    {
	label      => "largeSizes",
	parameters => 
	    [
	     # Use large size for lensing.
	     {
		 name  => "analysisMassFunctionsGravitationalLensingSize",
		 value => 2.0e-3
	     }
	    ]
    }
};

# Run the models.
&DiscrepancyModels::RunModels(
	"lensingFixedSize"                                  ,
	"use of fixed source size in lensing magnifications",
	$configFile                                         ,
	\%arguments                                         ,
	$models
    );

exit;
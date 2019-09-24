#!/usr/bin/env perl
use strict;
use warnings;
use Cwd;
use lib $ENV{'GALACTICUS_EXEC_PATH'}."/perl";
use lib $ENV{'GALACTICUS_ANALYSIS_PERL_PATH'}."/perl";
use PDL;
use PDL::NiceSlice;
use PDL::IO::HDF5;
use PDL::Constants qw(PI);
use Astro::Cosmology;
use XML::Simple;
use Data::Dumper;
use Galacticus::Options;
use Galacticus::HDF5;
use Galacticus::Constraints::Covariances;
use Galacticus::Constraints::DiscrepancyModels;
use Galacticus::Constraints::Concentrations;
use Stats::Histograms;
use GnuPlot::PrettyPlots;
use GnuPlot::LaTeX;

# Compute likelihood (and make a plot) for a Galacticus model given the concentratio distribution in a mass bin from the COCO CDM
# simulation (Wojciech et al.; 2016; MNRAS; 457; 3492; http://adsabs.harvard.edu/abs/2016MNRAS.457.3492H).
# Andrew Benson (20-April-2018)

# Get name of input and output files.
die("concentrations_CDM_COCO_distribution2.pl <galacticusFile> [options]")
    unless ( scalar(@ARGV) >= 1 );
my $galacticusFileName = $ARGV[0];
# Create a hash of named options.
my $iArg = -1;
my %options =
    (
     quiet => 0
    );
&Galacticus::Options::Parse_Options              (\@ARGV                  ,\%options);
&Galacticus::Constraints::Concentrations::COCOCDM($galacticusFileName,"02",\%options);
exit 0;
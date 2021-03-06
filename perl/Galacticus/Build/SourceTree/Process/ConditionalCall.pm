# Contains a Perl module which implements calling of functions with conditionally-present arguments.

package Galacticus::Build::SourceTree::Process::ConditionalCall;
use strict;
use warnings;
use utf8;
use Cwd;
use lib $ENV{'GALACTICUS_EXEC_PATH'}."/perl";
use Data::Dumper;
use List::ExtraUtils;
use Scalar::Util qw(reftype);

# Insert hooks for our functions.
$Galacticus::Build::SourceTree::Hooks::processHooks{'conditionalCall'} = \&Process_ConditionalCall;

sub Process_ConditionalCall {
    # Get the tree.
    my $tree = shift();
    # Walk the tree, looking for code blocks.
    my $node  = $tree;
    my $depth = 0;
    while ( $node ) {
	if ( $node->{'type'} eq "conditionalCall" && ! $node->{'directive'}->{'processed'} ) {
	    # Generate source code for the conditional call.
	    $node->{'directive'}->{'processed'} =  1;
	    my $code      = "! Auto-generated conditional function call.\n";
	    my @variables;
	    die("Galacticus::Build::SourceTree::Process::ConditionalCall::Process_ConditionalCall: at least one argument must be given")
		unless ( exists($node->{'directive'}->{'argument'}) );
	    my $arguments = $node->{'directive'}->{'argument'};
	    my @argumentNames = sort(keys(%{$arguments}));
	    if ( ! reftype($arguments->{$argumentNames[0]}) ) {
		# Only one argument, must restructure the directive data.
		my $argumentsNew;
		$argumentsNew->{$arguments->{'name'}} = $arguments;
		$arguments = $argumentsNew;
		@argumentNames = sort(keys(%{$arguments}));
	    }
	    # Generate code to evaluate conditions.
	    my @conditionalVariables = map {&Galacticus::Build::SourceTree::Parse::Declarations::DeclarationExists($node->{'parent'},"condition".$_."__") ? () : "condition".$_."__"} 1..scalar(@argumentNames);
	    push(
		@variables,
		{
		    intrinsic => "logical",
		    variables => \@conditionalVariables
		}
		)
		if ( scalar(@conditionalVariables) > 0 );
	    my $i = 0;
	    foreach my $argument ( &List::ExtraUtils::hashList($arguments,keyAs => "name") ) {
		my $condition;
		if      ( exists($argument->{'parameterPresent'}) ) {
		    $condition = $argument->{'parameterPresent'}."%isPresent('".$argument->{'name'}."')";
		} elsif ( exists($argument->{'condition'       }) ) {
		    $condition = $argument->{'condition'       }                                        ;
		}
		die("Galacticus::Build::SourceTree::Process::ConditionalCall::Process_ConditionalCall: no condition specified")
		    unless ( defined($condition) );
		++$i;
		$code .= "condition".$i."__=".$condition."\n";
	    }
	    # Generate code to call function.
	    my $formatBinary = "%.".scalar(@argumentNames)."b";
	    for(my $i=0;$i<2**scalar(@argumentNames);++$i) {
		my @state = split(//,sprintf($formatBinary,$i));
		$code .= "if (".join(" .and. ",map {($state[$_-1] == 0 ? ".not." : "")."condition".$_."__"} 1..scalar(@argumentNames)).") then\n";
		foreach my $call ( &List::ExtraUtils::as_array($node->{'directive'}->{'call'}) ) {
		    my $valid = 0;
		    open(my $callStream,"<",\$call);
		    while ( my $line = <$callStream> ) {
			if ( $line =~ m/^(.*)\{conditions\}(.*)$/m ) {
			    my $callPre           = $1;
			    my $callPost          = $2;
			    my $conditionsPrefix  = ($callPre =~ m/\($/) ? "" : ",";
			    $code                .= $callPre.($i == 0 ? "" : $conditionsPrefix).join(",",map {$state[$_-1] == 1 ? $argumentNames[$_-1]."=".$arguments->{$argumentNames[$_-1]}->{'value'} : ()} 1..scalar(@argumentNames)).$callPost."\n";
			    $valid                = 1;
			} else {
			    $code                .= $line;
			}
		    }
		    close($callStream);
		    die("Galacticus::Build::SourceTree::Process::ConditionalCall::Process_ConditionalCall: syntax error in call element")
			unless ( $valid );
		}
		$code .= "end if\n";
	    }
	    # Create a new node.
	    my $newNode =
	    {
		type       => "code",
		content    => $code ,
		firstChild => undef()
	    };
	    # Insert the node.
	    &Galacticus::Build::SourceTree::InsertAfterNode($node,[$newNode]);
	    # Add variables.
	    &Galacticus::Build::SourceTree::Parse::Declarations::AddDeclarations($node->{'parent'},\@variables);
	}
	$node = &Galacticus::Build::SourceTree::Walk_Tree($node,\$depth);
    }
}

1;

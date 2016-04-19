#!/usr/bin/perl
use JSON::PP;
use Data::Dump qw(dump);
use strict;
use warnings;


##************************** VARIABLES DEFINITION ****************************
=head Example
perl extract_data.pl '/tmp/HTTPS_testplan.json'
=cut
my $json_file = $ARGV[0];
if ( $#ARGV < 1 and defined $json_file ) {
    print "Notice: Extrat data in the file $json_file \n";
} else {
    print "\nUsage: \n\t$0 xxx.json\n";
    exit;
}

##************************** END OFVARIABLES DEFINITION **********************

## Initialize JSON object
my $json = JSON::PP->new->utf8;
$json->relaxed;
## Copy content of JSON file into a SCALAR
open( my $fh, '<', $json_file )
    or die "Error: Can't open file: $json_file \n";
my @lines = <$fh>;
my $json_data = '';
foreach ( @lines ) {
    $json_data .= $_;
}
## Decode JSON data into one SCALR
my $perl_scalar = $json->decode($json_data);
## Close file handle
close $fh;

## Show title, id, steps and expected result in turn
print "Test case ID: " . $perl_scalar->{'01'}->{'id'} . "\n";
print "Test case title: " . $perl_scalar->{'01'}->{'title'} . "\n";
print "Decriptiotn: " . "\n"x3;
print " "x2 . "Initial steps:\n" . $perl_scalar->{'01'}->{'initial'} . "\n"x3;
print " "x2 . "Excuative steps:\n" . $perl_scalar->{'01'}->{'steps'} . "\n"x3;
print " "x2 . "Expected results: \n" . $perl_scalar->{'01'}->{'result'} . "\n"x3;
=head sub description
    
=cut
1;
__END__

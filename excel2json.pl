#!/usr/bin/perl
use JSON;
use Spreadsheet::ParseExcel;
use Data::Dump qw(dump);
use strict;
use warnings;


##************************** VARIABLES DEFINITION ****************************
=head Example
perl excel2json.pl '/tmp/testplan.xls' '/tmp/HTTPS_testplan.json'
=cut
my $num_args = $#ARGV + 1;
if ($num_args != 2) {
    print "\nUsage: \n\t$0 source destination\n";
    exit;
}
my $excel_file = $ARGV[0];
my $out_file = $ARGV[1];

print "Notice: $excel_file will be converted to $out_file.\n";

=head hardcoded
my $dir = '/tmp';
my $excel_filename = "testplan.xls";
my $out_filename = "HTTPS_testplan.json";
my $excel_file = $excel_filename;
my $out_file = "$dir/$out_filename";
=cut

##************************** END OFVARIABLES DEFINITION **********************
## 1) Extract data and then keep in an ARRAY data structure
my @converted_data = &excel2array( $excel_file, $out_file);

## 2) Convert ARRAY to HASH data structure
my $data_in_hash = &array2hash(\@converted_data);

## 3) Convert data from HASH to JSON fommat
my $data_in_json = &hash2json($data_in_hash);
print $data_in_json;

## 4) Output to a JSON file
&out2file($data_in_json, $out_file);


##***************************** SUBROUTINES *********************************
sub out2file($$){
    my ($j_string , $o_file) = @_;
    open( FH, "> $o_file" )
        or die "Error: Can't open file: $o_file \n";
    print FH $j_string;
    close FH;

    return 1;
}


sub array2hash(\@){
    my $source_data_aref = shift;
    my $out_data_href;
    my $id = 1;
    ## Switch for numerating testcases
=head_array2hash DESCRIPTION:conveted data struture will be:
    {
       1 => {
                'id'      => "...",
                'title'   => "...",
                'initial' => "...",
                'steps'   => "...",
                'result'  => "...",
            },
        ...
    }
=cut
    foreach (@$source_data_aref) {
        my $tmp_aref = $_;
        ## Get numerical part from original ID 
        my $ap_tc_id = $tmp_aref->[1];
        $ap_tc_id =~ /(\d+)$/;
        my $id = $&;
        $out_data_href->{$id}->{'title'} = $tmp_aref->[2];
        ## intial steps
        my $initial = $tmp_aref->[3];
        my $steps   = $tmp_aref->[4];
        my $results = $tmp_aref->[5];
        ## String formatting
        $initial = &string_processing($initial);
        $steps   = &string_processing($steps);
        $results = &string_processing($results);
        ## Then evaluate hash value
        $out_data_href->{$id}->{'id'}      = $id;
        $out_data_href->{$id}->{'initial'} = $initial;
        $out_data_href->{$id}->{'steps'}   = $steps;
        $out_data_href->{$id}->{'result'}  = $results;
    }

    return $out_data_href;
}


sub string_processing($){
    my $string = shift;
    ## 1) Remove extra return keys
    $string =~ s/\n{2,}/\n/g;
    ## 2) Format speace & table with (\s)X2
    $string =~ s/(\s){2,}/ /g;
    ## Save in an array for futher formatting
    my @item_a = split("\n", $string);
    ## 3) Add 4 space in the beginning of each item
    foreach (@item_a){
        $_ =  " "x2 . $_;
    }
    ## Join them to a string
    $string = join "\n", @item_a;
    ## unicode
    ## html <tag>

    return $string
}


sub hash2json(\%) {
    my $source_data = shift;
    my $json_string = '';
    $json_string = to_json( $source_data, { ascii => 1, pretty => 1 } );

    return $json_string;
}


sub excel2array($$) {
    my ( $source_file ) = @_;
    my $parser   = Spreadsheet::ParseExcel->new();
    my $workbook = $parser->parse("$source_file");

    my @row_a;
    if ( !defined $workbook ) {
        die $parser->error(), "!\n";
    }
    for my $worksheet ( $workbook->worksheets() ) {
        my ( $row_min, $row_max ) = $worksheet->row_range();
        my ( $col_min, $col_max ) = $worksheet->col_range();
        
        for my $row ( $row_min + 1 .. $row_max ) {
            ## Save a row of cells
            my @whole_cols_a = [];
            for my $col ( $col_min .. $col_max ) {
                my $cell = $worksheet->get_cell( $row, $col );
				$cell ?  push @whole_cols_a, $cell->value() : push  @whole_cols_a, 'TBD';
            }
            push @row_a, \@whole_cols_a;
        }
    }
    
    return @row_a;
}
1;
__END__

#!/usr/bin/perl -w
use Data::Dump qw (dump);
use File::Spec;
use MIME::Base64 qw(encode_base64  decode_base64);
use IO::Compress::Zip qw(zip $ZipError) ;
use IO::Uncompress::Unzip qw(unzip $UnzipError) ;

if ( $#ARGV < 1  ){
	die "Usage: $0 method abs_dir times";
}
my $method = exists $ARGV[0] ?  $ARGV[0] : 'encode';
my $passed_dir = $ARGV[1];
my $rootdir = File::Spec->rootdir();
my $dir =  File::Spec->catfile(qw ( var www html ));
my $path = File::Spec->catdir( $rootdir,  $dir  );
my $n = (exists $ARGV[2] and $ARGV[2] =~ /\d+/) ?  $ARGV[2] : 2;

if ( $passed_dir and -d $passed_dir ) {
	print "Passed dir: passed_dir \n";
	$path = $passed_dir;
}
print "method: $method \n", "abs path: $path \n";

process_files($path);
## process files recursively
sub process_files{
	my $current_file = shift;
	opendir DIR, $current_file
		or die "Cannot open $current_file: $!";
	my @files = grep { !/^\.{1,2}$/ } readdir DIR;
	#dump @files;
	close DIR;

	@files = map {$current_file . '/' . $_} @files;
	#dump @files;
	foreach (@files) {
		if ( -d $_ ) {
			process_files($_);
		} else {	
			## compress
			my $status = 'unknow';
			my $input = $_;
			for (1..$n) {
				if ($method eq 'encode') {
					my $output = $input . '.base';
					print "Encoding... \n";
					open(FILE, $input ) or die "Cannot open file $input for input, $!";
					open(TO, ">$output") or die "Cannot open file $output for output, $!";
					while (read(FILE, $buf, 60*57)) {
						#print "string: ", encode_base64($buf);
						print TO encode_base64($buf);
					}
					close FILE;
					close TO;
					print "input: $input \n", "output: $output \n";
					`rm -f $input`;
					$input = $output;
				} elsif ( $method eq 'decode' ) {
					my $file = $input;
					if ( $file =~ /\.base$/ ) {
						print "Decoding... \n";
						$input =~ s/\.base$//;
						my $output = $input;
						open(FILE, $file ) or die "Cannot open file $input for input, $!";
						open(TO, ">$output") or die "Cannot open file $output for output, $!";
						while (read(FILE, $buf, 60*57)) {
							#print "string: ", decode_base64($buf);
							print TO decode_base64($buf);
						}
						close FILE;
						close TO;
						print "input: $file \n", "output: $output \n";
						`rm -f $file`;	
					}
				} elsif ($method eq 'zip') {
					print "Compressing... \n";
					$status = zip  $input => $input . '.zip' 
						or die "zip failed: $ZipError\n";
					`rm -f $input`;
					print "input: $input \n", "output: $input.zip \n", "compress status: $status\n";
					$input .= '.zip';
				} elsif ($method eq 'unzip') {
					my $file = $input;
					if ( $file =~ /\.zip$/ ) {
						print "Uncompressing... \n";
						$input =~ s/\.zip$//;
						my $output = $input;
						$status = unzip $file => $output
							or die "unzip failed: $UnzipError\n" ;
						## remove original file
						`rm -f $file`;
						print "input: $file \n", "output: $output \n", "compress status: $status\n";
					}
					#print "No file to be unzip! \n";
				}
			}## for	
		}## file processing
	}
}
__END__
perl process_viruses.pl encode  /var/www/html/virus 2
perl process_viruses.pl decode  /var/www/html/virus 2
perl process_viruses.pl zip  /var/www/html/virus 3
perl process_viruses.pl unzip  /tmp/test_dir 3











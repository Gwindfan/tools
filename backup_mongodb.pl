#!/usr/bin/perl
use strict;
use warnings;
use MIME::Lite;
=head arguments
host ip 
db name
=cut

## Initialize the variables
my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
my $timestamp     = sprintf ( "%04d%02d%02d-%02d%02d%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);
my $host   = '10.200.0.103';
my $hostname = `hostname`;
$host      = $ARGV[0] if $#ARGV > -1;
my $db_name    = (exists $ARGV[1] and '' ne $ARGV[1]) ? $ARGV[1] : "qadashboard_production";
my $tmp_dir    = (exists $ARGV[2] and '' ne $ARGV[2]) ? $ARGV[2] : "/opt/backup/mongodump";
my $backup_dir = '/opt/backup';

=head mail initialization
## init mail list
my $domain = "TBD.com";
my $smtp_server = "TBD\." . $domain;
my $from   = "TBD@" . $domain;
my $to     = $ARGV[3] . '@'. $domain;
my $cc     = "TBD@" . $domain;
=cut

## cmd for mongodump to backup db
my $bkpCmd = "mongodump --host $host --port 27017 --db $db_name --out $tmp_dir";
## zip and add time stamp into output file's name
my $zipCmd = "zip -r $backup_dir/mongodump-$timestamp.zip $tmp_dir";

## Remove the oldest backup
my  $files = `ls -tR /opt/backup/mongodump-*`;
my @backups = split /\n/, $files;
my $maxBkps = 5;
if ( $#backups >= $maxBkps ) {
    for my $backup (@backups[$maxBkps..$#backups]) {
        next unless $backup =~ /mongodump/;
        $backup =~ s/^\s+//;
        my $cmd = "rm $backup";
        `$cmd`;
    }
}

## Excute previous cmds
`rm -rf /opt/backup/mongodump`;
`$bkpCmd`;
`$zipCmd`;
`rm -rf /opt/backup/mongodump`;
## Mail to Admin
notify();


sub notify {
    my $result = shift;
	my @backup_list = split '\n',`ls -l -A $backup_dir`;
	my $mail_body = join '</br>', @backup_list[1..$#backup_list];
	my $hint = 'Dump all backups: </br>';
	local $@;
    eval {
        ## Compose the mail body
        my $data = "";
        $data .= qq|<body  bgcolor="#F4F4F4">
            <p style="color: #555; padding: 3px 6px; font-size: .9em;"> $hint $mail_body
            </p>|;

        MIME::Lite->send( 'smtp', "$smtp_server", Timeout => 60 );
        my $msg = MIME::Lite->new(
            "From"     => $from,
            "To"       => $to,
            "Cc"       => $cc,
            "Subject"  => "QADashboard - MongoDB backup on $hostname - Done",
            "Type"     => 'multipart/mixed',
            "Reply-To" => ''
        );

        $msg->attach(
            Type => 'text/html',
            Data => $data,
        );
        $msg->send(); 
    };
    print($@) if my $exception = $@;
}
__END__
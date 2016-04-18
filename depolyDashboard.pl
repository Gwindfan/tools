#!/usr/bin/perl
use strict;
use MIME::Lite;
use LWP;
use LWP::Protocol::https;

=head arguments
mail username like mike required for $to
=cut

## Initialize
my $logBuffer;
my $hostname = `hostname`;
my $webServerState = 0;
chomp($hostname);
=head user-defined info
## P4 credential
$ENV{P4PASSWD} = 'TBD';
$ENV{P4CLIENT} = $hostname;
$ENV{P4USER}   = 'TBD';
$ENV{P4PORT}   = 'TBD';

## init mail list
my $domain = "TBD.com";
my $smtp_server = "TBD\." . $domain;
my $from   = "TBD@" . $domain;
my $to     = $ARGV[0] . '@'. $domain;
my $cc     = "TBD@" . $domain;

## Dashboard path in P4
my $dashboard_dir = 'TBD';
my $dashboard_local_dir = 'TBD';
my $production_dir = "TBD";
=cut

## Open the log file
open FH, ">/tmp/deploy.log";

eval {
    ## Sync from Perforce
    debuglog("#1/3 P4 Sync Started.");
    my $p4out = `p4 sync $dashboard_dir/... 2>&1`;
    debuglog($p4out);	
	## Get up-to-date returned
    debuglog("");
    $p4out = `p4 sync $dashboard_dir/... 2>&1`;
    debuglog($p4out);
    if ( $p4out !~ /up-to-date/ ) {
        debuglog("P4 Sync Failed");
        notify("Failed");
        exit 1;
    }
	## succeed to sync from P4
    debuglog("#1/3 Sync Completed.");

    ## Copy the files to production location
    debuglog("#2/3 File Copy Started");
    `rm -rf $production_dir`;
    `cp -r $dashboard_local_dir /.`;
	## -w
    `chmod -R 555 $production_dir/script/*`;
    my $diffCount = `diff -r $production_dir/ $dashboard_local_dir/ | grep diff | grep -v 'QADashboard/tmp' | wc -l`;
    if ( $diffCount > 0 ) {
        debuglog("File Copy Failed");
        notify("Failed");
        exit;
    }
    debuglog("#2/3 File Copy Completed");


    ## Check if WebServer is up
	local $@;
    eval {
        debuglog("#3/3 Web Server restart Started");
        my $out = `/etc/init.d/apache2 restart 2>&1`; 
        debuglog($out);       
        my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
        my $response;
        for ( my $i = 0; $i < 6; $i++ ) {
            sleep 5;
            for ( my $j = 0; $j < 12; $j++ ) {
                $response = $ua->get("https://localhost");
                debuglog("WebServer status - " . $response->is_success );
                last if ( $response->is_success );
                sleep 5;
            }
            if ( $response->is_success ) {
                $webServerState = 1;
                last;
            }
            `/etc/init.d/apache2 restart`;
        }
    };
    debuglog($@) if $@;
};
if ( $webServerState == 1 ) {
    debuglog("#3/3 Web Server restart Succeeded");
    notify("Successful");
} else {
    debuglog("#3/3 Web Server restart Failed");
    notify("Failed");
}
## close file handler
close FH;


## inner methods
sub debuglog {
    my $message = shift;
    $logBuffer .= $message . '<br/>';
    print FH $message;
}


sub notify {
    my $result = shift;

	local $@;
    eval {
        ## Compose the mail body
        my $data = "";
        $data .= qq|<body  bgcolor="#F4F4F4">
            <p style="color: #555; padding: 3px 6px; font-size: .9em;"> $logBuffer
            </p>|;

        MIME::Lite->send( 'smtp', "$smtp_server", Timeout => 60 );
        my $msg = MIME::Lite->new(
            "From"     => $from,
            "To"       => $to,
            "Cc"       => $cc,
            "Subject"  => "QADashboard - Deployment on $hostname - $result",
            "Type"     => 'multipart/mixed',
            "Reply-To" => ''
        );

        $msg->attach(
            Type => 'text/html',
            Data => $data,
        );
        $msg->send(); 
    };
    debuglog($@) if my $exception = $@;
}
__END__
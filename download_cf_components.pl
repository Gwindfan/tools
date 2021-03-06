﻿use POSIX ":sys_wait_h";
use Net::SCP::Expect;
use warnings;
use strict;

if ( $#ARGV < 0 ){
	die "Usage: $0 to_host [to_dir] [username] [password]";
}
## Destination host infomation
my $dest_host =  $ARGV[0] if $#ARGV > -1 ;
my $dest_dir  = ( exists $ARGV[1] and '' ne $ARGV[1] ) ? $ARGV[1] : '/tmp';
my $username  = ( exists $ARGV[2] and '' ne $ARGV[2] ) ? $ARGV[2] : 'root';
my $password  = ( exists $ARGV[3] and '' ne $ARGV[3] ) ? $ARGV[3] : 'password';
my $scpe = Net::SCP::Expect->new( host => $dest_host,
                                  user => $username,
                                  password => $password,
                                  timeout => 20,
                                  auto_yes => 1); 
my %uri = ( 
'virtualbox_bosh-lite.box' => 'https://atlas.hashicorp.com/cloudfoundry/boxes/bosh-lite/versions/9000.131.0/providers/virtualbox.box',
);
my @children_pids;

$SIG{CHLD}=\&REAPER;
sub REAPER {
	my $child;
	while(( $child = waitpid(-1, &WNOHANG)) > 0){
        my $localtime = localtime;
        print "Parent: Child $child was reaped - $localtime.\n";
        @children_pids = grep {$_  ne $child} @children_pids;
        if ( 0 == (my $count = @children_pids )) {
             print "All children reaped. exit \n";
             exit 0;
        }

    }
    $SIG{CHLD}=\&REAPER;
}

print "Parent: my pid $$\n";
foreach my $key (keys %uri) {
	die "$@" unless defined( my $child_pid = fork());
    if ($child_pid) {  # If I have a child PID, then I must be the parent
    push @children_pids, $child_pid;
        print "children's PIDs: @children_pids\n";
    } else { # I am the child
        my $start_time = time();
        `wget -O $key $uri{$key}`;
        local $SIG{CHLD} = sub {}; ## catch scp process
        my $res = $scpe->scp($key, "$dest_dir");
        (1 == $res) ? print "scp passed. \n" : print "scp failed! \n" ;
        my $end_time = time();
        my $time_cost = $end_time - $start_time;
        my $min = int($time_cost / 60);
        my $sec = $time_cost % 60;

        print "Child $$ exited, took $min min $sec sec\n";
        exit 0; # Exit the child
        }
}
while(1){
    sleep 1;
}
__END__
## Ubuntu trusty
my %uri = (
	'vagrant_1.8.6_x86_64.deb' => 'https://releases.hashicorp.com/vagrant/1.8.6/vagrant_1.8.6_x86_64.deb',
	'virtualbox-5.1_5.1.6-110634-Ubuntu-trusty_amd64.deb' => 'http://download.virtualbox.org/virtualbox/5.1.6/virtualbox-5.1_5.1.6-110634~Ubuntu~trusty_amd64.deb',
	'Oracle_VM_VirtualBox_Extension_Pack-5.1.6-110634.vbox-extpack' => 'http://download.virtualbox.org/virtualbox/5.1.6/Oracle_VM_VirtualBox_Extension_Pack-5.1.6-110634.vbox-extpack',
	'virtualbox_trusty64.box' => 'https://atlas.hashicorp.com/ubuntu/boxes/trusty64/versions/20161005.0.0/providers/virtualbox.box',
	'virtualbox_precise64_.box' => 'https://atlas.hashicorp.com/hashicorp/boxes/precise64/versions/1.1.0/providers/virtualbox.box',
	'virtualbox_precise32.box' => ' https://atlas.hashicorp.com/hashicorp/boxes/precise32/versions/1.0.0/providers/virtualbox.box',
); 
## MAC OS
my $uri = (
	'vagrant_1.8.6.dmg' => 'https://releases.hashicorp.com/vagrant/1.8.6/vagrant_1.8.6.dmg',
	'VirtualBox-5.1.6-110634-OSX.dmg' => 'http://download.virtualbox.org/virtualbox/5.1.6/VirtualBox-5.1.6-110634-OSX.dmg',
	'Oracle_VM_VirtualBox_Extension_Pack-5.1.6-110634.vbox-extpack' => 'http://download.virtualbox.org/virtualbox/5.1.6/Oracle_VM_VirtualBox_Extension_Pack-5.1.6-110634.vbox-extpack',
	'virtualbox_trusty64.box' => 'https://atlas.hashicorp.com/ubuntu/boxes/trusty64/versions/20161005.0.0/providers/virtualbox.box',
	'virtualbox_precise64.box' => 'https://atlas.hashicorp.com/hashicorp/boxes/precise64/versions/1.1.0/providers/virtualbox.box',
	'virtualbox_precise32.box' => ' https://atlas.hashicorp.com/hashicorp/boxes/precise32/versions/1.0.0/providers/virtualbox.box',
);

'virtualbox_bosh-lite.box' => 'https://atlas.hashicorp.com/cloudfoundry/boxes/bosh-lite/versions/9000.131.0/providers/virtualbox.box',

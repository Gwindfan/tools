#!/usr/bin/perl
use POSIX qw(:signal_h :errno_h :sys_wait_h);


$SIG{CHLD}=\&REAPER;
sub REAPER {
    my $child = waitpid(-1, WHOHANG);
    my $exit_code = $? >> 8;
    my $localtime =localtime;

    if ($child <= 0 ){
        ## no dead child
    } elsif (WIFEXITED($?)) { ## Make suire child exited, not SIGSTOP or others
        print "Child $child was reaped, return $exit_code at $localtime.\n";
    } else {
        print "False alam. \n";
    }
    $SIG{CHLD}=\&REAPER;
}

my @children_pids;
print "Parent: my pid $$\n";
for my $count (1..10){
    die "$@" unless defined( my $child_pid = fork());
    if ($child_pid) {  # If I have a child PID, then I must be the parent
        push @children_pids, $child_pid;
        print "children's PIDs: @children_pids\n";
    } else { # I am the child
        my $wait_time = int(rand(10));
        sleep $wait_time;
        my $localtime = localtime;
        print "Child: Some child exited at $localtime\n";
        exit 1; # Exit the child
    }
}


=head reap children in order
foreach my $child (@children_pids) {
        print "Parent: Waiting on $child\n";
        waitpid($child, 0);
        my $localtime = localtime;
        print "Parent: Child $child was reaped - $localtime.\n";
}
=cut

## Keep parent alive to reap all children
while (1) {
    sleep;
}
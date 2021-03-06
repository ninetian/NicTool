package NicToolServer::Export::NSD;
# ABSTRACT: exporting DNS data to NSD

use strict;
use warnings;

use lib 'lib';
use parent 'NicToolServer::Export::BIND';

use Cwd;
use IO::File;
use File::Copy;
use Params::Validate qw/ :all /;

sub write_makefile {
    my $self = shift;

    my $exportdir = $self->{nte}->get_export_dir or do {
        warn "no export dir!";
        return;
    };
    return 1 if -e "$exportdir/Makefile";   # already exists

    my $address = $self->{nte}{ns_ref}{address} || '127.0.0.1';
    my $datadir = $self->{nte}{ns_ref}{datadir} || getcwd . '/data-all';
    $datadir =~ s/\/$//;  # strip off any trailing /
    open my $M, '>', "$exportdir/Makefile" or do {
        warn "unable to open ./Makefile: $!\n";
        return;
    };
    print $M <<MAKE
# After a successful export, 3 make targets are run: compile, remote, restart
# Each target can do anything you'd like.
# See https://www.gnu.org/software/make/manual/make.html

################################
#########    NSD   #############
################################
# Note: you will need to configure zonesdir in nsd.conf to point to this
# export directory. Make sure the export directory reflected below is correct
# then uncomment each of the targets.

# NSD v3 uses nsdc, v4 uses nsd-control
compile: $exportdir/named.conf.nictool
\tnsd-control rebuild
\t#nsdc rebuild

remote: /var/db/nsd/nsd.db
\trsync -az --delete /var/db/nsd/nsd.db nsd\@$address:/var/db/nsd/

restart: nsd.db
\tssh nsd\@$address nsd-control reload
\t#ssh nsd\@$address nsdc reload
MAKE
;
    close $M;
    return 1;
};

1;

__END__

=head1 NAME

NicToolServer::Export::NSD

=head1 SYNOPSIS

Export DNS information from NicTool as BIND zone files for the NSD name server.

=head1 named.conf.local

This class will export a named.conf.nictool file with all the NicTool zones assigned to that NicTool nameserver. It is expected that this file will be included into a named.conf file via an include entry like this:

 include "/etc/namedb/master/named.conf.nictool";

=cut

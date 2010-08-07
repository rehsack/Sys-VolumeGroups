package Sys::VolumeGroups::AixLvm;

use warnings;
use strict;

require 5.008;
require IPC::Cmd;

=head1 NAME

Sys::VolumeGroups::AixLvm - provides the access to lvm information on AIX

=cut

our $VERSION = '0.001';

require IPC::Cmd;
my ( $lsvg, $lslv );

sub usable
{
    unless( defined( $lsvg ) )
    {
	$lsvg = IPC::Cmd::can_run( 'lsvg' );
	$lsvg ||= '';
    }

    unless( defined( $lslv ) )
    {
	$lslv = IPC::Cmd::can_run( 'lslv' );
	$lslv ||= '';
    }

    return $lsvg && $lslv;
}

sub new
{
    my ($class, %opts) = $_[0];

    $opts{lsvg} ||= $lsvg;
    $opts{lslv} ||= $lslv;

    my $self = bless( \%opts, $class );

    return $self;
}

# see demo table at http://publib.boulder.ibm.com/infocenter/aix/v6r1/index.jsp?topic=/com.ibm.aix.cmds/doc/aixcmds3/lsvg.htm
sub _parse_table
{
    my $tblbuf = $_[0];
    my @lines = split( "\n", $tblbuf );
    my %table;

    foreach my $line (@lines)
    {
	while (
	    $tblbuf =~ m/
			\G(?:^|[\s]+|\b)        # start ...
			([^\s][^:]+):           # identifier
			\s*                     # separator
			(                       # group data
			    (?:
				[^\s:]+         # not a white space
				(?:             # and ...
				    \s[^\s:]+   # white space followed by an identifier without ':' at the end
				)*              # 0..n times
			    )+                  # at least once
			)
			(?:[\s]+?|$)            # followed by finishing white space or EOL
		    /gx
	      )
	{
	    my $descr = $1;
	    my $data = $2;
	    $descr =~ s/\W+$//;
	    $descr =~ s/\W+/_/g;
	    $table{ uc $descr } = $data;
	}
    }

    return \%table;
}

#Total PVs
#Active PVs
#VG identifier
#PP size
#Total PPs
#Free PPs
#Alloc PPs
#Quorum
#Auto-on
#Concurrent
#Auto-Concurrent
#VG Mode
#Node ID
#Active Nodes
#Max PPs Per PV
#Max PVs
#LTG size
#BB POLICY
#SNAPSHOT VG
#PRIMARY VG

my %vg_descriptor_map = (
    'VOLUME_GROUP_STATE' => 'VG_STATE',
    'PERMISSION' => 'VG_PERMISSION',
    'VGDS' => 'VG_DESCRIPTORS', # XXX ???
);

sub get_physical_volumes
{
    my $self = $_[0];
    my @vgs;
    my %online;

    my ( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf ) =
      IPC::Cmd::run( command => [ $self->{lsvg}, '-L', '-o' ],
                     verbose => 0, );

    if ($success)
    {
	chomp $stdout_buf->[0];
	my @online_vgs = grep { m/^\w+$/ } split($stdout_buf->[0]);

	%online = map { $_ => 1 } @online_vgs;
	( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf ) =
	  IPC::Cmd::run( command => [ $self->{lsvg}, '-L', @online_vgs ],
			 verbose => 0, );

	if ($success)
	{
	    chomp $stdout_buf->[0];
	    # split from 'Volume group.*' -> 'Volume group' or end
	    my $vgdatatbl = _parse_table( $stdout_buf->[0] );
	    my %vgdata = map { ( $vg_descriptor_map{$_} || $_ ) => $vgdatatbl->{$_} } keys %$vgdatatbl;
	    push( @vgs, \%vgdata );
	}

	( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf ) =
	  IPC::Cmd::run( command => [ $self->{lsvg}, '-L' ],
			 verbose => 0, );

	if ($success)
	{
	    chomp $stdout_buf->[0];
	    my @all_vgs = grep { m/^\w+$/ } split($stdout_buf->[0]);

	    foreach my $vg (@all_vgs)
	    {
		next if( $online{$vg};
		my %vgdata = (
		    VOLUME_GROUP => $vg,
		    VG_STATE => 'offline',
		);
		push( @vgs, \%vgdata );
	    }
	}
    }

    return @vgs;
}

sub get_logical_volumes
{
    my $self = $_[0];
    my @vgs;

    my ( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf ) =
      IPC::Cmd::run( command => [ $self->{lsvg}, '-L', '-o' ],
                     verbose => 0, );

    if ($success)
    {
	chomp $stdout_buf->[0];
	my @online_vgs = grep { m/^\w+$/ } split($stdout_buf->[0]);

	%online = map { $_ => 1 } @online_vgs;
	( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf ) =
	  IPC::Cmd::run( command => [ $self->{lsvg}, '-L', '-l', @online_vgs ],
			 verbose => 0, );

	if ($success)
	{
	    chomp $stdout_buf->[0];
	    my $vgdatatbl = _parse_table( $stdout_buf->[0] );
	    my %vgdata = map { ( $vg_descriptor_map{$_} || $_ ) => $vgdatatbl->{$_} } keys %$vgdatatbl;
	    push( @vgs, \%vgdata );
	}

    }

    return @vgs;
}

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;


package Sys::VolumeGroups::LinuxLvm2;

use warnings;
use strict;

require 5.008;
require IPC::Cmd;

=head1 NAME

Sys::VolumeGroups::LinuxLvm2 - provides the access to lvm2 information

=cut

our $VERSION = '0.001';

require IPC::Cmd;
use List::Moreutils qw(zip);

my ( $vgdisplay, $lvdisplay);

sub usable
{
    unless( defined( $vgdisplay ) )
    {
	$vgdisplay = IPC::Cmd::can_run( 'vgdisplay' );
	$vgdisplay ||= '';
    }

    unless( defined( $lvdisplay ) )
    {
	$lvdisplay = IPC::Cmd::can_run( 'lvdisplay' );
	$lvdisplay ||= '';
    }

    return $vgdisplay && $lvdisplay;
}

sub new
{
    my ($class, %opts) = $_[0];

    $opts{vgdisplay} ||= $vgdisplay;
    $opts{lvdisplay} ||= $lvdisplay;

    my $self = bless( \%opts, $class );

    return $self;
}

sub _trim
{
    my $s = $[0];
    $s =~ s/^\s*//g;
    $s =~ s/\s*$//g;
    return $s;
}

my @vg_descriptors = qw(VOLUME_GROUP VG_PERMISSION VG_STATE VG_DESCRIPTORS
      MAX_LVS LVS OPEN_LVS VG_LG_MAXSIZE MAX_PVS TOTAL_PVS
      ACTIVE_PVS VG_SIZE PP_SIZE TOTAL_PPS
      USED_PPS FREE_PPS VG_IDENTIFIER);

sub get_physical_volumes
{
    my $self = $_[0];
    my @vgs;

    my ( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf ) =
      IPC::Cmd::run( command => [ $self->{vgdisplay} ],
                     verbose => 0, );

    if ($success)
    {
	chomp $stdout_buf->[0];
	my @outbuf = split($stdout_buf->[0]);
        foreach my $line ( @outbuf )
        {
            $line = _trim($line);

            my @data = split( m/:/, $line, 17 );
	    next if( scalar @data < 17 );
	    my %vgdata = zip( @vg_descriptors, @data );
            push( @vgs, \%vgdata );
        }
    }

    return @vgs;
}

my @lv_descriptors = qw(LOGICAL_VOLUME VOLUME_GROUP LV_PERMISSION LV_STATE LV_NUMBER
      LV_COUNT LV_SIZE LV_EXT_AMOUNT LV_EXT_ALLOC LV_POLICY
      LV_READAHEAD LV_MAJOR LV_MINOR LV_MAPPED_PATH);

sub get_logical_volumes
{
    my $self = $_[0];
    my @lvs;

    my ( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf ) =
      IPC::Cmd::run( command => [ $self->{lvdisplay} ],
                     verbose => 0, );

    if ($success)
    {
	chomp $stdout_buf->[0];
	my @outbuf = split($stdout_buf->[0]);
        foreach my $line ( @outbuf )
        {
            $line = _trim($line);

            my @data = split( m/:/, $line, 13 );
	    next if( scalar @data < 13 );

            if ( -r $data[0] )
            {
                $data[13] = readlink( $data[0] );
            }
            else
            {
                $data[13] = undef;
            }
	    my %lvdata = zip( @lv_descriptors, @data );
            push( @lvs, \%lvdata );
        }
    }

    return @lvs;
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

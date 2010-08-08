package Sys::VolumeGroups;

use warnings;
use strict;

require 5.008;
require Module::Pluggable::Object;

=head1 NAME

Sys::VolumeGroups - Retrieve list of volume groups, logical volumes and their properties

=cut

our $VERSION = '0.001';


=head1 SYNOPSIS

    my $sysvgs = Sys::VolumeGroups->new();
    my @vgs = $sysvgs->get_physical_volumes();
    print "Volume groups: ", join( ", ", map { $_->{VOLUME_GROUP} } @vgs ), "\n";
    my @lvs = $sysvgs->get_logical_volumes();
    print "Logical volumes: ", join( ", ", map { $_->{LOGICAL_VOLUME} } @lvs ), "\n";

=head1 SUBROUTINES/METHODS

=head2 new

Instantiates new Sys::VolumeGroups object. Attributes can be specified
for used finder (of type L<Module::Pluggable::Object>). Additionally,

=over 4

=item C<only_loaded>

Use only plugins which are still loaded.

=back

can be specified with a true value. This forces to grep C<%INC> instead
of using Module::Pluggable.

=cut

sub new
{
    my ( $class, %attrs ) = @_;
    my $self = bless( { plugins => [], }, $class );

    my $only_loaded = delete $attrs{only_loaded};

    if ($only_loaded)
    {
        my @search_path = __PACKAGE__ eq $class ? (__PACKAGE__) : ( __PACKAGE__, $class );
        foreach my $path (@search_path)
        {
            $path =~ s|::|/|g;
            $path .= "/";
            my @loadedModules = grep { 0 == index( $_, $path ) } keys %INC;
            foreach my $module (@loadedModules)
            {
                $module =~ s|/|::|;
                $module =~ s/\.pm$//;
                next unless ( $module->can('usable') && $module->usable() );
                push( @{ $self->{plugins} }, $module->new() );
            }
        }
    }
    else
    {
        %attrs = (
                   require     => 1,
                   search_path => [ __PACKAGE__ eq $class ? __PACKAGE__ : ( __PACKAGE__, $class ) ],
                   inner       => 0,
                   %attrs,
                 );
        my $finder  = Module::Pluggable::Object->new(%attrs);
        my @plugins = $finder->plugins();
        foreach my $plugin (@plugins)
        {
            next unless ( $plugin->can('usable') && $plugin->usable() );
            push( @{ $self->{plugins} }, $plugin->new() );
        }
    }

    return $self;
}

=head2 get_physical_volumes

=cut

sub get_physical_volumes
{
    my $self = $_[0];
    my @vgs;

    foreach my $plugin (@{$self->{plugins}})
    {
	push( @vgs, $plugin->get_physical_volumes() );
    }

    return @vgs;
}

=head2 get_logical_volumes

=cut

sub get_logical_volumes
{
    my $self = $_[0];
    my @lvs;

    foreach my $plugin (@{$self->{plugins}})
    {
	push( @lvs, $plugin->get_logical_volumes() );
    }

    return @lvs;
}

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-sys-volumegroups at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sys-VolumeGroups>.  I
will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sys::VolumeGroups

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sys-VolumeGroups>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sys-VolumeGroups>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Sys-VolumeGroups>

=item * Search CPAN

L<http://search.cpan.org/dist/Sys-VolumeGroups/>

=back

=head1 RESOURCES AND CONTRIBUTIONS

There're several ways how you can help to support future development: You
can hire the author to implement the features you require at most (this
also defines priorities), you can negotiate a support and maintenance
contract with the company of the author and you can provide tests and
patches. Further, you can submit documentation and links to resources to
improve or add volume group managers or grant remote access to machines
with insufficient supported volume managers, file systems with volume
manager capabilities or storage systems.

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Sys::VolumeGroups

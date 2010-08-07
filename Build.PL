use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Sys::VolumeGroups',
    license             => 'perl',
    dist_author         => q{Jens Rehsack <rehsack@cpan.org>},
    dist_version_from   => 'lib/Sys/VolumeGroups.pm',
    build_requires => {
        'Test::More' => "0.90",
    },
    requires            => {
	'IPC::Open3'        => 0,
	'IPC::Cmd'          => 0,
	'List::MoreUtils'   => '0.22',
	'Module::Pluggable' => '3.9',
    },
    recommends          => {
	'IPC::Run'    => 0,
    },
    create_readme       => 1,
    add_to_cleanup      => [ 'Sys-VolumeGroups-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();

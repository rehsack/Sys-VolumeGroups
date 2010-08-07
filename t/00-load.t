#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Sys::VolumeGroups' ) || print "Bail out!
";
}

diag( "Testing Sys::VolumeGroups $Sys::VolumeGroups::VERSION, Perl $], $^X" );

#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'CHI::Driver::SharedMem' ) || print "Bail out!
";
}

diag( "Testing CHI::Driver::SharedMem $CHI::Driver::SharedMem::VERSION, Perl $], $^X" );

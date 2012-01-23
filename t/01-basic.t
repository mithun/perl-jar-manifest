#!perl

####################
# LOAD CORE MODULES
####################
use strict;
use warnings FATAL => 'all';
use Test::More;

# Autoflush ON
local $| = 1;

####################
# LOAD DIST MODULE
####################
use Jar::Manifest qw(Dump Load);

my $str1 = <<"MANIFEST_MF";
Manifest-Version: 1.0
Built-By: JAPH

Name: org/myapp/foo
Implementation-Version: 1.5
My-Random-Key: alalalalalalalalalalalalalalalalalalalalalalalalalalalal
 alalalalalalalalalalalalalalalalalalalalalalalalalalalalala
Implementation-URL: http://foo.com
MANIFEST_MF

my $m1 = {
    main => {
        'Manifest-Version' => '1.0',
        'Built-By'         => 'JAPH',
    },
    entries => [
        {
            'Name'                   => 'org/myapp/foo',
            'Implementation-Version' => '1.5',
            'My-Random-Key' =>
                'alalalalalalalalalalalalalalalalalalalalalalalalalalalalalalalalalalalalalalalalalalalalalalalalalalalalalalalalala',
            'Implementation-URL' => 'http://foo.com',
        }
    ],
};

# Check Load
is_deeply( Load($str1), $m1 );

# Check Dump
ok( Dump($m1) eq $str1 );

# Done
done_testing();
exit 0;

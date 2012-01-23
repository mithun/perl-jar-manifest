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
Built-By: JAPH
Manifest-Version: 1.0

Name: org/myapp/foo
Implementation-URL: http://foo.com
Implementation-Version: 1.5
My-Random-Key: alalalalalalalalalalalalalalalalalalalalalalalalalalalal
 alalalalalalalalalalalalalalalalalalalalalalalalalalalalala
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
my $m2 = Load($str1);
is_deeply( $m1, $m2 );

# Check Dump
my $str2 = Dump($m1);
ok( $str1 eq $str2 );

# Done
done_testing();
exit 0;

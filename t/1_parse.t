# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

use Test::More tests => 7;
BEGIN { use_ok('Config::Properties') };

my $cfg=Config::Properties->new();
$cfg->load(\*DATA);

is ($cfg->getProperty('foo'), 'one', 'foo');
is ($cfg->getProperty('eq=ua:l'), 'jamon', 'eq=ual');
is ($cfg->getProperty('Bar'), "maybe one\none\tone\r", 'Bar');
is ($cfg->getProperty('more'), 'another configuration line', 'more');
is ($cfg->getProperty('less'), "who said:\tless ??? ", 'less');
is ($cfg->getProperty("cra\n=: \\z'y'"), 'jump', 'crazy');

__DATA__
# hello
foo=one
    Bar : maybe one\none\tone\r
eq\=ua\:l jamon

more : another \
    configuration \
    line
less= who said:\tless ??? 

cra\n\=\:\ \\z'y' jump

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

use Test::More tests => 13;
BEGIN { use_ok('Config::Properties') };

my $cfg=Config::Properties->new();
for (1) {
    eval { $cfg->load(\*DATA) };
}
ok (!$@, "don't use \$_");


is ($cfg->getProperty('foo'), 'one', 'foo');
is ($cfg->getProperty('eq=ua:l'), 'jamon', 'eq=ual');
is ($cfg->getProperty('Bar'), "maybe one\none\tone\r", 'Bar');
is ($cfg->getProperty('more'), 'another configuration line', 'more');
is ($cfg->getProperty('less'), "who said:\tless ??? ", 'less');
is ($cfg->getProperty("cra\n=: \\z'y'"), 'jump', 'crazy');
is ($cfg->getProperty("#nocmt"), 'good', 'no comment 1');
is ($cfg->getProperty("!nocmt"), 'good', 'no comment 2');
is ($cfg->getProperty("lineend1"), 'here', 'line end 1');
is ($cfg->getProperty("lineend2"), 'here', 'line end 2');
is ($cfg->getProperty("\\\\machinename\\folder"),
    "\\\\windows\\ style\\path",
    'windows style path');

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

\#nocmt = good
#nocmt = bad

\!nocmt = good
!nocmt = bad

lineend1=here
lineend2=here

\\\\machinename\\folder = \\\\windows\\ style\\path

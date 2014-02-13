use strict;
use utf8;
use Test::More tests => 1;
use Config::Properties;

my $cfg=Config::Properties->new(file => 't/utf8.props', utf8 => 1);
is ($cfg->getProperty('foo'), 'ばあ', 'foo');

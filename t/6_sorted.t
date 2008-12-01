use Test::More tests => 2;

use Config::Properties;
use File::Temp qw(tempfile);

my $cfg=Config::Properties->new();
$cfg->load(\*DATA);

my ($fh, $fn)=tempfile()
    or die "unable to create temporal file to save properties";

$cfg->deleteProperty('dos');
$cfg->setProperty('cinco', '5');
$cfg->setProperty('tres', '6!');

$cfg->store($fh, "test header");
close $fh;
open CFG, '<', $fn
    or die "unable to open tempory file $fn";

undef $/;
$contents=<CFG>;

# print STDERR "$fn\n$contents\n";

ok($contents=~/uno.*tres.*cuatro.*cinco/s,
   "order preserved");

unlink $fn;

ok((not -e $fn), "delete test file");

__DATA__

uno = 1u
dos = 2u
tres = 3u
cuatro = 4u


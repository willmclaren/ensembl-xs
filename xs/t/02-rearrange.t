#!perl -T
use 5.8.9;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 22;

BEGIN { use_ok('Bio::EnsEMBL::XS'); }

#
# Test exceptions, e.g. missing arguments
#
# throws_ok doesn't catch the exception
# throws_ok { &Bio::EnsEMBL::XS::Utils::Argument::rearrange() }
#   qr/missing argument/, 'call without arguments';
my $test_name = 'call without arguments';
eval { &Bio::EnsEMBL::XS::Utils::Argument::rearrange() };
if ($@) { ok($@ =~ 'missing arguments', $test_name); } else { ok(0, $test_name); }

$test_name = 'call with not enough arguments';
eval { &Bio::EnsEMBL::XS::Utils::Argument::rearrange([]) };
if ($@) { ok($@ =~ 'missing arguments', $test_name); } else { ok(0, $test_name); }

$test_name = 'first argument is array_ref';
eval { &Bio::EnsEMBL::XS::Utils::Argument::rearrange(1, 2) };
if ($@) { ok($@ =~ 'array ref', $test_name); } else { ok(0, $test_name); }

$test_name = 'first argument must contain elements';
eval { &Bio::EnsEMBL::XS::Utils::Argument::rearrange([], 2) };
if ($@) { ok($@ =~ 'elements', $test_name); } else { ok(0, $test_name); }

#
# Test passing arguments with no hyphen,
# should return the inputs straight out
#
my ($one, $two, $three, $four) =
  &Bio::EnsEMBL::XS::Utils::Argument::rearrange([qw(ONE TWO THREE)], 
						1, 2, 3);
ok($one == 1 && $two == 2 && $three == 3 && !$four, 'arguments returned as-is');

sub mysub {
  my ($one, $two, $three, $four) = 
    Bio::EnsEMBL::XS::Utils::Argument::rearrange([qw/one two three four/], @_);
}

($one, $two, $three, $four) = mysub(1,2,3,4);
ok($one == 1 && $two == 2 && $three == 3 && $four == 4, 'arguments returned as-is');

($one, $two, $three, $four) = mysub(undef,2,3,4);
ok(!$one && $two == 2 && $three == 3 && $four == 4, 'arguments returned as-is');

#
# Test expected mode of operation
#
my @args = ('-TwO' => 2,
            '-oNE' => 1,
            '-THreE' => 3);
($one, $two, $three) = 
  Bio::EnsEMBL::XS::Utils::Argument::rearrange(['one','tWO','THRee'], @args);
ok($one == 1, 'argument: ONE');
ok($two == 2, 'argument: TWO');
ok($three == 3, 'argument: THREE');

#
# Test when order != keys args
#
@args = ('-user',
	 'ensadmin',
	 '-species',
	 'circ',
	 '-dbname',
	 'test_db_circ_core',
	 '-host',
	 '127.0.0.1',
	 '-group',
	 'core',
	 '-pass',
	 'ensembl',
	 '-port',
	 3306,
	 '-driver',
	 'mysql');

my ($host, $is_multispecies, $species, $user, $species_id, $group, $con, $dnadb,
    $no_cache, $dbname ) =
  Bio::EnsEMBL::XS::Utils::Argument::rearrange(
					       [
                  'HOST', #'PORT', 'USER', 'PASS', 'DRIVER', 
		  'MULTISPECIES_DB', 'SPECIES', 'USER', 'SPECIES_ID', 'GROUP',
		  'DBCONN',          'DNADB',   'NO_CACHE',   'DBNAME'
		 ], @args);
is($host, '127.0.0.1', 'argument: host');
is($is_multispecies, undef, 'argument: multispecies');
is($species, 'circ', 'argument: species');
is($user, 'ensadmin', 'argument: user');
is($species_id, undef, 'argument: species_id');
is($group, 'core', 'argument: group');
is($con, undef, 'argument: con');
is($dnadb, undef, 'argument: dnadb');
is($no_cache, undef, 'argument: no_cache');
is($dbname, 'test_db_circ_core', 'argument: dbname');

my $keys = [qw/one two three four five six seven eight nine ten/];
my @two_output = Bio::EnsEMBL::XS::Utils::Argument::rearrange($keys, (-SIX => 6, -THrEE => 3));
ok($two_output[0] == 3 && $two_output[1] == 6, 'two output list');

my @six_output = Bio::EnsEMBL::XS::Utils::Argument::rearrange($keys, (-SIX => 6, -THREE => 3, -ten => 10, -four => 4, -ONE => 1, -TWO => 2));
ok($six_output[0] == 1 && $six_output[1] == 2 && $six_output[2] == 3 && $six_output[3] == 4 && $six_output[4] == 6 && $six_output[5] == 10, 'six output list');

# test with large artificial argument list
SKIP: {
  skip 'Cannot continue testing: List::Util not installed', 1
    unless eval { require List::Util; 1 };

  @args = ("0000001" .. "1000000");

  my @random_args;
  for my $i (&List::Util::shuffle(@args)) {
    push @random_args, "-$i", $i;
  }

  my @args1 = Bio::EnsEMBL::XS::Utils::Argument::rearrange([@args], @random_args);

  is_deeply(\@args, \@args1, 'call with 1M randomly shuffled arguments');
}
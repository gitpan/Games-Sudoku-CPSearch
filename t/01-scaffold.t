#!perl -T

use Test::More tests => 4;
use Games::Sudoku::CPSearch;

my $easy_unsolved = "..3.2.6..9..3.5..1..18.64....81.29..7.......8..67.82....26.95..8..2.3..9..5.1.3..";
my $easy_solved = "483921657967345821251876493548132976729564138136798245372689514814253769695417382";

my $o = Games::Sudoku::CPSearch->new($easy_unsolved);

is(join("", @{$o->rows()}),"ABCDEFGHI");
is(join("", @{$o->cols()}),"123456789");

my $cross = <<END;
A1A2A3A4A5A6A7A8A9B1B2B3B4B5B6B7B8B9
C1C2C3C4C5C6C7C8C9D1D2D3D4D5D6D7D8D9
E1E2E3E4E5E6E7E8E9F1F2F3F4F5F6F7F8F9
G1G2G3G4G5G6G7G8G9H1H2H3H4H5H6H7H8H9
I1I2I3I4I5I6I7I8I9
END

$cross =~ s/\s//g;
is(join("", $o->squares()), $cross);
is($o->puzzle(), $easy_unsolved);

=pod
# unitlist
diag("unitlist:\n");
foreach my $u ($o->unitlist()) {
	diag(join(",", @$u) . "\n");
}

# units
diag("units:\n");
foreach my $s ($o->squares()) {
	foreach my $u ($o->units($s)) {
		diag($s . " " . join(",",@$u) . "\n");
	}
}

# peers
diag("peers:\n");
foreach my $s ($o->squares()) {
	my $output = "$s ";
	$output .= join(",", $o->peers($s));
	diag("$output\n");
}

diag($o->solution($o->fullgrid()));
diag($o->solution($o->assign($o->fullgrid(),'I9','9')));
=cut

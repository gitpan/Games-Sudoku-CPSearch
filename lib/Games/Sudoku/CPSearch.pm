package Games::Sudoku::CPSearch;

use warnings;
use strict;
use 5.008;
use List::MoreUtils qw(all mesh);

our $VERSION = '0.07';

sub new {
	my ($class) = @_;

	my $rows = [qw(A B C D E F G H I)];
	my $cols = [qw(1 2 3 4 5 6 7 8 9)];
	my $squares = $class->cross($rows, $cols);

	my @unitlist = ();
	foreach my $c (@$cols) {
		push @unitlist, $class->cross($rows, [$c]);
	}
	foreach my $r (@$rows) {
		push @unitlist, $class->cross([$r], $cols);
	}
	foreach my $r ([qw(A B C)],[qw(D E F)],[qw(G H I)]) {
		foreach my $c ([qw(1 2 3)],[qw(4 5 6)],[qw(7 8 9)]) {
			push @unitlist, $class->cross($r, $c);	
		}
	}

	my %units;
	foreach my $s (@$squares) {
		$units{$s} = [];
		foreach my $unit (@unitlist) {
			foreach my $s2 (@$unit) {
				if ($s eq $s2) {
					push @{$units{$s}}, $unit;
					last;
				}
			}
		}
	}

	my %peers;
	foreach my $s (@$squares) {
		$peers{$s} = [];
		foreach my $u (@{$units{$s}}) {
			foreach my $s2 (@$u) {
				push(@{$peers{$s}}, $s2) if ($s2 ne $s);
			}
		}
	}

	my $self = {
		_unitlist => \@unitlist,
		_rows => $rows,
		_cols => $cols,
		_squares => $squares,
		_units => \%units,
		_peers => \%peers,
		_puzzle => "",
		_solution => "",
	};

	bless $self, $class;
}

sub unitlist {
	my ($self) = @_;
	return @{$self->{_unitlist}};
}

sub rows {
	my ($self) = @_;
	return $self->{_rows};
}

sub cols {
	my ($self) = @_;
	return $self->{_cols};
}

sub units {
	my ($self, $s) = @_;
	return @{$self->{_units}{$s}};
}

sub peers {
	my ($self, $s) = @_;
	return @{$self->{_peers}{$s}};
}

sub squares {
	my ($self) = @_;
	return @{$self->{_squares}};
}

sub cross {
	my ($class, $a, $b) = @_;
	my @cross = ();
	foreach my $x (@$a) {
		foreach my $y (@$b) {
			push @cross, "$x$y";
		}
	}
	return \@cross; 
}

sub fullgrid {
	my ($self) = @_;
	my %grid;
	foreach my $s ($self->squares()) {
		$grid{$s} = "123456789";
	}
	return \%grid;
}

sub propagate {
	my ($self) = @_;
	my @d = split(//, $self->puzzle);
	my @s = $self->squares();
	my @z = mesh @s, @d;
	my $grid = $self->fullgrid();
	while (scalar(@z) > 0) {
		my ($s, $d) = splice(@z,0,2);
		next unless ($d =~ /^\d$/);
		return undef unless defined $self->assign($grid, $s, $d);
	}
	return $grid;
}

sub assign {
	my ($self, $grid, $s, $d) = @_;
	my @delete = grep {$_ ne $d} split(//, $grid->{$s});
	return $grid if (scalar(@delete) == 0);
	my @results;
	foreach my $del (@delete) { 
		$grid = $self->eliminate($grid, $s, $del);
		push @results, $grid;
	}
	return $grid if all { defined($_) } @results;
	return undef;
}

sub eliminate {
	my ($self, $grid, $s, $d) = @_;
	unless ((defined $grid->{$s}) && ($grid->{$s} =~ /$d/)) {
		return $grid;
	}
	$grid->{$s} =~ s/$d//;
	my $len = length($grid->{$s});
	return undef if ($len == 0);
	if ($len == 1) {
		foreach my $peer ($self->peers($s)) {
			$grid = $self->eliminate($grid, $peer, $grid->{$s});
			return undef unless defined $grid;
		}
	}

	foreach my $unit ($self->units($s)) {
		my @dplaces = grep { $grid->{$_} =~ /$d/ } @$unit;
		my $locations = scalar @dplaces;
		return undef if ($locations == 0);
		if ($locations == 1) {
			$grid = $self->assign($grid, $dplaces[0], $d);
			return undef unless defined $grid;
		}
	}	
	return $grid;
}

sub search {
	my ($self, $grid) = @_;
	return undef unless defined $grid;
	return $grid if (all {length($grid->{$_}) == 1} $self->squares());
	# solved!
	my @sorted = sort {length($grid->{$a}) <=> length($grid->{$b})}
		grep {length($grid->{$_}) > 1} $self->squares();
	my $fewest_digits = shift @sorted;
	my $result = undef;
	foreach my $d (split(//, $grid->{$fewest_digits})) {
		my %grid_copy = %$grid;	
		$result =
			$self->search($self->assign(\%grid_copy, $fewest_digits, $d));
		return $result if defined $result;
	}
	return $result;
}

sub solution {
	my ($self) = @_;
	return $self->{_solution};
}

sub solve {
	my ($self) = @_;
	my $solution = $self->search($self->propagate());
	return undef unless (defined $solution);
	$self->{_solution} = "";
	foreach my $s ($self->squares()) {
		$self->{_solution} .= $solution->{$s};
	}
	return $self->{_solution};
}

sub puzzle {
	my ($self) = @_;
	return $self->{_puzzle};
}

sub set_puzzle {
	my ($self, $puzzle) = @_;
	return undef
		unless ((length($puzzle) == 81) && ($puzzle =~ /^[\d\.\-]+$/)); 

	$puzzle =~ s/0/\./g; # 0 is a digit, which makes things hairy.

	$self->{_puzzle} = $puzzle;
	return $self->{_puzzle};
}

1; # End of Games::Sudoku::CPSearch

=head1 NAME

Games::Sudoku::CPSearch - Solve Sudoku problems quickly.

=head1 VERSION

Version 0.07

=cut

=head1 SYNOPSIS

	use Games::Sudoku::CPSearch;

	my $puzzle = <<PUZZLE;
	4.....8.5
	.3.......
	...7.....
	.2.....6.
	....8.4..
	....1....
	...6.3.7.
	5..2.....
	1.4......
	PUZZLE

	$puzzle =~ s/\s//g;

	my $solved = <<SOLVED;
	417369825
	632158947
	958724316
	825437169
	791586432
	346912758
	289643571
	573291684
	164875293
	SOLVED

	$solved =~ s/\s//g;

	my $sudoku = Games::Sudoku::CPSearch->new();
	die "bad puzzle" unless defined $sudoku->set_puzzle($puzzle);
	$sudoku->solve();
	print $sudoku->solution(), "\n";

=head1 DESCRIPTION

This module solves a Sudoku puzzle using the same constraint propagation technique/algorithm explained on Peter Norvig's website (http://norvig.com/sudoku.html), and implemented there in Python.

=head1 METHODS

=over 4

=item $sudoku_object = Games::Sudoku::CPSearch->new()

Initializes the sudoku solving framework.

=item $sudoku_object->solve()

Solves the puzzle. Returns the solution as a flat 81 character string.

=item $sudoku_object->set_puzzle($puzzle)

Sets the puzzle to be solved. The only parameter is the 81 character string
representing the puzzle. The only characters allowed are [0-9\.\-].
Sets the puzzle to be solved. You can then reuse the object:

	my $o = Games::Sudoku::CPSearch->new();
	$o->set_puzzle($puzzle);
	print $o->solve(), "\n";
	$o->set_puzzle($another_puzzle);
	print $o->solve(), "\n";

=item $o->solution()

Returns the solution string, or the empty string if there is no solution.

=back

=head1 INTERNAL METHODS

These methods are exposed but are not intended to be used.

=over 4

=item $o->fullgrid()
Returns a hash with squares as keys and "123456789" as each value.

=item $o->puzzle()

Returns the object's puzzle as an 81 character string.

=item $o->unitlist($square)

Returns an list of sudoku "units": rows, columns, boxes for a given square.

=item $o->propagate()

Perform the constraint propagation on the Sudoku grid.

=item $o->eliminate($grid, $square, $digit)

Eliminate digit from the square in the grid.

=item $o->assign($grid, $square, $digit)

Assign digit to square in grid. Mutually recursive with eliminate().

=item $o->rows()

Returns array of row values: A-I

=item $o->cols()

Returns array of column values: 1-9

=item $o->squares()

Return list of all the squares in a Sudoku grid:
A1, A2, ..., A9, B1, ..., I1, ..., I9

=item $o->units($square)

Return list of all the units for a given square.

=item $o->peers($square)

Return list of all the peers for a given square.

=item $o->search()

Perform search for a given grid after constraint propagation. 

=item $o->cross()

Return "cross product" of 2 arrays.

=back

=head1 AUTHOR

Martin-Louis Bright, C<< <mlbright at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-sudoku-cpsearch at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Sudoku-CPSearch>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::Sudoku::CPSearch


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Sudoku-CPSearch>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-Sudoku-CPSearch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-Sudoku-CPSearch>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-Sudoku-CPSearch>

=back


=head1 ACKNOWLEDGEMENTS

Peter Norvig, for the explanation/tutorial and python code at
http://www.norvig.com/sudoku.html.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Martin-Louis Bright, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
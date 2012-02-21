#!/usr/bin/perl
use strict;

=head1 NAME

8-bit grey code generator

=head1 USAGE

To run this program just type

  ./grey_code_generator.pl

It will display the sequence of values for an
8-bit grey code counter starting from zero.

=head1 DESIGN

There are two main components to this counter.

The first is the special cases at the start of
each sequence.  The first bit changes at sequence 1,
second at 2, third at 4, etc.

The second is the repeating sequence after the
special cases.
The first bit changes every 2 bits, the second
every 4, the third every 8, fourth every 16, etc.
(Do you see a pattern yet?)

The modulo operator is used by subtracting the offset
and checking if the required number of numbers has
changed.

This design could be easily expanded to any number of bits.

=cut

# 8-bits
#  [MSB ... LSB]
my $bits = [0, 0, 0, 0, 0, 0, 0, 0];

for (my $n = 0; $n < 256; $n++) {

	if (0 == $n) {
		$bits = [0, 0, 0, 0, 0, 0, 0, 0];
	} elsif (1 == $n) {
		$bits->[7] = 1;
	} elsif (2 == $n) {
		$bits->[6] = 1;
	} elsif (4 == $n) {
		$bits->[5] = 1;
	} elsif (8 == $n) {
		$bits->[4] = 1;
	} elsif (16 == $n) {
		$bits->[3] = 1;
	} elsif (32 == $n) {
		$bits->[2] = 1;
	} elsif (64 == $n) {
		$bits->[1] = 1;
	} elsif (128 == $n) {
		$bits->[0] = 1;
	} elsif (0 == (($n - 1) % 2)) { 
		$bits->[7] = bnot($bits->[7]);
	} elsif (0 == (($n - 2) % 4)) {
		$bits->[6] = bnot($bits->[6]);
	} elsif (0 == (($n - 4) % 8)) {
		$bits->[5] = bnot($bits->[5]);
	} elsif (0 == (($n - 8) % 16)) {
		$bits->[4] = bnot($bits->[4]);
	} elsif (0 == (($n - 16) % 32)) {
		$bits->[3] = bnot($bits->[3]);
	} elsif (0 == (($n - 32) % 64)) {
		$bits->[2] = bnot($bits->[2]);
	} elsif (0 == (($n - 64) % 128)) {
		$bits->[1] = bnot($bits->[1]);
	} elsif (0 == (($n - 128) % 256)) {
		$bits->[0] = bnot($bits->[0]);
	}

	print str_bits($bits) . "  $n\n";
}

# binary not operation
sub bnot {
	if (1 == $_[0]) {
		0;
	} else {
		1;
	}
}

# convert the array of bits in to a string
sub str_bits {
	my $bits = shift;

	my $str = join " ", @$bits;

	return $str;
}


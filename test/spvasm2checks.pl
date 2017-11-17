#!/usr/bin/perl -w

# Copyright 2017 The Clspv Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Convert a SPIR-V assembly listing into a list of FileCheck check assertions.

use strict;
use Getopt::Long;

# Only replace numeric IDs?
my $numeric_only = 0;

# Can we assume RE2 is the matcher?  It supports more readable expressions.
my $assume_re2 = 0;

GetOptions("numeric" => \$numeric_only,
	   "re2"     => \$assume_re2,
          ) or die ("Bad option");

# Key is a defined id.
my %id = ();

my $replace_pat = $numeric_only ? '\d+' : '\S+';
my $id_pat = $assume_re2 ? '\w+' : '[0-9a-zA-Z_]+';

while(<>) {
  chomp;
  my $line = $_;
  $line =~ s/^\s+//;
  $line =~ s/\s+$//;
  my @words = split(/\s+/, $line);
  my @parts = qw(// CHECK:);
  foreach my $word (@words) {
    if ($word =~ m/^%($replace_pat)/o) {
      my $name = $1;
      if (defined $id{$name}) {
	# This is a use, not the first mention.
	push @parts, "[[_$name]]";
      } else {
	# This is first use of the pattern, and therefore a definition.
	# Write a match rule.
	push @parts, "[[_$name:%$id_pat]]";
	# Also remember that we made this defnition.
	$id{$name} = 1;
      }
    } else {
      # Not an Id.  Emit it verbatim
      push @parts, $word;
    }
  }
  print join(' ', @parts), "\n";
}

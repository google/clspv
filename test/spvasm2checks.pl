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

# Key is a defined id.
my %id = ();

while(<>) {
  chomp;
  my $line = $_;
  $line =~ s/^\s+//;
  $line =~ s/\s+$//;
  my @words = split(/\s+/, $line);
  my @parts = qw(// CHECK:);
  foreach my $word (@words) {
    if ($word =~ m/^%(.*)/) {
      my $name = $1;
      if (defined $id{$name}) {
	# This is a first use
	push @parts, "[[_$name]]"
      } else {
	# This is a definition.  Write a match rule
	push @parts, "[[_$name:%[a-zA-Z0-9_]+]]"
      }
    } else {
      # Not an Id.  Emit it verbatim
      push @parts, $word;
    }
  }
  print join(' ', @parts), "\n";
}

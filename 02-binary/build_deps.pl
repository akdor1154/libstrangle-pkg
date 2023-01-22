#!/usr/bin/env perl

use strict;
use warnings;

use Dpkg::Control::Info;
use Dpkg::Deps;

my $control = Dpkg::Control::Info->new($ARGV[0]);
my $fields = $control->get_source();
my $build_depends = deps_parse($fields->{'Build-Depends-Arch'});
my @build_deps_list = split(/,/, $build_depends);
print join(' ', @build_deps_list);
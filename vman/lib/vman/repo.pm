### PAKCAGE REPO ###################################################################################################################
package vman::repo;
use strict;
use warnings;
use feature 'say';
use Data::Dumper;
use Data::Dump 'dump';

use parent 'vman::data';

sub remSpace ($) { my $str = shift; $str =~ s/^\s*(.*)\s*$/$1/; return $str; }

sub new {
    my $class       = shift;
    my $self        = $class->SUPER::new(@_);
    bless $self, $class;
}

sub parse {
    my $self        = shift;
    my $inputText   = shift;
    my @data;
    my $res = {};
    my @versions;
    my $pattern = '(?:^\w+(?:\s+\d+.*?zip\n)+)+';
    my $key;

    foreach my $row ($inputText =~ m/$pattern/gm) {
        @data       = split /\n/, $row;
        $key        = $data[0];
        @versions   = map { remSpace $_ } @data[1..$#data];
        my $ver     = {};

        for(@versions){
            my($k, $v) = split /\s+/, $_;
            $ver->{$k} = $v;
        }

        $res->{$key} = $ver;
    }

    return $res;
}

sub toString {
    my $self        = shift;
    my $data        = $self->{data};
    my $res         = '';
    # no strict 'refs';

    foreach my $app (sort keys %$data) {
        $res .= "$app" . "\n";
        foreach my $ver (sort keys %{$data->{$app}}) {
            $res .= "    $ver    $data->{$app}{$ver}" . "\n";
        }
        $res .= "\n";
    }

    return $res;
}

1;
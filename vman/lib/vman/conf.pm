### PAKCAGE CONF ###################################################################################################################
package vman::conf;
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
    my $pattern = '^\w+\s+.*';

    foreach my $row ($inputText =~ m/$pattern/gm) {
        # my($app, $ver, $path)       = split /\s+/, $row;
        my($app, $ver, $path)       = $row =~ m/^(.*?)\s+(.*?)\s+(.*?)$/;
        # $res->{$app} = $path;
        $res->{$app} = { vers => $ver, path => $path };
    }

    return $res;
}

sub toString {
    my $self        = shift;
    my $data        = $self->{data};
    my $res;

    foreach my $app (sort keys %$data) {
        $res .= "$app $data->{$app}{vers} $data->{$app}{path}\n";
    }

    return $res;
}

1;
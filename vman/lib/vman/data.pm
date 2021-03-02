### PAKCAGE DATA ###################################################################################################################
package vman::data;
use strict;
use warnings;
use feature 'say';
use Data::Dumper;
# use Data::Dump 'dump';

# $Data::Dumper::Purity = 1;
$Data::Dumper::Terse = 1;
# $Data::Dumper::Pair = " : ";
$Data::Dumper::Useqq = 1;
$Data::Dumper::Indent = 3;

sub remSpace ($) { my $str = shift; $str =~ s/^\s*(.*)\s*$/$1/; return $str; }

sub new {
    my $self        = bless {}, shift;
    my $datafile    = shift or die "need data file name!!!";
    my $data        = shift || {};

    $self->{file}   = vman::fs->new($datafile);
    $self->read() if ($self->{file}->exists);
    if (!$self->{file}->exists){
        $self->{data} = $data;
        $self->write();
    }

    return $self;
}

sub data {
    my $self        = shift;
    my $key         = shift;
    my $value       = shift;

    return $self->{data}{$key} if ($key && !$value);
    
    if ($key && $value) {
        %{$self->{data}{$key}} = (%{$self->{data}{$key}}, %$value);
        $self->write();
    }

    return $self->{data};
}

sub read {
    # no strict;
    my $self        = shift;

    $self->{raw}   = $self->{file}->read();

    if ( exists &{caller(1).'::parse'} ) {
        $self->{data}   = $self->parse($self->{raw});
    } else {
        $self->{data}   = eval $self->{raw};
    }

    return $self->{data};
}

sub write {
    my $self        = shift;

    if ( exists &{caller(1).'::toString'} ) {
        $self->{file}->write($self->toString());
    } else {
        $self->{file}->write(Dumper $self->{data});
    }

}

1;
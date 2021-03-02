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

    if ($self->{file}->exists) {
        $self->read();
    } else {
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
            # no strict;
        # exists $self->{data}{$key} or die "NOT FOUND"; 

        # say "############## $key" . Dumper($value);

        if(ref \$value eq 'SCALAR'){
            $self->{data}{$key} = $value;
        } else {
            $self->{data}{$key} = {} if !$self->{data}{$key};
            %{$self->{data}{$key}} = (%{$self->{data}{$key}}, %$value);
        }
        
        # $self->{data}{$key} = $value;

        $self->write();
    }

    return $self->{data};
}

sub read {
    # no strict;
    my $self        = shift;
    my ($child)     = $self =~ m/^(.*?)\=.*?$/;
    $self->{raw}   = $self->{file}->read();

    if ( exists &{$child.'::parse'} ) {
        $self->{data}   = $self->parse($self->{raw});
    } else {
        $self->{data}   = eval $self->{raw};
    }

    return $self->{data};
}

sub write {
    my $self        = shift;
    my ($child)     = $self =~ m/^(.*?)\=.*?$/;

    if ( exists &{$child.'::toString'} ) {
        $self->{file}->write($self->toString());
    } else {
        $self->{file}->write(Dumper $self->{data});
    }

}

1;
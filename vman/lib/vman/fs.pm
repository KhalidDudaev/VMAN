### PAKCAGE FS ###################################################################################################################
package vman::fs;
use strict;
use warnings;
use feature 'say';
use Data::Dumper;
# use vman::fs::utils;

sub new {
    my $self        = bless {}, shift;
    my $file        = shift or die "need file name!!!";
    my $cwd         = vman::fs::utils->new()->cwd();
    
    $file           =~ s/^\./$cwd/sx;
    $self->{file}  = $file;

    return $self;
}

sub exists {
     my $self       = shift;
     my $filename   = $self->{file};
     return (-e $self->{file});
}

sub read {
    my $self        = shift;
    my $filename    = $self->{file};
    my $fileInner   = '';
    open(FH, '<', $filename) or die "Cannot open file $filename. $@";
    while(<FH>){
        $fileInner .= $_;
    }
    close(FH);
    return $fileInner;
}

sub write {
    my $self        = shift;
    my $filename    = $self->{file};
    my $data        = shift || die "no data for write file '$filename'";
    open(FH, '>:raw', $filename) or die "Cannot open file $filename. $!";
    print FH $data;
    close(FH);
}

1;

### PAKCAGE FS::UTILS ###################################################################################################################
package vman::fs::utils;
use strict;
use warnings;
use feature 'say';
use Data::Dumper;

sub new {
    my $package     = shift;
    my $confs       = shift || {};
    return bless $confs, $package;
}

sub cwd {
    my $self        = shift;
    my $cwd = $0;
    $cwd =~ s/\\/\//gsx;
    $cwd =~ s/^(.*)\/.*?$/$1/gsx;
    return $cwd;
}

1;
package vmanlib;

#!perl
use strict;
use warnings;
use feature 'say';
use threads;

use HTTP::Tiny;
use Archive::Extract;
use Time::HiRes qw(usleep);

use Data::Dumper;
use Data::Dump 'dump';

# $Data::Dumper::Purity = 1;
$Data::Dumper::Terse = 1;
# $Data::Dumper::Pair = " : ";
$Data::Dumper::Useqq = 1;
$Data::Dumper::Indent = 3;

my $db;
my $repo;
my $conf;
# $db[0]{'candidates'} = "AKLSDJFHASKLDJFH";

sub dataBase {
    $db = \$_[0];
}

my @exports = qw /
    readFile writeFile readDBase writeDBase getDirChilds toLeftSlash _cwd remNL getLocalDirName textToColumn download unzip setRepo repo setConf conf
/;

sub import {
    no strict;
    my $aaa = caller(0);
    for my $member (@exports) {
        *{$aaa.'::'.$member} = *{$member} if $member;
    }
}

#########################################################################################################################
sub _cwd {
    my $cwd = $0;
    $cwd =~ s/\\/\//gsx;
    $cwd =~ s/^(.*)\/.*?$/$1/gsx;
    return $cwd;
}

sub floor { my $num = shift; my $int = int $num; return $num - $int; }
sub roundUp { my $num = shift; my $floor = floor $num; return $num + (1 - $floor); }

sub remSpace ($) { my $str = shift; $str =~ s/^\s*(.*)\s*$/$1/; return $str; }

sub remNL {
    my $str = shift;
    $str =~ s/[\n\s]//gsx;
    return $str;
}

sub toLeftSlash {
    my $path = shift;
    $path =~ s/\//\\/gsx;
    return $path;
}

sub textToColumn {
    my $res         = '';
    my $arr         = shift;
    my $min_rows    = shift;
    my $with        = shift;
    my $cols        = roundUp (215 / $with);
    my $indent      = 0;
    my $act_rows    = scalar @$arr / $cols;

    $min_rows       = roundUp $act_rows if ($act_rows > $min_rows);

    my $last_row    = $min_rows + 1;
    my $count       = int (scalar @$arr / 10);
    my $colums      = $count;

    $colums         += 1 if (scalar @$arr % 10) > 0;

    $res .= "\n";
    LAST: {
        my $colpos = 1;
        for my $col (1..$colums) {
            for (1..$min_rows) {
                $last_row = $min_rows - $_;
                $res .= "\x1b[".($colpos + $indent)."C  ". shift(@$arr)."  \n";
                if (scalar @$arr == 0) {
                    $res .= "\x1b[".($min_rows + 1 - $last_row)."A"."\n";
                    last LAST;
                }
            }
            $colpos += $with;
            $res .= "\x1b[".($min_rows + 1)."A"."\n";
        }
    }
    $res .= "\x1b[".($min_rows + 1)."B"."\n";
}

sub ESC {
    "\x1b["
}
#########################################################################################################################

# sub readFile {
#     my $filename = shift;
#     my $fileInner = '';
#     open(FH, '<', $filename) or die "Cannot open file $filename. $@";
#     while(<FH>){
#         $fileInner .= $_;
#     }
#     close(FH);
#     return $fileInner;
# }

# sub writeFile {
#     my $filename    = shift;
#     my $data        = shift;
#     open(FH, '>:raw', $filename) or die "Cannot open file $filename. $!";
#     print FH $data;
#     close(FH);
# }

sub readFile { vmanlib::fs->new(shift)->read() }
sub writeFile { vmanlib::fs->new(shift)->write(shift) }

sub setRepo { $repo = vmanlib::repo->new(shift) }
sub setConf { $conf = vmanlib::conf->new(shift) }

sub repo { $repo->repo(@_) }
sub conf { $conf->conf(@_) }

sub readDBase {
    no strict;
    my $dbfile = shift;
    unless (-e $dbfile) {
        writeDBase($dbfile);
    }
    my $data = parseData(readFile($dbfile));
    return %$data;
}

sub writeDBase {
    my $db = shift;
    my $dbfile = shift;
    my $data = data2string ($db);
    writeFile($dbfile, $data);
}

sub parseData {
    my $inputText = shift;
    my @data;
    my $res = {};
    my @versions;
    foreach my $row ($inputText =~ m/^\w+\n\s+.*\n\s+.*\n\s+.*/gm) {
        @data = split /\n/, $row;
        @versions = split /\s+/, remSpace $data[1];
        push @{$res->{$data[0]}}, ([@versions], remSpace $data[2], remSpace $data[3]);
    }
    return $res;
}

sub readConf {
    no strict;
    my $dbfile = shift;
    unless (-e $dbfile) {
        writeConf();
    }
    my $data = parseConf(readFile($dbfile));
    return %$data;
}

sub writeConf {
    my $db = shift;
    my $dbfile = shift;
    my $data = data2string ($db);
    writeFile($dbfile, $data);
}

sub parseConf {
    my $inputText = shift;
    my @data;
    my $res = {};
    my @versions;
    foreach my $row ($inputText =~ m/^\w+\n\s+.*\n\s+.*\n\s+.*/gm) {
        @data = split /\n/, $row;
        @versions = split /\s+/, remSpace $data[1];
        push @{$res->{$data[0]}}, ([@versions], remSpace $data[2], remSpace $data[3]);
    }
    return $res;
}

sub data2string {
    my $data = shift;
    my $res;
    foreach my $app (sort keys %$data) {
        $res .= "$app" . "\n";
        $res .= "    " . join (" ", @{$data->{$app}[0]}) . "\n";
        $res .= "    $data->{$app}[1]" . "\n";
        $res .= "    $data->{$app}[2]" . "\n";
        $res .= "\n";
    }
    return $res;
}

sub getDirChilds {
    my $dir = shift;
    my @list;
    opendir(DIR, $dir) or die $!;
    while (my $file = readdir(DIR)) {
        next if ($file =~ m/^\./);
        push @list, $file;
    }
    closedir(DIR);
    return @list;
}

sub getLocalDirName {
    my $local = shift;
    $local =~ s/^.*[\\\/](.*?)$/$1/gsx;
    return $local;
}

sub download ($$) {
    my $url     = shift;
    my $name    = shift;

    my $pr      = progress ('download', $name);
    my $res     = HTTP::Tiny->new->get( $url );
    die 'Download failed' if not $res->{'success'};
    $pr->kill('KILL')->join();
    # $pr->exit();
    # say "\x1b[1A\x1b[9C..................................................100";
    return $res->{'content'};
}

sub unzip ($$) {
    my $file = shift;
    my $toPath = shift;
    my $pr = progress ('extract', $toPath);
    my $x = Archive::Extract->new( archive => $file );
    $x->extract( to => $toPath ) or die $x->error;
    $pr->kill('KILL')->join();
    # say "\x1b[1A\x1b[9C..................................................100";
}

sub progress (;@) {
    my $progress = threads->create( sub {
        my $action  = shift;
        my $name    = shift;
        my $progress;
        my $anim = [qw`- \ | /`];

        my $indent = 
        
        $SIG{'KILL'} = sub {
            # say "\x1b[1A\x1b[9C".('.'x50)."100";
            # say "\x1b[1A\x1b[".length ($action . ' ')."C ".('.'x50) . "  100%";
            say "\x1b[1A\x1b[9C  ".('.'x50) . "  100%";
            threads->exit();
        };

        say "$action ";

        # for (1..45) {
        #     $progress .= '#';
        #     select(undef, undef, undef, 0.05);
        #     say "\x1b[1A\x1b[".length ($action . ' ')."C$progress";
        #     say "\x1b[1A\x1b[".(length ($progress) + length ($action))."C" . $_*2;
        # }

        for (1..45) {
            $progress = "#" x ($_);
            $progress .= ' ' x (50 - length ($progress));
            usleep 100000;
            $anim = [qw`- \ | /`] if scalar @$anim == 0;
            # say ("\x1b[1A\x1b[".length ($action . '  ')."C" . shift (@$anim) . " |\33[90m$progress\33[0m| ". $_*2 . "%");
            say ("\x1b[1A\x1b[9C" . shift (@$anim) . " |\33[90m$progress\33[0m| ". $_*2 . "% ...$name");
        }

        while (1){};
    }, @_);
    return $progress;
}

sub progress2 (;@) {
    my $progress = threads->create( sub {
        my $name = shift;
        my $progress = '';
        my $anim = [qw`- \ | /`];
        # say "$name ";
        say "$name ";
        # my $termline = lastLine();
        # debug 10, 150, $termline;
        my $killCode = sub {
            # say "\x1b[1A\x1b[".length ($name . ' ')."C ".('.'x50)."    \33[92m100%\33[0m";
            # say "\x1b[".length ($name . ' ')."C ".('.'x50)."    \33[92m100%\33[0m", "SET" . ($termline + 1);
            say "\x1b[s\x1b[".length ($name . ' ')."C ".('.'x50) . "  100%\x1b[u";
            threads->exit();
        };

        $SIG{'KILL'} = $killCode;
        $SIG{'STOP'} = $killCode;
        
        # say '';
        for (1..45) {
            $progress = "#" x ($_);
            $progress .= ' ' x (50 - length ($progress));
            # select(undef, undef, undef, 0.05);
            usleep 100000;
            $anim = [qw`- \ | /`] if scalar @$anim == 0;
            # say ("\x1b[s\x1b[".length ($name . ' ')."C" . shift (@$anim) . " |\33[90m$progress\33[0m| ". $_*2 . "%\x1b[u");
            say ("\x1b[s\x1b[".length ($name . ' ')."C" . shift (@$anim) . " |\33[90m$progress\33[0m| ". $_*2 . "%\x1b[u");
        }
        
        while (1){};
    }, @_);
    return $progress;
}

1;

### PAKCAGE FS::UTILS ###################################################################################################################
package vmanlib::fs::utils;
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

### PAKCAGE FS ###################################################################################################################
package vmanlib::fs;
use strict;
use warnings;
use feature 'say';
use Data::Dumper;
# use vmanlib::fs::utils;

sub new {
    my $package     = shift;
    my $file        = shift or die "need file name!!!";
    my $cwd         = vmanlib::fs::utils->new()->cwd();
    my $confs       = {};

    my $self        = bless $confs, $package;
    
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

### PAKCAGE CONF ###################################################################################################################
package vmanlib::conf;
use strict;
use warnings;
use feature 'say';
use Data::Dumper;
use Data::Dump 'dump';

sub remSpace ($) { my $str = shift; $str =~ s/^\s*(.*)\s*$/$1/; return $str; }

sub new {
    my $package     = shift;
    my $conffile    = shift or die "need conf file name!!!";
    my $data        = shift || {};
    my $confs       = {};

    my $self        = bless $confs, $package;

    $self->{conf}   = vmanlib::fs->new($conffile);

    $self->read() if ($self->{conf}->exists);

    if (!$self->{conf}->exists){
        $self->{data} = $data;
        $self->write();
    }

    return $self;
}

sub conf {
    my $self        = shift;
    my $key         = shift;
    my $value       = shift;

    return $self->{data}{$key} if ($key && !$value);
    
    if ($key && $value) {
        $self->{data}{$key} = $value;
        $self->write();
    }

    return $self->{data};
}

sub read {
    no strict;
    my $self        = shift;
    $self->{data}   = parse($self->{conf}->read());
    return %{$self->{data}};
}

sub write {
    my $self        = shift;
    $self->{conf}->write($self->data2string());
}

sub parse {
    my $inputText   = shift;
    my @data;
    my $res = {};
    my $pattern = '^\w+\s+.*';

    foreach my $row ($inputText =~ m/$pattern/gm) {
        my($app, $path)       = split /\s+/, $row;
        $res->{$app} = $path;
    }

    return $res;
}

sub data2string {
    my $self        = shift;
    my $data        = $self->{data};
    my $res;

    foreach my $app (sort keys %$data) {
        $res .= "$app    $data->{$app}\n";
    }

    return $res;
}

1;

### PAKCAGE REPO ###################################################################################################################
package vmanlib::repo;
use strict;
use warnings;
use feature 'say';
use Data::Dumper;
use Data::Dump 'dump';

sub remSpace ($) { my $str = shift; $str =~ s/^\s*(.*)\s*$/$1/; return $str; }

sub new {
    my $package     = shift;
    my $repofile    = shift or die "need repo file name!!!";
    my $data        = shift || {};
    my $confs       = {};

    my $self        = bless $confs, $package;

    $self->{repo}   = vmanlib::fs->new($repofile);

    $self->read() if ($self->{repo}->exists);

    if (!$self->{repo}->exists){
        $self->{data} = $data;
        $self->write();
    }

    return $self;
}

sub repo {
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
    no strict;
    my $self        = shift;
    # my $dbfile      = shift;
    $self->{data}   = parse($self->{repo}->read());
    return %{$self->{data}};
}

sub write {
    my $self        = shift;
    $self->{repo}->write($self->data2string());
}

sub parse {
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

sub data2string {
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
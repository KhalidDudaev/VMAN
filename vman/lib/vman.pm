package vman;

#!perl
use strict;
use warnings;
use feature 'say';
use threads;

use HTTP::Tiny;
use Archive::Extract;
use Time::HiRes qw(usleep);

use vman::repo;
use vman::conf;
use vman::fs;

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

sub readFile { vman::fs->new(shift)->read() }
sub writeFile { vman::fs->new(shift)->write(shift) }

sub setRepo { $repo = vman::repo->new(shift) }
sub setConf { $conf = vman::conf->new(shift) }

sub repo { $repo->data(@_) }
sub conf { $conf->data(@_) }

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

# sub readConf {
#     no strict;
#     my $dbfile = shift;
#     unless (-e $dbfile) {
#         writeConf();
#     }
#     my $data = parseConf(readFile($dbfile));
#     return %$data;
# }

# sub writeConf {
#     my $db = shift;
#     my $dbfile = shift;
#     my $data = data2string ($db);
#     writeFile($dbfile, $data);
# }

# sub parseConf {
#     my $inputText = shift;
#     my @data;
#     my $res = {};
#     my @versions;
#     foreach my $row ($inputText =~ m/^\w+\n\s+.*\n\s+.*\n\s+.*/gm) {
#         @data = split /\n/, $row;
#         @versions = split /\s+/, remSpace $data[1];
#         push @{$res->{$data[0]}}, ([@versions], remSpace $data[2], remSpace $data[3]);
#     }
#     return $res;
# }

# sub data2string {
#     my $data = shift;
#     my $res;
#     foreach my $app (sort keys %$data) {
#         $res .= "$app" . "\n";
#         $res .= "    " . join (" ", @{$data->{$app}[0]}) . "\n";
#         $res .= "    $data->{$app}[1]" . "\n";
#         $res .= "    $data->{$app}[2]" . "\n";
#         $res .= "\n";
#     }
#     return $res;
# }

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
    
    my $text_before   = shift;
    my $text_after    = shift;

    my $progressStart = '[';
    my $progressEnd = ']';
    # my $progressBar = '|';
    # my $progressBar = '#';
    # my $progressBar = chr 220;
    # my $progressBar = chr 219;
    my $progressBar = chr 254;
    # my $progressBar = chr 240;

    # my $anim = [qw`\ _ /`];
    # my $anim = [qw`- \ | /`];
    # my $anim = [qw`. : · :`];
    # my $anim = [' ',chr(220),chr(219),chr(223)]; # UP
    # my $anim = [chr(220),chr(219),chr(223),chr(219)]; # UP
    my $anim = ['.',':',chr(250),':']; # UP
    # my $anim = [' ',' ','/','\\']; # DOWN

    my $progress = threads->create( sub {
        my $progress = '';
        say "$text_before ";
        # my $termline = lastLine();
        my $killCode = sub {
            say "\x1b[1A\x1b[9C".(' 'x200);
            # say "\x1b[1A\x1b[9C $text_after".('.'x(52 - length $text_after))." done!";
            say "\x1b[1A\x1b[9C ...complete for '$text_after'";
            threads->exit();
        };

        $SIG{'KILL'} = $killCode;
        $SIG{'STOP'} = $killCode;
        
        for my $step (1..45) {
            $progress = $progressBar x $step;
            $progress .= ' ' x (50 - length ($progress));
            usleep 100000;
            say "\x1b[1A\x1b[9C" . anim(\$anim, 'd', 2) . " $progressStart\33[90m$progress\33[0m$progressEnd ". $step * 2 . "% ...$text_after";
            # say "\x1b[1A\x1b[9C $progressStart\33[90m$progress\33[0m$progressEnd ". $step * 2 . "% " . anim(\$anim, 'd', 2) . " ...$text_after";
        }
        
        while (1){};
    }, @_);
    return $progress;
}

sub anim {
    my $animref     = shift;
    my $act         = shift;
    my $barLength   = shift;
    my $animLength  = $#$$animref;
    my $next = 0;
    my $result;

    push ( @$$animref, shift @$$animref) if $act =~ /[uU]/;
    unshift ( @$$animref, pop @$$animref ) if $act =~ /[dD]/;

    for (1..$barLength) {
        $result .= $$animref->[$next++];
        $next = 0 if $next > $animLength;
    }

    return $result;
}


1;









1;
#!perl
use strict;
use warnings;
use feature 'say';
use Cwd 'cwd';
use Data::Dumper;
use Data::Dump 'dump';

use LWP::UserAgent;
use HTTP::Tiny;
use File::Path;
use File::Copy;

use lib qw '
    C:\__programs__\utools\vman\lib\
';

use vmanlib;

setRepo './repo.vmdb';
setConf './conf.vmdb';

# repo 'java', { "321" => "ALKSDFJASLKDFJ" };

# say dump ${repo 'java'}{'10.0.2.hs'};
# say dump conf;
# say dump conf 'java';
# conf 'javax', "QWEQWEQWEQWE";
# say dump conf;


# say "$^O";

# my $cwd = $0;
# $cwd =~ s/\\/\//gsx;
# $cwd =~ s/^(.*)\/.*?$/$1/gsx;
# require "$cwd/vman.lib.pl";

# my %db = ();

my $VMAN_HOME = _cwd;

# %db = readDBase("$VMAN_HOME/vman4.db");
# %db = readDBase("$VMAN_HOME/vman4.db");
# %db = readDBase("$VMAN_HOME/vman4.db");

# say Dumper \%db;
 
if ($ARGV[0] && $ARGV[0] =~ /\b(?:h|help|\-h|\-\-help|\/\?)\b/) { say ''; help(); say ''; goto end; }
if (!$ARGV[0] || $ARGV[0] eq "-v") { say ''; version(); say ''; goto end; }
if ($ARGV[0] && $ARGV[0] eq "init") { init(); goto end; }
if ($ARGV[0] && $ARGV[0] =~ /\b(?:l|list|\-l|\-\-list)\b/) { say ''; app_list(); say ''; goto end; } 
if ($ARGV[0] && $ARGV[0] =~ /\b(?:r|repo|\-r|\-\-repo)\b/) { say ''; repo_list(); say ''; goto end; } 
if ($ARGV[0]) { ver_list(@ARGV); goto end; }

end:   

sub version {
    say "VMan v 0.2.3";
}

sub help {
    version();
    my $txt = readFile ("$VMAN_HOME/help02.txt");
    say $txt;
}

sub init {

    my $APP_DIR         = cwd();

    my $APP_DIR_NAME    = getLocalDirName $APP_DIR;
    # $APP_DIR_NAME       =~ s/^.*\\(.*?)$/$1/gsx;

    # `echo $APP_DIR > $VMAN_HOME\\paths\\$APP_DIR_NAME`;

    # writeFile "$VMAN_HOME/paths/$APP_DIR_NAME", $APP_DIR;
    
    # $db{$APP_DIR_NAME}[0] = ["0.0"];
    # $db{$APP_DIR_NAME}[1] = "http://";
    # $db{$APP_DIR_NAME}[2] = $APP_DIR;

    conf $APP_DIR_NAME, $APP_DIR;

    # writeDBase(\%db, "$VMAN_HOME/vman.db");
    # writeDBase(\%db, "$VMAN_HOME/vman4.db");

    my $env_name = uc $APP_DIR_NAME;
    my $env_value = toLeftSlash ($APP_DIR) . "\\current";

    # `setx $env_name $env_value`;
    # system "setx PATH %PATH%;$env_value";

    writeFile ("$APP_DIR/.current", "0.0");

    if (! -e "$APP_DIR/candidate") {
        my $dir1 = "$APP_DIR/candidate";
        my $dir2 = "$APP_DIR/candidate/0.0";
        mkdir $dir1;
        mkdir $dir2;
    }

    if (! -e "$APP_DIR/current") { mkdir "$APP_DIR/current" }

    # if $^O =~ /^MSWin/;
    if (-e "$APP_DIR/.init.vman.cmd") {
        `$APP_DIR/.init.vman.cmd`
    }

    say "\x1b[33mNew app \"$APP_DIR_NAME\" inittializated\x1b[0m"
}

sub install {
    my $name    = shift;
    my $ver     = shift;
    my $path    = shift;

    # my $link    = $db{$name}[1];
    # my $pattern = $db{$name}[0][0];

    my $link    = ${repo $name}{$ver};
    
    my $folder;

    ($link, $folder) = split /\s+/, $link;

    # "$APP_DIR/candidate/$ARGV[1]"
    # my @cap = $ver =~ m/^$pattern$/sx;

    # $link =~ s/\{\{(\d+)\}\}/$cap[$1]/gsxe;

    rmtree "$path/.download";
    rmtree "$path/.install";
    mkdir "$path/.download";
    mkdir "$path/.install";

    my $appdir;

    my $dfname = $link;
    $dfname =~ s/^.*\/(.*?)$/$1/sx;

    my $content = download $link, $dfname;
    writeFile "$path/.download/$dfname", $content;
    # my $zipfile = new vmanlib::fs ("$path/.download/$dfname");
    # $zipfile->($content);

    unzip "$path/.download/$dfname", "$path/.install";

    my @childs = getDirChilds "$path/.install";

    if ($#childs == 0) {
        ($appdir) = getDirChilds "$path/.install";
        move "$path/.install/$appdir", "$path/candidate/$ver";
    } else {
        move "$path/.install", "$path/candidate/$ver";
    }

}

sub repo_list {
    # foreach my $app_name (sort keys %db) {
    #     if( $db{$app_name}[1] !~ m/^https?:\/\/$/s ) {
    #         my $APP_VER = $db{$app_name}[0];
    #         my $APP_URL = $db{$app_name}[1];
    #         my $APP_DIR = $db{$app_name}[2];
    #         # my $VER_CURRENT = remNL readFile "$APP_DIR/.current";
    #         say " $app_name";
    #         say "       url:  $APP_URL";
    #         say "       ver:  @$APP_VER";
    #         say '';
    #     }
    # }
    say readFile('./repo.vmdb');
}

sub app_list {
    # say Dumper $db{candidates};
    foreach my $app_name (sort keys %{conf()}) {
        my $APP_DIR = conf $app_name;
        my $VER_CURRENT = remNL readFile "$APP_DIR/.current";
        my $APP = $app_name;
        say " $APP\t\t\x1b[90m$VER_CURRENT\x1b[0m";
    }
}

sub ver_list {
    # my $APP_DIR = remNL (readFile("$VMAN_HOME/paths/$_[0]"));
    # my $APP_DIR = $db{$_[0]}[2];
    my $APP_DIR = conf $_[0];
    my $VER_CURRENT = remNL readFile "$APP_DIR/.current";
    my $APP = getLocalDirName $APP_DIR;

    # my @candidates = `dir/ad /oe /b $APP_DIR\\candidate`;
    my @candidates = getDirChilds "$APP_DIR/candidate";
    # my @versions = @{$db{$APP}[0]}[1..$#{$db{$APP}[0]}];
    no warnings;

    my %cand = %{repo $_[0]};
    my $cand = {};

    map { $cand->{$_} = '' } @candidates;

    %cand = (%cand, %$cand);

    # say ">>>>> \n". dump sort {$b <=> $a} keys %cand;
    # my @versions = sort {$b <=> $a} keys %{repo $_[0]};
    my @versions = sort {$b cmp $a} keys %cand;

    # $APP =~ s/^.*[\\\/](.*?)$/$1/gsx;

    my $local_candidates;

    if (!$ARGV[1] || $ARGV[1] =~ /\b(?:l|list|\-l|\-\-list)\b/) {  
        
        # remove the first element that is a pattern
        # shift @{$db{$APP}[0]};
        my $txt = "\x1b[90m" . textToColumn (\@versions, 10, 13) . "\x1b[0m";

        for my $v (@candidates) {
            $v = remNL $v;
            # $local_candidates .= "|$v";
            # $VER_CURRENT eq $v ? say "> \x1b[1m$v\x1b[0m" : say "  \x1b[90m$v\x1b[0m";
            $txt =~ s/\s\s$v\s\s/\x1b[97m  $v  \x1b[90m/sx;
        }

        $txt =~ s/\s\s$VER_CURRENT/\x1b[97m# $VER_CURRENT\x1b[90m/sx if $VER_CURRENT;

        say $txt;
        
    } else {
        
        if (! -e "$APP_DIR/candidate/$ARGV[1]") {
            install($APP, $ARGV[1], "$APP_DIR");
        }

        if (-e "$APP_DIR/candidate/$ARGV[1]") {
            make_link ($APP_DIR, $ARGV[1]);
            say "$APP version changed...";
            if (-e "$APP_DIR/.vers.vman.cmd") {
                `$APP_DIR/.vers.vman.cmd`;
            }
        } else {
            say "\x1b[31mERROR: The command \"$ARGV[1]\" not recognized\x1b[0m"
        }
    }
}

sub make_link {
    my $APP_DIR     = shift;
    my $VER_CURRENT = shift;
    
    $APP_DIR = toLeftSlash $APP_DIR;
    `rd /s /q "$APP_DIR\\current"` if (-e "$APP_DIR\\current");
    `mklink /J $APP_DIR\\current $APP_DIR\\candidate\\$VER_CURRENT`;
    # link "$APP_DIR\\current", "$APP_DIR\\candidate\\$VER_CURRENT";
    # symlink "$APP_DIR\\current", "$APP_DIR\\candidate\\$VER_CURRENT";

    # `echo $VER_CURRENT> "$APP_DIR\\.current"`;
    writeFile "$APP_DIR\\.current", $VER_CURRENT;
}



1;
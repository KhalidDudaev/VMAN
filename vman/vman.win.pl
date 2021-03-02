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

use lib 'C:/__programs__/utools/vman/lib/';

# use lib Cwd::cwd.'/lib/';

use vman;

my $VMAN_HOME = _cwd;
my $VMAN_REPO_URL = 'https://github.com/KhalidDudaev/VMAN/raw/main';
sub VMAN_REPO_URL { $VMAN_REPO_URL }

repoUpdate() if (! -e "$VMAN_HOME/.repo");

setRepo './.repo';
setConf './.conf';

# say dump repo;

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



# %db = readDBase("$VMAN_HOME/vman4.db");
# %db = readDBase("$VMAN_HOME/vman4.db");
# %db = readDBase("$VMAN_HOME/vman4.db");

# say Dumper \%db;
 
if ($ARGV[0] && $ARGV[0] =~ /\b(?:h|help|\-h|\-\-help|\/\?)\b/) { say ''; help(); say ''; goto end; }
if (!$ARGV[0] || $ARGV[0] eq "-v") { say ''; version(); say ''; goto end; }
if ($ARGV[0] && $ARGV[0] eq "init") { init($ARGV[1], '000', $ARGV[2]); goto end; }
if ($ARGV[0] && $ARGV[0] =~ /\b(?:l|list|\-l|\-\-list)\b/) { say ''; app_list(); say ''; goto end; } 
if ($ARGV[0] && $ARGV[0] =~ /\b(?:r|repo|\-r|\-\-repo)\b/) { say ''; repo_list(); say ''; goto end; } 
if ($ARGV[0] && $ARGV[0] =~ /\b(?:u|updae|\-u|\-\-updae)\b/) { say ''; repoUpdate(); say ''; goto end; } 
if ($ARGV[0]) { ver_list(@ARGV); goto end; }

end:   

sub version {
    say "VMan v 0.2.3";
}

sub help {
    version();
    my $txt = readFile ("$VMAN_HOME/help");
    say $txt;
}

sub init {

    my $APP_DIR         = $_[2] || cwd();
    my $APP_VER         = $_[1];
    my $APP_DIR_SHORT   = getLocalDirName $APP_DIR;
    my $APP_NAME        = $_[0] || $APP_DIR_SHORT;
    
    mkdir $APP_DIR if ! -d $APP_DIR;

    # `echo $APP_DIR > $VMAN_HOME\\paths\\$APP_DIR_SHORT`;

    # writeFile "$VMAN_HOME/paths/$APP_DIR_SHORT", $APP_DIR;
    
    # $db{$APP_DIR_SHORT}[0] = ["0.0"];
    # $db{$APP_DIR_SHORT}[1] = "http://";
    # $db{$APP_DIR_SHORT}[2] = $APP_DIR;

    conf $APP_NAME, { 'ver' => $APP_VER, 'path' => $APP_DIR };

    # writeDBase(\%db, "$VMAN_HOME/vman.db");
    # writeDBase(\%db, "$VMAN_HOME/vman4.db");

    # my $env_name = uc $APP_NAME;
    # my $env_value = toLeftSlash ($APP_DIR) . "\\current";

    # `setx $env_name $env_value`;
    # system "setx PATH %PATH%;$env_value";

    writeFile ("$APP_DIR/.current", "0.0");

    if (! -e "$APP_DIR/candidate") {
        my $dir1 = "$APP_DIR/candidate";
        # my $dir2 = "$APP_DIR/candidate/0.0";
        mkdir $dir1;
        # mkdir $dir2;
    }

    if (! -e "$APP_DIR/current") { mkdir "$APP_DIR/current" }

    # if $^O =~ /^MSWin/;
    if (-e "$APP_DIR/.init.vman.cmd") {
        `$APP_DIR/.init.vman.cmd`
    }

    say "\x1b[33mNew app \"$APP_NAME\" initializated\x1b[0m"
}

sub repoUpdate {

    say "update repository ...";
    say '';
    rmtree "$VMAN_HOME/.download";
    mkdir "$VMAN_HOME/.download";

    # my $link = VMAN_REPO_URL . '/.conf/.repo.zip';
    my $link = "$VMAN_REPO_URL/.conf/.repo.zip";
    my $content = download $link, '.repo.zip';

    writeFile "$VMAN_HOME/.download/.repo.zip", $content;
    unzip "$VMAN_HOME/.download/.repo.zip", "$VMAN_HOME";

    rmtree "$VMAN_HOME/.download";

}

sub install {
    my $app_name    = shift;
    my $ver         = shift;
    my $app_path    = shift;

    # my $link    = $db{$app_name}[1];
    # my $pattern = $db{$app_name}[0][0];

    init($app_name, $ver, $app_path) if ! -d "$app_path/candidate";

    my $link    = ${repo $app_name}{$ver};
    my $folder;

    ($link, $folder) = split /\s+/, $link;

    # "$APP_DIR/candidate/$ARGV[1]"
    # my @cap = $ver =~ m/^$pattern$/sx;

    # $link =~ s/\{\{(\d+)\}\}/$cap[$1]/gsxe;

    rmtree "$app_path/.download";
    rmtree "$app_path/.install";
    rmtree "$app_path/.conf";
    mkdir "$app_path/.download";
    mkdir "$app_path/.install";
    mkdir "$app_path/.conf";

    my $appdir;

    my $dfname = $link;
    $dfname =~ s/^.*\/(.*?)$/$1/sx;

    # 'https://github.com/KhalidDudaev/VMAN/raw/main/.conf/init/gradle.conf.zip'
    if(! -e "$app_path/.init.vman.cmd"){
        my $confContent = download "$VMAN_REPO_URL/.conf/init/$app_name.conf.zip", "$app_name.conf.zip";
        writeFile "$app_path/.download/$app_name.conf.zip", $confContent;
        unzip "$app_path/.download/$app_name.conf.zip", "$app_path/.conf";
        move "$app_path/.conf/$app_name.init.vman.cmd", "$app_path/.init.cmd";
    }

    my $content = download $link, $dfname;
    writeFile "$app_path/.download/$dfname", $content;
    unzip "$app_path/.download/$dfname", "$app_path/.install";

    my @childs = getDirChilds "$app_path/.install";

    if ($#childs == 0) {
        ($appdir) = getDirChilds "$app_path/.install";
        move "$app_path/.install/$appdir", "$app_path/candidate/$ver";
    } else {
        move "$app_path/.install", "$app_path/candidate/$ver";
    }
    
    if (-e "$app_path/.init.cmd") {
        `$app_path/.init.cmd`;
        unlink "$app_path/.init.cmd";
    }
    rmtree "$app_path/.download";
    rmtree "$app_path/.install";
    rmtree "$app_path/.conf";
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
    say readFile('./.repo');
    # say repo;
}

sub app_list {
    # say Dumper $db{candidates};
    foreach my $APP (sort keys %{conf()}) {
        my $APP_INFO = conf $APP;
        my $APP_DIR = $APP_INFO->{path};
        my $APP_VER = $APP_INFO->{ver};
        # my $APP = $app_name;
        # my $VER_CURRENT = remNL readFile "$APP_DIR/.current";
        say "\33[91mERROR: \33[0mINCORRECT FILE NAME OR PATH... \33[91m'$APP_DIR/.current'\33[0m FOR \33[91m'$APP'\33[0m" if ! -e "$APP_DIR/.current";
        my $VER_CURRENT = -e "$APP_DIR/.current" ? remNL readFile "$APP_DIR/.current" : "\33[91mNOT INFO\33[0m";
        # say " $APP\t\t\x1b[90m$VER_CURRENT\x1b[0m";
        say " $APP\t\t\x1b[90m$APP_VER\x1b[0m";
    }
}

sub ver_list {
    # my $APP_DIR = remNL (readFile("$VMAN_HOME/paths/$_[0]"));
    # my $APP_DIR = $db{$_[0]}[2];
    my $APP_INFO    = conf $_[0];
    my $APP_DIR     = $APP_INFO->{path};
    my $APP_VER     = $APP_INFO->{path};
    $APP_DIR        = cwd() if !$APP_DIR;
    # my $VER_CURRENT = $APP_DIR && -e "$APP_DIR/.current" ? remNL readFile "$APP_DIR/.current" : "NOT INSTALLED";
    my $VER_CURRENT = $APP_VER;
    my $APP = $ARGV[0] || getLocalDirName $APP_DIR;

    # my @candidates = `dir/ad /oe /b $APP_DIR\\candidate`;
    my @candidates = $APP_DIR && -e "$APP_DIR/candidate" ? getDirChilds "$APP_DIR/candidate": ();
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

        # if (! -d "$APP_DIR/candidate/") {
        #     say "####################### $APP : $ARGV[1] : $APP_DIR";
        # }

        say $txt;
        
    } else {

        
        if (! -e "$APP_DIR/candidate/$ARGV[1]") {
            # init($APP, $ARGV[1], $APP_DIR);
            install($APP, $ARGV[1], $APP_DIR);
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
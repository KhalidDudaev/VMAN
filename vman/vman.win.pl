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

# use lib Cwd::cwd.'/lib/';
use lib 'c:/_programs/utools/vman/lib/';


use vman;

my $VMAN_HOME = _cwd;
my $VMAN_REPO_URL = 'https://github.com/KhalidDudaev/VMAN/raw/main';
sub VMAN_REPO_URL { $VMAN_REPO_URL }

### helper
sub say_error {
    my $msg = shift;
    say "\33[91m$msg\33[0m";
    exit;
}

repoUpdate() if (! -e "$VMAN_HOME/.repo");

setRepo './.repo';
setConf './.conf';

# say %{repo('python')}{'2.0.1'};

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
# say "AKDJFHASKDFHASKDFJH";
 
if ($ARGV[0] && $ARGV[0] =~ /\b(?:h|help|\-h|\-\-help|\/\?)\b/) { say ''; help(); say ''; goto end; }
if (!$ARGV[0] || $ARGV[0] eq "-v") { say ''; version(); say ''; goto end; }
if ($ARGV[0] && $ARGV[0] eq "init") { init($ARGV[1], 'NVER', $ARGV[2]); goto end; }
if ($ARGV[0] && $ARGV[0] =~ /\b(?:l|list|\-l|\-\-list)\b/) { say ''; app_list($ARGV[1]); say ''; goto end; } 
if ($ARGV[0] && $ARGV[0] =~ /\b(?:r|repo|\-r|\-\-repo)\b/) { say ''; repo_list(); say ''; goto end; } 
if ($ARGV[0] && $ARGV[0] =~ /\b(?:u|update|\-u|\-\-update)\b/) { say ''; repoUpdate(); say ''; goto end; } 
if ($ARGV[0]) { say ''; ver_list($ARGV[0], $ARGV[1], $ARGV[2]); goto end; }

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

    my $app_path        = $_[2] || cwd();
    my $app_vers        = $_[1];
    my $app_dir         = getLocalDirName $app_path;
    my $app_name        = $_[0] || $app_dir;
    
    mkdir $app_path if ! -d $app_path;

    # `echo $app_path > $VMAN_HOME\\paths\\$app_dir`;

    # writeFile "$VMAN_HOME/paths/$app_dir", $app_path;
    
    # $db{$app_dir}[0] = ["0.0"];
    # $db{$app_dir}[1] = "http://";
    # $db{$app_dir}[2] = $app_path;

    conf $app_name, { 'vers' => $app_vers, 'path' => $app_path };

    # writeDBase(\%db, "$VMAN_HOME/vman.db");
    # writeDBase(\%db, "$VMAN_HOME/vman4.db");

    # my $env_name = uc $app_name;
    # my $env_value = toLeftSlash ($app_path) . "\\current";

    # `setx $env_name $env_value`;
    # system "setx PATH %PATH%;$env_value";

    writeFile ("$app_path/.current", $app_vers);

    if (! -e "$app_path/candidate") {
        my $dir1 = "$app_path/candidate";
        # my $dir2 = "$app_path/candidate/0.0";
        mkdir $dir1;
        # mkdir $dir2;
    }

    if (! -e "$app_path/current") { mkdir "$app_path/current" }

    # if $^O =~ /^MSWin/;
    if (-e "$app_path/.init.cmd") {
        system "$app_path/.init.cmd";
        # `$app_path/.init.cmd`;
    }

    say "\x1b[33mNew app \"$app_name\" initializated\x1b[0m"
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
    my $app_vers    = shift;
    my $app_path    = shift;

    # my $link    = $db{$app_name}[1];
    # my $pattern = $db{$app_name}[0][0];

    if (!isAppRepo($app_name) && !isAppLocal($app_name)){
        say_error "app '$app_name' not avalable";
        return 0;
    }

    if (! isVer($app_name, $app_vers)){
        say_error "version '$app_vers' not avalable for app '$app_name'";
        return 0;
    }

    say "install $app_name v.$app_vers ...";
    
    if (! -d "$app_path/candidate"){
        init($app_name, $app_vers, $app_path);
    } else {
        conf ($app_name, { 'vers' => $app_vers, 'path' => $app_path });
    }

    my $link    = ${repo $app_name}{$app_vers};
    my $folder;

    ($link, $folder) = split /\s+/, $link;

    # "$app_path/candidate/$ARGV[1]"
    # my @cap = $app_vers =~ m/^$pattern$/sx;

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
        move "$app_path/.install/$appdir", "$app_path/candidate/$app_vers";
    } else {
        move "$app_path/.install", "$app_path/candidate/$app_vers";
    }
    
    if (-e "$app_path/.init.cmd") {
        say "set init...";
        `$app_path/.init.cmd`;
        # unlink "$app_path/.init.cmd";
    }
    
    rmtree "$app_path/.download";
    rmtree "$app_path/.install";
    rmtree "$app_path/.conf";
}

sub repo_list {
    # foreach my $app_name (sort keys %db) {
    #     if( $db{$app_name}[1] !~ m/^https?:\/\/$/s ) {
    #         my $app_vers = $db{$app_name}[0];
    #         my $app_url = $db{$app_name}[1];
    #         my $app_path = $db{$app_name}[2];
    #         # my $VER_CURRENT = remNL readFile "$app_path/.current";
    #         say " $app_name";
    #         say "       url:  $app_url";
    #         say "       ver:  @$app_vers";
    #         say '';
    #     }
    # }
    say readFile('./.repo');
    # say repo;
}

sub app_list {
    my $app     = shift;
    # say Dumper $db{candidates};
    if($app){
        (isAppRepo($app) || isAppLocal($app))
            ? ver_list($app)
            : say_error "\33[91mApp \33[0m'$app'\33[91m not available\33[0m";
    } else {
        say "list of avalable apps...\n";
        foreach my $app (sort keys %{conf()}) {
            my $app_info = conf $app;
            my $app_path = $app_info->{path};
            my $app_vers = $app_info->{vers};
            # my $app = $app_name;
            # my $VER_CURRENT = remNL readFile "$app_path/.current";
            say "\33[91mERROR: \33[0mINCORRECT FILE NAME OR PATH... \33[91m'$app_path/.current'\33[0m FOR \33[91m'$app'\33[0m" if ! -e "$app_path/.current";
            my $VER_CURRENT = -e "$app_path/.current" ? remNL readFile "$app_path/.current" : "\33[91mNOT INFO\33[0m";
            # say " $app\t\t\x1b[90m$VER_CURRENT\x1b[0m";
            say " $app\t\t\x1b[90m$app_vers\x1b[0m";
        }
    }
}

sub isAppLocal {
    my $app     = shift;
    my $conf    = readFile('./.conf');
    return $conf =~ m/\b$app\b/g || 0;
}

sub isAppRepo {
    my $app     = shift;
    my $repo    = readFile('./.repo');
    return $repo =~ m/\b$app\b/ || 0;
}

sub isVer {
    my $app     = shift;
    my $ver     = shift;
    my $repo    = readFile('./.repo');
    return exists ${repo($app)}{$ver};
}

sub ver_list {
    # my $app_path = remNL (readFile("$VMAN_HOME/paths/$_[0]"));
    # my $app_path = $db{$_[0]}[2];
    my $app_name    = $_[0];

    say_error "App '$app_name' not avalable" if (!isAppRepo($app_name) && !isAppLocal($app_name));

    my $app_info    = conf $app_name;
    my $curr_vers   = $app_info->{vers};
    my $curr_path   = $app_info->{path};

    my $set_vers    = $_[1];
    my $app_path    = $_[2] || $curr_path || cwd();

    # say "### app_path: $app_path";
    # say "### curr_path: $curr_path";


    # $app_path       = cwd() if !$app_path;
    # $app_path       = $curr_path if !$app_path;
    # $app_name       = getLocalDirName $app_path if !$app_name;

    # my $VER_CURRENT = $app_path && -e "$app_path/.current" ? remNL readFile "$app_path/.current" : "NOT INSTALLED";
    # my $app = $ARGV[0] || getLocalDirName $app_path;

    # my @candidates = `dir/ad /oe /b $app_path\\candidate`;
    my @candidates = $app_path && -e "$app_path/candidate" ? getDirChilds "$app_path/candidate": ();
    # my @versions = @{$db{$app}[0]}[1..$#{$db{$app}[0]}];
    no warnings;

    # say "VER LIST ########### $app_name | $set_vers | $app_path candidates" . dump \@candidates;

    my %cand = %{repo $app_name};
    my $cand = {};

    map { $cand->{$_} = '' } @candidates;

    %cand = (%cand, %$cand);

    # say ">>>>> \n". dump sort {$b <=> $a} keys %cand;
    # my @versions = sort {$b <=> $a} keys %{repo $_[0]};
    my @versions = sort {$b cmp $a} keys %cand;

    # $app =~ s/^.*[\\\/](.*?)$/$1/gsx;

    my $local_candidates;

    if (!$set_vers || $set_vers =~ /\b(?:l|list|\-l|\-\-list)\b/) {  
        say "version list of app '$app_name' ...\n";
        # remove the first element that is a pattern
        # shift @{$db{$app}[0]};
        my $txt = "\x1b[90m" . textToColumn (\@versions, 10, 13) . "\x1b[0m";

        for my $v (@candidates) {
            $v = remNL $v;
            # $local_candidates .= "|$v";
            # $curr_vers eq $v ? say "> \x1b[1m$v\x1b[0m" : say "  \x1b[90m$v\x1b[0m";
            $txt =~ s/\s\s$v\s\s/\x1b[97m  $v  \x1b[90m/sx;
        }

        $txt =~ s/\s\s$curr_vers/\x1b[97m# $curr_vers\x1b[90m/sx if $curr_vers;

        # if (! -d "$app_path/candidate/") {
            # say "####################### $app_name : $set_vers : $app_path";
        # }

        say $txt;
        
    } else {

        # say "VER LIST to INSTALL ########### $app_name | $set_vers | $app_path";

        if (! -e "$app_path/candidate/$set_vers") {
            install($app_name, $set_vers, $app_path);
        }

        if (-e "$app_path/candidate/$set_vers") {
            version_change($app_name, $curr_vers, $set_vers, $app_path);
        } else {
            say_error "\x1b[31mERROR: The command \"$set_vers\" not recognized\x1b[0m"
        }
    }
}

sub version_change {
    my $app_name = shift;
    my $curr_vers = shift || 0;
    my $app_vers = shift;
    my $app_path = shift;
    
    if ($app_vers eq $curr_vers) {
        say "The same version of app $app_name from $curr_vers to $app_vers.";
        say "No need to change version.";
        exit;
    }

    say "change version of app $app_name from $curr_vers to $app_vers" if $curr_vers != 0;

    make_link ($app_path, $app_vers);
    conf ($app_name, { 'vers' => $app_vers, 'path' => $app_path });
    
    say "$app_name version changed..." if $curr_vers != 0;

    if (-e "$app_path/.vers.vman.cmd") {
        `$app_path/.vers.vman.cmd`;
    }
}

sub make_link {
    my $app_path     = shift;
    my $ver_current = shift;
    
    $app_path = toLeftSlash $app_path;
    `rd /s /q "$app_path\\current"` if (-e "$app_path\\current");
    `mklink /J $app_path\\current $app_path\\candidate\\$ver_current`;
    # link "$app_path\\current", "$app_path\\candidate\\$ver_current";
    # symlink "$app_path\\current", "$app_path\\candidate\\$ver_current";

    # `echo $ver_current> "$app_path\\.current"`;
    writeFile "$app_path\\.current", $ver_current;
}



1;
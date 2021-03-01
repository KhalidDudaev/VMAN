package json;

use strict;
use warnings;

use Data::Dumper;
# use Data::Dump 'dump';

my $cenv   						= {};

sub new {
    my ($param, $class, $self)	= ($cenv, ref $_[0] || $_[0], $_[1] || {});    	# получаем имя класса, если передана ссылка то извлекаем имя класса,  получаем параметры, если параметров нет то присваиваем пустой анонимный хеш
	%$self						= (%$param, %$self);							# применяем умолчания, если имеются входные данные то сохраняем их в умолчаниях
    $self                   	= bless($self, $class);                         # обьявляем класс и его свойства
    return $self;
}

sub perl_json {
	my $self  					= shift;
	my $data					= shift;
	$data 						= Data::Dump::dump $data;
	$data 						=~ s/\"?(\w+)\"?\s*\=\>/"$1" :/gsx;

	#$data 						=~ s/(\w+)(\s*)\:/"$1"$2:/gsx;
	#$data 						=~ s/(\w+)(\s*)\=\>/"$1"$2:/gsx;
	#$data 						=~ s/\:\s*(\w+)/: "$1"/gsx;

	$data 						=~ s/\,(\s*[\]|\}])/$1/gsx;
	return $data;
}

sub json_perl {
	my $self  					= shift;
	my $data					= shift;
	$data 						=~ s/\:/\=\>/gsx;
	$data						= eval $data;
	return $data;
}

sub json2hash {
	my $self  					= shift;
    my $data        			= shift;
    $data           			=__convert('j2h',$data);
    # return $data;
    return eval("$data");
}

sub hash2json {
    my $self  					    = shift;
    my $data                        = shift;

    local $Data::Dumper::Terse      = 1;
    local $Data::Dumper::Useqq      = 1;
    local $Data::Dumper::Quotekeys  = 1;
    local $Data::Dumper::Sortkeys   = 1;
    local $Data::Dumper::Pair       = ' : ';
    $data           = Dumper $data;

    # $data           = Data::Dump::dump $data;
    # $data           =~ s/(?<!\\)\"/\\\"/gsx;
    # $data           =__convert('h2j',$data);
    return $data;
}

sub __convert {
    my $command     = shift;
    my $data        = shift;
    my $txt_bank    = [];
	my $regex       = q/(?:\"\"|\"(?(?<!\\\)[^\"]|.)*?[^\\\]\")/;
    $data           =~ s/($regex)/__txt_extr($txt_bank,$1)/gsxe;
    $data           =~ s/\:/=>/gsx      if $command eq 'j2h';
    $data           =~ s/\=\>/:/gsx     if $command eq 'h2j';
	# $data 			=~ s/\"?(\w+)\"?(\s*\:)/"$1"$2/gsx;
    $data           =~ s/\%\%\%TEXT\_(\d+)\%\%\%/__txt_incl($txt_bank,$1)/gsxe;
    return $data;
}

sub __txt_extr {
    my $txt_bank    = shift;
    my $data        = shift;
    my $result;
    push @$txt_bank, $data;
    $result         = '%%%TEXT_' . sprintf("%03d", $#$txt_bank) . '%%%' if $txt_bank;
    return $result;
}

sub __txt_incl {
    my $txt_bank    = shift;
    my $num         = shift;
    my $res         = '';
    $res            = $txt_bank->[$num] if $txt_bank->[$num];
    return $res;
}

1;

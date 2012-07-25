#!/usr/bin/perl -w
use warnings;
use strict;
use WWW::Curl::Easy;
use Tk;
use JSON;
use Data::Dumper;


sub get{
	my ($url) = @_;
	perform_request($url, '', 0);
}

sub post{
    my ($url, $data) = @_;
    perform_request($url, $data, 1);
}

sub perform_request{

    my @cookies = (
        'erpk=ikvu6m9gunis3gkvnnhf8sek63',
	);
    
    my @headers;
    push(@headers, 'Cookie: '.join('; ', @cookies));
    push(@headers, 'User-Agent:	Mozilla/5.0 (X11; Linux x86_64; rv:9.0.1) Gecko/20100101 Firefox/9.0.1 Iceweasel/9.0.1');
    
    my $curl = WWW::Curl::Easy->new;
    $curl->setopt(CURLOPT_HEADER,0);
    $curl->setopt(CURLOPT_HTTPHEADER, \@headers);
    
    my ($url, $query, $post) = @_;
    
    if($post){
        $curl->setopt(CURLOPT_POST, 1);
        $curl->setopt(CURLOPT_POSTFIELDS, $query);
    }else{
        $url .= $query;
    }
    
    $curl->setopt(CURLOPT_URL, $url);
    
    my $response_body = '';
    open(my $fileb, ">", \$response_body);
    $curl->setopt(CURLOPT_WRITEDATA,$fileb);
    
    my $retcode = $curl->perform;
    
    if ($retcode != 0) {
        print "An error happened: $retcode ".$curl->strerror($retcode)." ".$curl->errbuf."\n";
        die;
    }else{
        return $response_body;
    }
}

sub find_food_raw{

    get('http://economy.erepublik.com/en/market/0') =~ m/<select\sname="countryId"\sid="countryId"\sonchange="javascript:redirectToMarket\(this,\s'countryId',\snull\);">[\r\n\s]+<option\svalue="0"\stitle="">Country<\/option>([\r\n\s\S]*)<\/select>/;
    my @countries = ($1 =~ m/<option\s?[selected=""]*\s?\svalue="(\d+)"\stitle="[^"]+">[^<]+<\/option>/g);

    my $min_price = 0;
    my $min_country = 0;
    foreach my $country (@countries)
    {
        my $res = get('http://economy.erepublik.com/en/market/'.$country.'/7/1/citizen/0/price_asc/1') =~ m/<td\sclass="m_price\sstprice">[\r\n\s]+<strong>([^<]+)<\/strong><sup>([^<]+)<strong>[^<]+<\/strong><\/sup>[\r\n\s]+<\/td>[\s\S]*<td\sclass="m_buy">/;
        if($res){
            my $price = $1.$2;
            if($min_price == 0 || $min_price > $price){
                $min_price = $price;
                $min_country = $country;
            }
        }
    } 
    print $min_price.' '.$min_country."\n";

	die;

}

sub get_token{
    my ($url) = @_;
    get($url) =~ m/<input\stype="hidden"\sname="_token"\svalue="([^"]+)"\sid="award_token"\s\/>/;
    return $1;
}

sub train{
    my $train_url = 'http://www.erepublik.com/en/economy/train';

    my $content =get('http://www.erepublik.com/en/economy/training-grounds');

    $content =~ m/<input\stype="hidden"\sname="_token"\svalue="([^"]+)"\sid="award_token"\s\/>/;
    my $token = $1;

    my @grounds = ($content =~ m/<div\sclass="listing\sgrounds\s"\sid="ground_(\d+)">/g);

    my @params = (
        '_token='.$token,
    );

    my $i = 0;
    foreach my $ground (@grounds){
        push(@params, 'grounds['.($i++).'][id]='.$ground);
        push(@params, 'grounds['.($i).'][train]=1');
    }

    my $resp = decode_json post($train_url, join('&', @params));

    if($resp->{status} == undef){
        if($resp->message == 'captcha'){
=cut
    TODO: Captcha processing
=cut
            print $resp->message."\n";
            return undef;
        }else{
            print $resp->message."\n";
            return undef;
        }
    }else{
        return 1;
    }
}

sub work_for_uncle{
    my $work_url  = 'http://www.erepublik.com/en/economy/work';
    my $token = get_token('http://www.erepublik.com/en/economy/myCompanies');
    my $resp = decode_json post($work_url, 'action_type=work&_token='.$token);
    if($resp->{status} == undef){
        if($resp->message == 'captcha'){
=cut
    TODO: Captcha processing
=cut
            print $resp->message."\n";
            return undef;
        }else{
            print $resp->message."\n";
            return undef;
        }
    }else{
        return 1;
    }
}

sub work_on_own{

    my $work_url  = 'http://www.erepublik.com/en/economy/work';

    my $get = get('http://www.erepublik.com/en/economy/myCompanies');

    $get =~ m/<input\stype="hidden"\sname="_token"\svalue="([^"]+)"\sid="award_token"\s\/>/;
    my $token = $1;

    $get =~ m/<span\sid="preset_works">(\d+)<\/span>\/(\d+)/;
    my $workers = $2;

    my @companies = ($get =~ m/<div\sclass="listing\scompanies[^"]*" id="company_(\d+)">/g);

    my @params = (
        '_token='.$token,
        'action_type=production'
    );

    my $i = 0;
    foreach my $company (@companies){
        push(@params, 'companies['.($i).'][id]='.$company);
        push(@params, 'companies['.($i).'][employee_works]=0');
        push(@params, 'companies['.($i++).'][own_work]=1');
    }

    my $resp = decode_json post($work_url, join('&', @params));
    
    if(!$resp->{status}){
        if($resp->message == 'captcha'){
=cut
    TODO: Captcha processing
=cut
            print $resp->message."\n";die;
            return undef;
        }else{
            print $resp->message."\n";die;
            return undef;
        }
    }else{
        return 1;
    }

=cut
  $get =~ m/<strong\sid="food_raw_consumed">([^<]*)<\/strong>/;
    my $food_raw_consumed = $1;
    $get =~ m/<strong\sid="weapon_raw_consumed">([^<]*)<\/strong>/;
    my $weapon_raw_consumed = $1;

    print $food_raw_consumed.' '.$weapon_raw_consumed;
=cut
}

sub work_day{
    train;
    work_for_uncle;
    work_on_own;
}

=cut
my $mw = MainWindow->new;

$mw->Label(-text => 'File Name')->pack;
my $filename = $mw->Entry(-width => 20);
$filename->pack;

$mw->Label(-text => 'Font Name')->pack;
my $font = $mw->Entry(-width => 10);
$font->pack;

$mw->Button(
    -text => 'Fax',
    -command => sub{do_fax($filename, $font)}
)->pack;

$mw->Button(
    -text => 'Print',
    -command => sub{do_print($filename, $font)}
)->pack;

MainLoop;

=cut


if(defined $ARGV[0]){
	if($ARGV[0] eq 'tk'){
        my $mw = MainWindow->new;

        $mw->Button(
            -text    => 'Buy Food Raw',
            -command => sub{find_food_raw},
        )->pack;

        $mw->Button(
            -text => 'Work Day',
            -command => sub{work_day},
        )->pack;
        MainLoop;
		
	}
}
work_on_own;
#!/usr/bin/perl
use warnings;
use strict;
use WWW::Curl::Easy;
use Tk;

sub get{
	my ($url) = @_;
	perform_request($url, '', 0);
}

sub perform_request{


    my @cookies = (
        'erpk=bocf936qb32odghbu7g0gh39s4',
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

sub buy_food_raw{

    get('http://economy.erepublik.com/en/market/0') =~ m/<select\sname="countryId"\sid="countryId"\sonchange="javascript:redirectToMarket\(this,\s'countryId',\snull\);">[\r\n\s]+<option\svalue="0"\stitle="">Country<\/option>([\r\n\s\S]*)<\/select>/;
    my @countries = ($1 =~ m/<option\svalue="(\d+)"\stitle="[^"]+">[^<]+<\/option>/g);
    
    my $min_price = 0;
    my $min_country = 0;
    foreach my $country (@countries)
    {
        get('http://economy.erepublik.com/en/market/'.$country.'/7/1/citizen/0/price_asc/1') =~ m/<td\sclass="m_price\sstprice">[\r\n\s]+<strong>([^<]+)<\/strong><sup>([^<]+)<strong>[^<]+<\/strong><\/sup>[\r\n\s]+<\/td>([\s\S]*<td\sclass="m_buy">)?/;
        my $price = $1.$2;
        if($min_price == 0 || $min_price > $price){
            $min_price = $price;
            $min_country = $country;
        }
        if(defined $3){
            print $price.' '.$country.' '.$3."\n";
        }
    } 
    print $min_price.' '.$min_country."\n";

	die;

}

if(defined $ARGV[0]){
	if($ARGV[0] eq 'tk'){

		my $mw = MainWindow->new;
	    $mw->Button(
	        -text    => 'Buy Food Raw',
	        -command => buy_food_raw,
	    )->pack;
	    MainLoop;
	}
}
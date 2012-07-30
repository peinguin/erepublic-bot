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
        push(@params, 'grounds['.($i).'][id]='.$ground);
        push(@params, 'grounds['.($i++).'][train]=1');
    }

    my $json = post($train_url, join('&', @params));
    my $resp = decode_json $json;

    if(!$resp->{status}){
        if($resp->{message} eq 'captcha'){
=cut
    TODO: Captcha processing
=cut
            print $resp->{message}."\n";
            return undef;
        }else{
            print $resp->{message}."\n";
            return undef;
        }
    }else{
        return 1;
    }
}

sub work_for_uncle{
    my $work_url  = 'http://www.erepublik.com/en/economy/work';
    my $token = get_token('http://www.erepublik.com/en/economy/myCompanies');
    my $json = post($work_url, 'action_type=work&_token='.$token);
    my $resp = decode_json $json;
    if(!$resp->{status}){
        if($resp->{message} eq 'captcha'){
=cut
    TODO: Captcha processing
=cut
            print $resp->{message}."\n";
            return undef;
        }else{
            print $resp->{message}."\n";
            return undef;
        }
    }else{
        return 1;
    }
}

sub buy_food_raw{
    print "Buy food raw start\n";
    my $url = 'http://economy.erepublik.com/en/market/40/7';
    my $get = get($url);

    $get =~ m/<tr>[\r\n\s\t]*<td\sclass="m_product"\sid="productId_\d+"\sstyle="width:60px">[\r\n\s\t]*<img\ssrc="[^"]+"\salt=""\sclass="product_tooltip"\sindustry="7"\squality="1"\/>[\r\n\s\t]*<\/td>[\r\n\s\t]*<td\sclass="m_provider">[\r\n\s\t]*<a\shref="[^"]+"\s>[\r\n\s\t]*[^<]*<\/a>[\r\n\s\t]*<\/td>[\r\n\s\t]*<td\sclass="m_stock">[\r\n]*[\s]+(\d+)[\s]+<\/td>[\r\n\s\t]*<td\sclass="m_price\sstprice">[\r\n\s\t]*<strong>\d+<\/strong><sup>\.\d+\s<strong>UAH<\/strong><\/sup>[\r\n\s\t]*<\/td>[\r\n\s\t]*<td\sclass="m_quantity"><input\stype="text"\sclass="shadowed\sbuyField"\sname="textfield"\sid="amount_\d+"\smaxlength="4"\sonkeypress="return\scheckNumber\('int',\sevent\)"\sonblur="return\scheckInput\(this\)"\svalue="1"\/><\/td>[\r\n\s\t]*<td\sclass="m_buy"><a\shref="javascript:;"\sclass="f_light_blue_big\sbuyOffer"\stitle="Buy"\sid="(\d+)"><span>Buy<\/span><\/a><\/td>[\r\n\s\t]*<\/tr>/;
    my $count = $1;
    if($count>200){
        $count = 200;
    }
    my $id = $2;
    $get =~ m/<input\stype="hidden"\sname="buyMarketOffer\[_csrf_token\]"\svalue="([^"]+)"\sid="buyMarketOffer__csrf_token"\s\/>/;
    my $token = $1;

    my @params = (
        'buyMarketOffer[_csrf_token]='.$token,
        'buyMarketOffer[amount]='.$count,
        'buyMarketOffer[offerId]='.$id
    );

    my $resp = post($url, join('&', @params));

    my $res = ($resp =~ m/<meta.*url=([^"]+)/);
    if($res){
        $resp = get($1);
        $res = ($resp =~ m/<table\sstyle=""\sid=""\sclass="success_message\s">[\r\n\s]+<tbody><tr>[\r\n\s]+<td>([^<]+)<\/td>[\r\n\s]+<\/tr>[\r\n\s]+<\/tbody><\/table>/);
        if($res){
            print $1."\n";
            return 1;
        }else{
            return 0;
        }
    }
}

sub buy_weapos_raw{
    print "Buy weapons raw start\n";
    my $url = 'http://economy.erepublik.com/en/market/40/12';
    my $get = get($url);
    $get =~ m/<tr>[\r\n\s\t]*<td\sclass="m_product"\sid="productId_\d+"\sstyle="width:60px">[\r\n\s\t]*<img\ssrc="[^"]+"\salt=""\sclass="product_tooltip"\sindustry="12"\squality="1"\/>[\r\n\s\t]*<\/td>[\r\n\s\t]*<td\sclass="m_provider">[\r\n\s\t]*<a\shref="[^"]+"\s>[\r\n\s\t]*[^<]*<\/a>[\r\n\s\t]*<\/td>[\r\n\s\t]*<td\sclass="m_stock">[\r\n]*[\s]+(\d+)[\s]+<\/td>[\r\n\s\t]*<td\sclass="m_price\sstprice">[\r\n\s\t]*<strong>\d+<\/strong><sup>\.\d+\s<strong>UAH<\/strong><\/sup>[\r\n\s\t]*<\/td>[\r\n\s\t]*<td\sclass="m_quantity"><input\stype="text"\sclass="shadowed\sbuyField"\sname="textfield"\sid="amount_\d+"\smaxlength="4"\sonkeypress="return\scheckNumber\('int',\sevent\)"\sonblur="return\scheckInput\(this\)"\svalue="1"\/><\/td>[\r\n\s\t]*<td\sclass="m_buy"><a\shref="javascript:;"\sclass="f_light_blue_big\sbuyOffer"\stitle="Buy"\sid="(\d+)"><span>Buy<\/span><\/a><\/td>[\r\n\s\t]*<\/tr>/;

    my $count = $1;
    if($count>1){
        $count = 1;
    }
    my $id = $2;
    $get =~ m/<input\stype="hidden"\sname="buyMarketOffer\[_csrf_token\]"\svalue="([^"]+)"\sid="buyMarketOffer__csrf_token"\s\/>/;
    my $token = $1;

    my @params = (
        'buyMarketOffer[_csrf_token]='.$token,
        'buyMarketOffer[amount]='.$count,
        'buyMarketOffer[offerId]='.$id
    );

    my $resp = post($url, join('&', @params));

    my $res = ($resp =~ m/<meta.*url=([^"]+)/);
    if($res){
        $resp = get($1);
        $res = ($resp =~ m/<table\sstyle=""\sid=""\sclass="success_message\s">[\r\n\s]+<tbody><tr>[\r\n\s]+<td>([^<]+)<\/td>[\r\n\s]+<\/tr>[\r\n\s]+<\/tbody><\/table>/);
        if($res){
            print $1."\n";
            return 1;
        }else{
            return 0;
        }
    }
}

sub buy_raw{
    buy_food_raw;
    buy_weapos_raw;
}

sub work_on_own{

    my $do = 1;
    my $error = 0;

    while ($do && $error == 0){

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

        my $json = post($work_url, join('&', @params));
        my $resp = decode_json $json;
        
        if(!$resp->{status}){
            if($resp->{message} eq 'captcha'){
=cut
    TODO: Captcha processing
=cut
                print $resp->{message}."\n";
                $error = 1;
                return undef;
            }elsif($resp->{message} eq 'not_enough_raw'){
                print "Not enought raw. Buying \n";
                buy_raw;
            }else{
                print $resp->{message}."\n";
                $error = 1;
            }
        }else{
            $do = 0;
        }

    }

    if($error){
        return 0;
    }else{
        return 1;
    }
}

sub get_reward{
    my $json = get('http://www.erepublik.com/daily_tasks_reward');
    my $resp = decode_json $json;
    if(!$resp->{status}){
        if($resp->{message} eq 'captcha'){
=cut
    TODO: Captcha processing
=cut
            print $resp->{message}."\n";
            return 0;
        }else{
            print $resp->{message}."\n";
            return 0;
        }
    }else{
        return 1;
    }
}

sub work_day{
    print "Train started\n";
    my $train = train;
    if($train){
        print "train sucessfull \n";
    }else{
        print "train failed \n";
    }

    print "Work for uncle started\n";
    my $work_for_uncle = work_for_uncle;
    if($work_for_uncle){
        print "Work for uncle sucessfull \n";
    }else{
        print "Work for uncle failed \n";
    }

    print "Work on own started\n";
    my $work_on_own = work_on_own;
    if($work_on_own){
        print "Work on own sucessfull \n";
    }else{
        print "Work on own failed \n";
    }

    if(($work_for_uncle || $work_on_own) && $train){
        print "Getting reward\n";
        if(get_reward){
            print "Sucessfull\n";
        }else{
            print "Unsucessfull\n";
        }
    }
}

sub find_work{
    #<select name="countryId" id="countryId" onchange="javascript:redirect('desc');">
    #    <option title=""></option>
   # 
    get('http://www.erepublik.com/en/economy/job-market/167') =~ m/<select\sname="countryId"\sid="countryId"\sonchange="javascript:redirect\('desc'\);">[\r\n\s]+<option\stitle=""><\/option>([\r\n\s\S]*)<\/select>/;
    my @countries = ($1 =~ m/<option\svalue="(\d+)"\s?[selected=""]*\s?\stitle="[^"]+"><a\shref="javascript:;">[^<]+<\/a><\/option>/g);
    my $max = 0;
    my $max_country = 0;
    foreach my $country (@countries)
    {
        my $res = get('http://www.erepublik.com/en/economy/job-market/'.$country.'/1/desc') =~ m/<td class="jm_salary">[\r\n\s]+<strong>(\d+)<\/strong><sup>([\.\d]+)&nbsp;<strong>[\S]+<\/strong><\/sup>[\r\n\s]+<\/td>/;

        if($res && $country != 11 && $country != 26 && $country != 77){
            my $salary = $1.$2;
            if($max == 0 || $max < $salary){
                $max = $salary;
                $max_country = $country;
            }
        }
    } 
    print $max.' '.$max_country."\n";

    die;
}

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
		
	}elsif($ARGV[0] eq 'find_work'){
        find_work;
    }
}else{
    work_day;
}
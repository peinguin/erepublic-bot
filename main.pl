#!/usr/bin/perl -w
use warnings;
use strict;
use WWW::Curl::Easy;
use Tk;
use JSON;
use Data::Dumper;
use Config::IniFiles;

my $host = 'erepublik.com';
my $protocol = 'http://';
my $prefix = 'www.';
my $lang = '/en';

my $erpk;

sub get_ajax{
    my ($url) = @_;
    perform_request($url, '', 0, 1);
}

sub get{
	my ($url) = @_;
	perform_request($url, '', 0);
}

sub post{
    my ($url, $data) = @_;
    perform_request($url, $data, 1);
}

sub perform_request{
    
    my ($url, $query, $post, $ajax, $show_headers, @additional_cookies) = @_;

    my @standart_cookies=(
        'erpk_auth=1'
    );

    if($erpk){
        push(@additional_cookies, 'erpk='.$erpk);
    }
    
    my @cookies = (
        @standart_cookies, @additional_cookies
    );

    my @headers;
    push(@headers, 'Cookie: '.join('; ', @cookies));
    push(@headers, 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:9.0.1) Gecko/20100101 Firefox/9.0.1 Iceweasel/9.0.1');

    if($ajax){
        push(@headers, 'X-Requested-With: XMLHttpRequest');
    }

    my $curl = WWW::Curl::Easy->new;
    $curl->setopt(CURLOPT_HEADER,$show_headers?1:0);
    $curl->setopt(CURLOPT_HTTPHEADER, \@headers);
    
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

    get($protocol.'economy.'.$host.$lang.'/market/0') =~ m/<select\sname="countryId"\sid="countryId"\sonchange="javascript:redirectToMarket\(this,\s'countryId',\snull\);">[\r\n\s]+<option\svalue="0"\stitle="">Country<\/option>([\r\n\s\S]*)<\/select>/;
    my @countries = ($1 =~ m/<option\s?[selected=""]*\s?\svalue="(\d+)"\stitle="[^"]+">[^<]+<\/option>/g);

    my $min_price = 0;
    my $min_country = 0;
    foreach my $country (@countries)
    {
        my $res = get($protocol.'economy.'.$host.$lang.'/market/'.$country.'/7/1/citizen/0/price_asc/1') =~ m/<td\sclass="m_price\sstprice">[\r\n\s]+<strong>([^<]+)<\/strong><sup>([^<]+)<strong>[^<]+<\/strong><\/sup>[\r\n\s]+<\/td>[\s\S]*<td\sclass="m_buy">/;
        if($res){
            my $price = $1.$2;
            if($min_price == 0 || $min_price > $price){
                $min_price = $price;
                $min_country = $country;
            }
        }
    } 
    print $min_price.' '.$min_country."\n";
}

sub get_token{
    my ($url) = @_;
    get($url) =~ m/<input\stype="hidden"\sname="_token"\svalue="([^"]+)"\sid="award_token"\s\/>/;
    return $1;
}

sub train{
    my $train_url = $protocol.$prefix.$host.$lang.'/economy/train';

    my $content =get($protocol.$prefix.$host.$lang.'/economy/training-grounds');

    my $res = $content =~ m/<input\stype="hidden"\sname="_token"\svalue="([^"]+)"\sid="award_token"\s\/>/;

    if(!$res){
        die "Error get train token";
    }

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

    if($i == 0){
        return 1;
    }

    my $json = post($train_url, join('&', @params));
    my $resp = decode_json $json;

    if(!$resp->{status}){
        if($resp->{message} eq 'captcha'){
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
    my $work_url  = $protocol.$prefix.$host.$lang.'/economy/work';
    my $token = get_token($protocol.$prefix.$host.$lang.'/economy/myCompanies');
    my $json = post($work_url, 'action_type=work&_token='.$token);
    my $resp = decode_json $json;
    if(!$resp->{status}){
        if($resp->{message} eq 'captcha'){
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
    my $url = $protocol.'economy.'.$host.$lang.'/market/40/7';
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
    my $url = $protocol.'economy'.$host.$lang.'/market/40/12';
    my $get = get($url);

    my $res = ($get =~ m/<tr>[\r\n\s\t]*<td\sclass="m_product"\sid="productId_\d+"\sstyle="width:60px">[\r\n\s\t]*<img\ssrc="[^"]+"\salt=""\sclass="product_tooltip"\sindustry="12"\squality="1"\/>[\r\n\s\t]*<\/td>[\r\n\s\t]*<td\sclass="m_provider">[\r\n\s\t]*<a\shref="[^"]+"\s>[\r\n\s\t]*[^<]*<\/a>[\r\n\s\t]*<\/td>[\r\n\s\t]*<td\sclass="m_stock">[\r\n]*[\s]+(\d+)[\s]+<\/td>[\r\n\s\t]*<td\sclass="m_price\sstprice">[\r\n\s\t]*<strong>\d+<\/strong><sup>\.\d+\s<strong>UAH<\/strong><\/sup>[\r\n\s\t]*<\/td>[\r\n\s\t]*<td\sclass="m_quantity"><input\stype="text"\sclass="shadowed\sbuyField"\sname="textfield"\sid="amount_\d+"\smaxlength="4"\sonkeypress="return\scheckNumber\('int',\sevent\)"\sonblur="return\scheckInput\(this\)"\svalue="1"\/><\/td>[\r\n\s\t]*<td\sclass="m_buy"><a\shref="javascript:;"\sclass="f_light_blue_big\sbuyOffer"\stitle="Buy"\sid="(\d+)"><span>Buy<\/span><\/a><\/td>[\r\n\s\t]*<\/tr>/);
    my $count = 0;
    if($res){
        $count = $1;
        if($count>200){
            $count = 200;
        }
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

    $res = ($resp =~ m/<meta.*url=([^"]+)/);
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

        my $work_url  = $protocol.$prefix.$host.$lang.'/economy/work';

        my $get = get($protocol.$prefix.$host.$lang.'/economy/myCompanies');

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
                print $resp->{message}."\n";
                $error = 1;
                return undef;
            }elsif($resp->{message} eq 'not_enough_raw'){
                print "Not enought raw. Buying \n";
                buy_raw;
            }elsif($resp->{message} eq 'not_enough_weapon_raw'){
                print "Not enought weapon raw. Buying \n";
                buy_weapos_raw;
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
    my $json = get($protocol.$prefix.$host.'/daily_tasks_reward');
    my $resp = decode_json $json;
    if(!$resp->{status}){
        if($resp->{message} eq 'captcha'){
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

sub get_notifications{

    my($get) = @_;
    if(!$get){
        $get = get($protocol.$prefix.$host.$lang);
    }

    my $res = ($get =~ /<div\sclass="user_notify">[\r\n\t\s]*<a href="[^"]*"\stitle="[^"]*"\sclass="notify\snmail">[\r\n\t\s]*<img\ssrc="[^"]*"\salt=""\s\/>[\r\n\t\s]*(<em\sclass="fadeInUp">[\r\n\t\s]*\d+[\r\n\t\s]*<span>&nbsp;<\/span>[\r\n\t\s]*<\/em>)?[\r\n\t\s]*<\/a>[\r\n\t\s]*<a\shref="[^"]+"\stitle="[^"]+"\sclass="notify\snalert">[\r\n\t\s]*<img\ssrc="[^"]+"\salt=""\s\/>[\r\n\t\s]*(<em\sclass="fadeInUp">[\r\n\t\s]*\d*[\r\n\t\s]*<span>&nbsp;<\/span>[\r\n\t\s]*<\/em>)?[\r\n\t\s]*<\/a>[\r\n\t\s]*<\/div>/m);

    if($res){
        if($1 || $2){
            return 1;
        }
    }else{
        print $get;
    }
    return undef;
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

    my $countries = decode_json get_ajax($protocol.$prefix.$host.'/country-list-not-conquered');

    my $max = 0;
    my $max_country = 0;
    while (my ($key, $country) = each $countries)
    {
        my $res = get($protocol.$prefix.$host.'/economy/job-market/'.$country->{id}.'/1/desc') =~ m/<td class="jm_salary">[\r\n\s]+<strong>(\d+)<\/strong><sup>([\.\d]+)&nbsp;<strong>[\S]+<\/strong><\/sup>[\r\n\s]+<\/td>/;

        if($res){
            my $salary = $1.$2;
            if($max == 0 || $max < $salary){
                $max = $salary;
                $max_country = $country->{name};
            }
        }
    } 
    print $max.' '.$max_country."\n";
}

sub eat{
    my $get = get($protocol.$prefix.$host);

    print "We must eat? - ";

    my $res = $get =~ m/<strong\sid="current_health">[^\d]*(\d+)\s\/\s(\d+)[^<]*<\/strong>/;

    if($1 < $2){
        print "Yes\n";
        $get =~ m/<big\sclass="tooltip_health_limit">(\d+)\s\/\s300<\/big>/;
        print "We can eat? - ";
        if($1 > 0){
            print "Yes\n";
           
            $get =~ m/<input\stype="hidden"\svalue="([^"]+)"\sid="a69925ed4a6ac8d4b191ead1ab58e853">/;
            $host .= "/main/eat?format=json&_token=".$1."&jsoncallback=?";
            print "Eating \n";
            my $json = get($host);
            $json =~ m/\?\((\{.*\})\)/;
            $json = $1;
            my $resp = decode_json $json;
            if($resp->{health} != 100){
                print "Error\n";
                print $json."\n";
                return 0;
            }else{
                print "Sucessfull\n";
                return 1;
            }
        }else{
            print "No\n";
        }
    }else{
        print "No\n";
    }
}

sub find_food{

    my $min_price = 0;
    my $min_sort = 0;
    for(my $i = 1; $i <= 7; $i++) {
        my $res = get($protocol.$prefix.$host.'/economy/market/40/1/'.$i.'/citizen/0/price_asc/1') =~ m/<tr>[\n\r\s]+<td\s+class="m_product"\s+id="productId_(\d+)"\s+style="width:60px">[\n\r\s]+<img\s+src="[^"]+"\s+alt=""\s+class="product_tooltip"\s+industry="\d+"\s+quality="(\d+)"\/>[\n\r\s]+<\/td>[\n\r\s]+<td\s+class="m_provider">[\n\r\s]+<a\s+href="[^"]+"\s+>[\n\r\s]*[^<]*<\/a>[\n\r\s]+<\/td>[\n\r\s]+<td\s+class="m_stock">[\n\r\s]+(\d+)\s*<\/td>[\n\r\s]+<td\s+class="m_price\s+stprice">[\n\r\s]+<strong>(\d+)<\/strong><sup>\.(\d+)\s*<strong>[^<]+<\/strong><\/sup>[\n\r\s]+<\/td>[\n\r\s]+<td\s+class="m_quantity"><input\s+type="text"\s+class="shadowed\s+buyField"\s+name="textfield"\s+id="amount_\d+"\s+maxlength="4"\s+onkeypress="return\s+checkNumber\('int',\s+event\)"\s+onblur="return\s+checkInput\(this\)"\s+value="1"\/><\/td>[\n\r\s]+<td\s+class="m_buy"><a\s+href="javascript:;"\s+class="f_light_blue_big\s+buyOffer"\s+title="Buy"\s+id="\d+"><span>Buy<\/span><\/a><\/td>[\n\r\s]+<\/tr>/;

        if($res){
            my $price = $4.'.'.$5;
            if($min_price == 0 || $min_price > $price/(2*$2)){
                $min_price = $price/(2*$2);
                $min_sort = $2;
            }

        }

    }

    print $min_price.' '.$min_sort."\n";

    die;
}

sub get_erpk{
    my($email, $password) = @_;

    my $res = get($protocol.$prefix.$host.$lang) =~ m/<input\stype="hidden"\sid="_token"\sname="_token"\svalue="([^"]+)">/;

    if($res){
        my $token = $1;
        my $resp = perform_request($protocol.$prefix.$host.$lang.'/login', '_token='.$token.'&citizen_email='.$email.'&citizen_password='.$password, 1,0,1);
       
        $res = ($resp =~ m/Set-Cookie:\serpk_mid=([^;]+);/);
        if($res){
            $res = ($resp = perform_request($protocol.$prefix.$host.$lang, '', 0,0,1, ('erpk_mid='.$1)) =~ m/Set-Cookie:\serpk=([^;]+);/);
            if($res){
                return $1;
            }else{
                print $resp;
                die('Error get erpk');            
            }
        }else{
            $res = $resp =~ m/Set-Cookie:\serpk=([^;]+);/;
            if($res){
                return $1;
            }
            die('Error get erpk_mid');            
        }
    }else{
        die('Error get login token');
    }
}

sub logged_in{
    my ($get) = @_;
    if(!$get){
        $get = get($protocol.$prefix.$host.$lang);
    }

    if($get =~ /<div\sid="signin">/m){
        return undef;
    }else{
        return 1;
    }
}

#return -1 if low health
sub fight{

    my ($get) = @_;
    if(!$get){
        $get = get($protocol.$prefix.$host.$lang);
    }

    my $res = $get =~ m/<strong\sid="current_health">[^\d]*(\d+)\s\/\s(\d+)[^<]*<\/strong>/;

    if($res){
        if($1 < 10){
            return -1;
        }

        $res = $get =~ /battleId[\s]+:\s(\d+)/m;
        if($res){
            my $battleId = $1;

            $res = $get =~ /csrfToken[\s]+:\s\'([^']+)\'/m;

            if($res){

                my $token = $1;

                my $url = $protocol.$prefix.$host.$lang."/military/fight-shooot/".$battleId;

                while(1){

                    my $json = post($url, 'battleId='.$battleId.'&_token='.$token);

                    my $resp = decode_json $json;
                    if($resp->{error}){
                        if($resp->{display_captcha}){
                            print "captcha";
                            die;
                        }elsif($resp->{message} eq "UNKNOWN_SIDE"){
                            die $resp->{url};#document.location = response.url;
                        }elsif($resp->{message} eq 'CHANGE_LOCATION'){
                            die "change location";#location.reload();
                        }
                    }

                    my $user = $resp->{user};
                    if($user->{health} < 10){
                        return -1;
                    }
                }

            }else{
                die "Error getting csrf token\n";
            }

        }else{
            die "Error getting battleId\n";   
        }

    }else{
        print 'Failed gat current health'."\n";
        die;
    }
}

sub day_order{

    my ($get) = @_;
    if(!$get){
        $get = get($protocol.$prefix.$host.$lang);
    }

    my $res = ($get =~ /<div class="boxes\sorder_of_day"\sid="orderContainer">/m);
    
    if($res){
        print 'In military unit'."\n";
        return 1;
    }else{

        my $res = ($get =~ /<div class="boxes\srecruit_orders"\sid="recruitOrderContainer">/m);
        if($res){
            $res = get($protocol.$prefix.$host.$lang.'/military/campaigns') =~ /<a\shref="([^"]+)"\stitle=""\sclass="fight_button">/m;
            if($res){
                print 'Recruit order started'."\n";
                fight(get($protocol.$prefix.$host.$1));
            }else{
                print 'Cannot find any campain'."\n";
                return undef;
            }
        }else{
            print 'Not in military unit'."\n";
            if(go_in_military){
                print "Joined in military unit\n";
            }
            return undef;
        }
    }
}

sub play_as_bots{
    my $cfg = Config::IniFiles->new( -file => "config.ini" );

    my $i = 0;
    WHILE: {
        do{
            if($cfg->SectionExists ( 'user'.(++$i) )){

                if(!$cfg->exists('user'.$i, 'erpk')){
                    $cfg->newval('user'.$i, 'erpk', get_erpk($cfg->val( 'user'.$i, 'username' ), $cfg->val( 'user'.$i, 'password' )));
                    $cfg->RewriteConfig;
                }

                $erpk = $cfg->val( 'user'.$i, 'erpk' );

                my $get = get($protocol.$prefix.$host.$lang);

                if(!logged_in($get)){
                    $cfg->setval('user'.$i, 'erpk', get_erpk($cfg->val( 'user'.$i, 'username' ), $cfg->val( 'user'.$i, 'password' )));
                    $erpk = $cfg->val( 'user'.$i, 'erpk' );
                    $get = get($protocol.$prefix.$host.$lang);
                    $cfg->RewriteConfig;
                }

                if(get_notifications($get)){

                    use MIME::Lite;
                    my $msg = MIME::Lite->new (
                        From =>$cfg->val( 'settings', 'email' ),
                        To =>$cfg->val( 'settings', 'email' ),
                        Subject =>'Erepublik notification.',
                        Data =>"Have a new notification ".$cfg->val( 'user'.$i, 'username' ).' '.$cfg->val( 'user'.$i, 'password' )
                        );
                    $msg->send;
                }

                work_day;
                day_order;

            }else{
                last WHILE;
            }
            my $user = {};
            
        }while(1);
    }
}

sub go_in_military{
    my $res = get($protocol.$prefix.$host.'/main/group-home/military') =~ /<div\sclass="mulist">[\r\s\t\n]*<a\shref="([^"]+)"\sclass="unit"\sstyle="display:none;">/m;
    if($res){

        my $resp = get($protocol.$prefix.$host.$1) =~ /<form\saction="([^"]+)"\smethod="post"\sname="groupActionsForm">[\r\s\t\n]*<input\stype="hidden"\sname="groupId"\svalue="([^"]+)"\/>[\r\s\t\n]*<input\stype="hidden"\sname="_token"\svalue="([^"]+)"\s\/>[\r\s\t\n]*<input\stype="hidden"\sname="action"\svalue="apply"\s\/>[\r\s\t\n]*<\/form>/m;

        post($protocol.$prefix.$host.$1, 'groupId='.$2.'&_token='.$3.'&action=apply');
        return 1;
    }else{
        die('Cant find any military unit');
    }
}

sub in_military{

    my ($get) = @_;
    if(!$get){
        $get = get($protocol.$prefix.$host.$lang);
    }

    my $res = ($get =~ /<div class="boxes\s(recruit_orders|order_of_day)"\sid="(recruitOrderContainer|orderContainer)">/m);
    if($res){
        print 'In military unit'."\n";
        return 1;
    }else{
        print 'Not in military unit'."\n";
        return undef;
    }
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
    }elsif($ARGV[0] eq 'work_on_own'){
        work_on_own;
    }
    elsif($ARGV[0] eq 'eat'){
        eat;
    }elsif($ARGV[0] eq 'find_food'){
        find_food;
    }elsif($ARGV[0] eq 'play_as_bots'){
        play_as_bots;
    }elsif($ARGV[0] eq 'work_day'){
        work_day;
    }elsif($ARGV[0] eq 'in_military'){
        in_military;
    }elsif($ARGV[0] eq 'go_in_military'){
        go_in_military;
    }elsif($ARGV[0] eq 'get_notifications'){
        get_notifications;
    }
}else{
    play_as_bots;
}
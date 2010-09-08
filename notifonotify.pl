use strict;
use warnings;

#####
# A lot of code borrowed from the prowlnotify.pl script at
# http://www.denis.lemire.name/2009/07/07/prowl-irssi-hack/

use Irssi;
use Irssi::Irc;
use vars qw($VERSION %IRSSI %config);

use HTTP::Request::Common qw(
    POST
);
use LWP::UserAgent;

$VERSION = '0.1';

%IRSSI = (
	authors => 'Daniel Johansson',
	contact => 'donnex@donnex.net',
	name => 'notifonotify',
	description => 'Send iPhone Notifo.com notification when away and also '
		. 'set away when disconnecting irssi-proxy.',
	license => 'GPLv2',
	url => 'http://donnex.net',
);

$config{away_level} = 0;
$config{awayreason} = 'Auto-away because client has disconnected from proxy.';
$config{clientcount} = 0;

Irssi::settings_add_str($IRSSI{'name'}, 'notifo_username', '');
Irssi::settings_add_str($IRSSI{'name'}, 'notifo_api_secret', '');
Irssi::settings_add_bool($IRSSI{'name'}, 'notifo_debug', 0);


sub debug
{
    return unless Irssi::settings_get_bool('notifo_debug');

    my $text = shift;
    my $caller = caller;
    Irssi::print('From '.$caller.':'."\n".$text."\n");
}

sub send_notifo
{
    debug('Sending notification.');

    my $notifo_username = Irssi::settings_get_str('notifo_username');
    my $notifo_api_secret = Irssi::settings_get_str('notifo_api_secret');
    if (!$notifo_username || !$notifo_api_secret) {
        debug('Missing Notifo username or api secret.');
        return;
    }

    my ($event, $text) = @_;

    my $req = POST(
        'https://api.notifo.com/v1/send_notification',
        [
            label => 'Irssi',
            title => $event,
            msg => $text,
        ]
    );
    $req->authorization_basic(
        $notifo_username,
        $notifo_api_secret
    );

    my $ua = LWP::UserAgent->new();
    my $response = $ua->request($req);
	if ($response->is_success) {
		debug('Notification successfully posted.');
	} elsif ($response->code == 401) {
		debug('Notification not posted: Incorrect username or Notifo API secret.');
	} else {
		debug('Notification not posted: '.$response->decoded_content);
	}
}

sub client_connect
{
	my (@servers) = Irssi::servers;

	$config{clientcount}++;
	debug('Client connected.');

	# setback
	foreach my $server (@servers) {
		# if you're away on that server send yourself back
		if ($server->{usermode_away} == 1) {
			$server->send_raw('AWAY :');
		}
	}
}

sub client_disconnect
{
	my (@servers) = Irssi::servers;
	debug('Client Disconnectted');

	$config{clientcount}-- unless $config{clientcount} == 0;

	# setaway
	if ($config{clientcount} <= $config{away_level}) {
		# ok.. we have the away_level of clients connected or less.
		foreach my $server (@servers) {
			if ($server->{usermode_away} == '0') {
				# we are not away on this server allready.. set the autoaway
				# reason
				$server->send_raw(
					'AWAY :' . $config{awayreason}
				);
			}
		}
	}
}

sub msg_pub
{
	my ($server, $data, $nick, $mask, $target) = @_;
	my $safeNick = quotemeta($server->{nick});

	if ($server->{usermode_away} == '1' && $data =~ /$safeNick/i) {
		debug('Got pub msg with my name.');
		send_notifo('Mention', $target.' '.$nick.': '.strip_formating($data));
	}
}

sub msg_pri
{
	my ($server, $data, $nick, $address) = @_;
	if ($server->{usermode_away} == '1') {
	    debug('Got priv msg.');
		send_notifo('Private msg', $nick.': '.strip_formating($data));
	}
}

sub strip_formating
{
	my ($msg) = @_;
	$msg =~ s/\x03[0-9]{0,2}(,[0-9]{1,2})?//g;
	$msg =~ s/[^\x20-\xFF]//g;
	$msg =~ s/\xa0/ /g;
	return $msg;
}

Irssi::signal_add_last('proxy client connected', 'client_connect');
Irssi::signal_add_last('proxy client disconnected', 'client_disconnect');
Irssi::signal_add_last('message public', 'msg_pub');
Irssi::signal_add_last('message private', 'msg_pri');

Irssi::print('%G>>%n '.$IRSSI{name}.' '.$VERSION.' loaded.');
if (!Irssi::settings_get_str('notifo_username')) {
    Irssi::print('%G>>%n '.$IRSSI{name}.' Notifo username is not set, set it with /set notifo_username username.');
}
if (!Irssi::settings_get_str('notifo_api_secret')) {
    Irssi::print('%G>>%n '.$IRSSI{name}.' Notifo API secret is not set, set it with /set notifo_api_secret api_secret.');
}

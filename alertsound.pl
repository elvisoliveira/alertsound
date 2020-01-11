# AlertSound:
# alertSound - {
#     eventList monster Poring
#     notInTown 1
#     inLockOnly 0
#     play sounds\birds.wav
# }
package alertsound;

use strict;
use Plugins;
use Globals qw($accountID %config %cities_lut $field %players %items @itemsID);
use Log qw(message);
# use Utils::Win32;

Plugins::register('alertsound', 'plays sounds on certain events', \&Unload, \&Reload);
my $packetHook = Plugins::addHooks (
	['player', \&player, undef],
	['self_died', \&death, undef],
	['disconnected', \&disc, undef],
	['packet_pubMsg', \&public, undef],
	['packet_sysMsg', \&system_message, undef],
	['charNameUpdate', \&player, undef],
	['packet_privMsg', \&private, undef],
	['packet_emotion', \&emotion, undef],
	['packet_pre/sendSit', \&sit, undef],
	['packet_itemappeared', \&item, undef],
	['packet/map_change_cell', \&areaupdate],
	['Actor::setStatus::change', \&status, undef],
	['packet_pre/actor_display', \&monster, undef],
	['Network::Receive::map_changed', \&map_change, undef]
);
sub Reload {
	message "alertsound plugin reloading, ";
	Plugins::delHooks($packetHook);
}
sub Unload {
	Plugins::delHooks($packetHook);
}
sub areaupdate {
	my($hook, $args) = @_;
	alertSound("area change");
}
sub item {
	my (undef, $args) = @_;
	my $name = $args->{item}->{name};
	alertSound("item $name");
}
sub death {
	# eventList death
	alertSound("death");
}
sub status {
	# eventList status
	my (undef, $args) = @_;

	if($args->{handle} ne 'EFST_MOVHASTE_INFINITY' &&
	   $args->{handle} ne 'EFST_TWOHANDQUICKEN' &&
	   $args->{handle} ne 'EFST_WEAPONPERFECT' &&
	   $args->{handle} ne 'UNKNOWN_STATUS_824' &&
	   $args->{handle} ne 'UNKNOWN_STATUS_993' &&
	   $args->{handle} ne 'UNKNOWN_STATUS_994' &&
	   $args->{handle} ne 'EFST_ON_PUSH_CART' &&
	   $args->{handle} ne 'EFST_WEIGHTOVER50' &&
	   $args->{handle} ne 'EFST_OVERTHRUST' &&
	   $args->{handle} ne 'EFST_ADRENALINE' &&
	   $args->{handle} ne 'EFST_RIDING' &&
	   $args->{handle} ne 'EFST_SHOUT' &&
	   $args->{handle} ne 'EFST_SIT' &&
	   $args->{actor_type} eq 'Actor::You' &&
	   $args->{flag} eq '1') {
		&debugger($args->{handle});
		&debugger($args->{flag});
		&debugger($args->{tick});
		&debugger($args->{actor_type});
		alertSound("status change");
	}
}
sub sit {
	# eventList sit
	alertSound("sit");
}
sub emotion {
	# eventList emotion
	my (undef, $args) = @_;
	if ($players{$args->{ID}} && $args->{ID} ne $accountID) {
		alertSound("emotion");
	}
}
sub map_change {
	# eventList teleport
	# eventList map change
	my (undef, $args) = @_;
	if ($args->{oldMap} eq $field->{baseName}) {
		alertSound("teleport");
	} else {
		alertSound("map change");
	}
}
sub monster {
	#eventList monster <monster name>
	my (undef, $args) = @_;
	if ($args->{type} >= 1000 and $args->{hair_style} ne 0x64) {
		my $display = ($::monsters_lut{$args->{type}} ne "")
			? $::monsters_lut{$args->{type}}
			: "Unknown ".$args->{type};
		alertSound("monster $display");
	}
}
sub player {
	# eventList player <player name>
	# eventlist player *
	# eventList GM near
	my (undef, $args) = @_;
	my $name = $args->{player}{name};
	my $id = unpack("V1", $args->{player}{ID});

	my @array = qw(100903 100909 100912 100913 100915 100916 100918 100920 100921 100922 100924 100926 100927 100929 100931 100934 100935 100937 100940 100943 100944 100945 100946 100948 100949 100950 100953 100954 100956 100958 100959 100960 100961 100963 100964 100966 100969 100970 100972 100973 100977 100979 231656 1650290 1650292 1650297 1650302 1650306 1650310 1650313 1650315 1650319 1650330 1650296 1650298 1650300 1650303 1650304 1650309 1650312 1650314 1650317 1650320 527214 527215 4025205 4025207 4025208 4025209 4031694);
	my %hash = map { $_, 1 } @array;

	for (my $i = 0; exists $config{"alertSound_".$i."_eventList"}; $i++) {
		next if (!$config{"alertSound_".$i."_eventList"});
		if (Utils::existsInList($config{"alertSound_".$i."_eventList"}, "player *")) {
			alertSound("player *");
			return;
		}
	}

	if (exists($hash{$id})) {
		alertSound("GM near");
	}

	if ($name =~ /^([a-z]?ro)?-?(Sub)?-?\[?GM\]?/i) {
		alertSound("GM near");
	}
	else {
		alertSound("player $name");
	}
}
sub private {
	# eventList private GM chat
	# eventList private chat
	my (undef, $args) = @_;
	if ($args->{privMsgUser} =~ /^([a-z]?ro)?-?(Sub)?-?\[?GM\]?/i) {
		alertSound("private GM chat");
	} else {
		alertSound("private chat");
	}
}
sub public {
	# eventList public GM chat
	# eventList npc chat
	# eventList public chat
	my (undef, $args) = @_;
	if ($args->{pubMsgUser} =~ /^([a-z]?ro)?-?(Sub)?-?\[?GM\]?/i) {
		alertSound("public GM chat");
	} elsif (unpack("V", $args->{pubID}) == 0) {
		alertSound("npc chat");
	} elsif ($args->{pubMsg} =~ /IROZENYSHOP|GOLDAA/g) {
		# alertSound("public chat");
	} else {
		alertSound("public chat");
	}
}
sub disc {
	# eventList disconnected
	alertSound("disconnected");
}
sub system_message {
	# eventList system message
	alertSound("system message");
}
sub alertSound {
	my $event = shift;
	for (my $i = 0; exists $config{"alertSound_".$i."_eventList"}; $i++) {
		next if (!$config{"alertSound_".$i."_eventList"});
		if (Utils::existsInList($config{"alertSound_".$i."_eventList"}, $event)
			&& (!$config{"alertSound_".$i."_notInTown"} || !$cities_lut{$field->baseName().'.rsw'})
			&& (!$config{"alertSound_".$i."_inLockOnly"} || $field->baseName() eq $config{'lockMap'})) {
				$event=~s/ /-/g;
				message("Sound alert: $event\n", "alertSound");
				system("pushbullet.sh " . $config{"username"} . " " . $event);
				# Utils::Win32::playSound($config{"alertSound_".$i."_play"});
				# system("paplay " . $config{"alertSound_" . $i . "_play"});
				
		}
	}
}
# Add plugin information on screem
sub debugger {
	my $datetime = localtime time;

	# use Data::Dumper;
	# message Dumper($_[0])."\n";
	# eval use Data::Dumper;message Dumper($char->statusActive("EFST_POSTDELAY"));
	message "[HAR] $datetime: $_[0].\n";
}
1;

# AlertSound:
# alertSound - {
#     eventList monster Poring
#     notInTown 1
#     inLockOnly 0
#     play sounds\birds.wav
# }
package alertsound;

use strict;
use AI;
use Plugins;
use Data::Dumper;
use Globals qw($accountID %config %cities_lut $field %players $char);
use Log qw(message);
# use Utils::Win32;

Plugins::register('alertsound', 'plays sounds on certain events', \&Unload, \&Reload);
my $packetHook = Plugins::addHooks (
    ["self_died", \&death, undef],
    ["packet_pre/actor_display", \&monster, undef],
    ["charNameUpdate", \&player, undef],
    ["player", \&player, undef],
    ["packet_privMsg", \&private, undef],
    ["packet_pubMsg", \&public, undef],
    ["packet_sysMsg", \&system_message, undef],
    ["packet_emotion", \&emotion, undef],
    ["Network::Receive::map_changed", \&map_change, undef],
    ["is_casting", \&heal_trap, undef],
    ["packet_skilluse", \&heal_trap, undef]
);
sub Reload {
    message "alertsound plugin reloading, ";
    Plugins::delHooks($packetHook);
}
sub Unload {
    Plugins::delHooks($packetHook);
}
sub death {
    # eventList death
    alertSound("death");
}
sub heal_trap {
    # eventList heal_trap
    my($hook, $args) = @_;
    if($args->{skillID} eq 70 || $args->{skillID} eq 28) {
        if($field->baseName() ne 'prt_fild03') {
            alertSound("heal trap");
        }
    }
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
    # eventList monster <monster name>
    my (undef, $args) = @_;
    if ($args->{type} >= 1000 and $args->{hair_style} ne 0x64) {
        my $display = ($::monsters_lut{$args->{type}} ne "")
            ? $::monsters_lut{$args->{type}}
            : "Unknown " . $args->{type};
        alertSound("monster $display");
    }
}
sub player {
    # eventList player <player name>
    # eventlist player *
    # eventList GM near
    my (undef, $args) = @_;
    my $name = $args->{player}{name};
    for (my $i = 0; exists $config{"alertSound_{$i}_eventList"}; $i++) {
        next if (!$config{"alertSound_{$i}_eventList"});
        if (Utils::existsInList($config{"alertSound_{$i}_eventList"}, "player *")) {
            alertSound("player *");
            return;
        }
    }
    if ($name =~ /^([a-z]?ro)? ?\[?GM\]?/i) {
        alertSound("GM near");
    } else {
        alertSound("player {$name}");
    }
}
sub private {
    # eventList private GM chat
    # eventList private chat
    my (undef, $args) = @_;
    if ($args->{privMsgUser} =~ /^([a-z]?ro)?-?(Sub)?-?\[?GM\]?/i) {
        alertSound("private GM chat");
    } elsif ($args->{privMsg} =~ /(Mathilda|Yosuke|Rubalkabara|Asgard)/i) {
        # alertSound("private chat");
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
    } else {
        alertSound("public chat");
    }
}
sub system_message {
    # eventList system message
    alertSound("system message");
}
sub alertSound {
    my $event = shift;
    for (my $i = 0; exists $config{"alertSound_{$i}_eventList"}; $i++) {
        next if (!$config{"alertSound_{$i}_eventList"});
        if (Utils::existsInList($config{"alertSound_{$i}_eventList"}, $event)
            && (!$config{"alertSound_{$i}_notInTown"} || !$cities_lut{$field->baseName().'.rsw'})
            && (!$config{"alertSound_{$i}_inLockOnly"} || $field->baseName() eq $config{'lockMap'})
            && ($field->baseName() ne 'asgard_vil')) {
                # message "Alertsound: $event\n", "alertSound";
                system "play", "-q", $config{"alertSound_{$i}_play"};
                system "tmux switch-client -t $TMUX_PANE";
                # system 'tmux display -pt $TMUX_PANE "====== HERE"';
                AI::state(AI::OFF); AI::clear;
        }
    }
}
1;

#!/usr/bin/perl -w
use strict;

$| = 1;

my $browser = "(?:Firefox|opera|plugin-container|xbmc.bin)";
#my $browser = "(?:Firefox|opera|plugin-container|xbmc.bin|google-chrome|chromium)";
my $LAST_NET_ACTIVE_WINDOW = 0;
my $LAST_NET_WM_WINDOW_TYPE_DIALOG = 0;
my $LAST_NET_ACTIVE_WINDOW_PPID = 0;
my @LAST_NET_ACTIVE_WINDOW_CHILDPID = 0;
my $PS_OPTS='-o user,pid,ppid,%cpu,vsz,rss,stat,time,comm -p';

open (XPROP, "-|", "xprop", "-spy", "-root", "_NET_ACTIVE_WINDOW") or die "could not open $!";

MAIN: while (<XPROP>){
  s/^.* # //; # _NET_ACTIVE_WINDOW(WINDOW): window id #
  s/^.* = //; #TODO: nongreedy # _NET_ACTIVE_WINDOW(STRING) =
  s/"//g;

  chomp;

  #print $_;
  #0x0 = root window
  if ( $_ eq '0x0' ) { next; }
#> _NET_WM_WINDOW_TYPE(ATOM) = _NET_WM_WINDOW_TYPE_DIALOG
  my @NET_ACTIVE_WINDOW_PROPERTIES = `xprop -id $_ WM_CLASS _NET_WM_PID _NET_WM_WINDOW_TYPE _NET_WM_NAME`; 
  chomp @NET_ACTIVE_WINDOW_PROPERTIES;
#TODO: Refactor if active window changes $browser->$browser ie firefox->opera
  if ( $NET_ACTIVE_WINDOW_PROPERTIES[0] =~ m/WM_CLASS.*$browser.*/i ) {
        $LAST_NET_ACTIVE_WINDOW = $_;
        print "LAST_NET_ACTIVE_WINDOW: $LAST_NET_ACTIVE_WINDOW\n";
        #print $NET_ACTIVE_WINDOW_PROPERTIES[1];
        #if ( $LAST_NET_ACTIVE_WINDOW =~ "^0x" ) {
        #  print "1 SIGSTOP sent to: \n";
        #  foreach my $LAST_NET_ACTIVE_WINDOW_CHILDPID (@LAST_NET_ACTIVE_WINDOW_CHILDPID) {
        #    #Don't kill itself
        #    if ($LAST_NET_ACTIVE_WINDOW_CHILDPID != 0 ) {
        #      print "$LAST_NET_ACTIVE_WINDOW_CHILDPID\n";
        #      kill 'SIGSTOP', $LAST_NET_ACTIVE_WINDOW_CHILDPID;
        #      print `ps $PS_OPTS $LAST_NET_ACTIVE_WINDOW_CHILDPID`; 
        #      $LAST_NET_ACTIVE_WINDOW_PPID = 0;
        #    }
        #  }
        #    #Don't kill itself
        #    if ($LAST_NET_ACTIVE_WINDOW_PPID != 0 ) {
        #      kill 'SIGSTOP', $LAST_NET_ACTIVE_WINDOW_PPID;
        #      print `ps $PS_OPTS $LAST_NET_ACTIVE_WINDOW_PPID`; 
        #      @LAST_NET_ACTIVE_WINDOW_CHILDPID = 0;
        #    }
        #}

        my $PPID = $NET_ACTIVE_WINDOW_PROPERTIES[1];
        #print $PPID ."\n";
        $PPID =~ s/.*=//;
        my @CHILDPID = `pgrep -P $PPID`;

        $LAST_NET_ACTIVE_WINDOW_PPID = $PPID;
        @LAST_NET_ACTIVE_WINDOW_CHILDPID = @CHILDPID;

        print "SIGCONT sent to: \n";
        foreach my $CHILDPID (@CHILDPID) {
          kill 'SIGCONT', $CHILDPID;
          print `ps $PS_OPTS $CHILDPID`; 
        }
        kill 'SIGCONT', $PPID;
        print `ps $PS_OPTS $PPID`; 
        print "\n";
        print $NET_ACTIVE_WINDOW_PROPERTIES[2] . "\n";
        
        #Opera crash dialog
        if ($NET_ACTIVE_WINDOW_PROPERTIES[2] ne '_NET_WM_WINDOW_TYPE_DIALOG') {
          $LAST_NET_WM_WINDOW_TYPE_DIALOG = 1;
        } else {
          $LAST_NET_WM_WINDOW_TYPE_DIALOG = 0;
        }
  } else {
    #audio_check();

    #Opera crash dialog
    if ( $LAST_NET_WM_WINDOW_TYPE_DIALOG == 1 ) {
        $LAST_NET_WM_WINDOW_TYPE_DIALOG = 0;
        sleep 1;
        next;
    }
    print "Couldn't match - $NET_ACTIVE_WINDOW_PROPERTIES[0] !~ WM_CLASS.*$browser.*\n";
    print "LAST_NET_ACTIVE_WINDOW: $LAST_NET_ACTIVE_WINDOW\n";

    if ( $LAST_NET_ACTIVE_WINDOW =~ "^0x" && $_ !~ $LAST_NET_ACTIVE_WINDOW) {
        print "SIGSTOP sent to: \n";
        foreach my $LAST_NET_ACTIVE_WINDOW_CHILDPID (@LAST_NET_ACTIVE_WINDOW_CHILDPID) {
          kill 'SIGSTOP', $LAST_NET_ACTIVE_WINDOW_CHILDPID;
          print `ps $PS_OPTS $LAST_NET_ACTIVE_WINDOW_CHILDPID`; 
        }
        kill 'SIGSTOP', $LAST_NET_ACTIVE_WINDOW_PPID;
        print `ps $PS_OPTS $LAST_NET_ACTIVE_WINDOW_PPID`; 
        $LAST_NET_ACTIVE_WINDOW = 0;
        $LAST_NET_ACTIVE_WINDOW_PPID = 0;
        @LAST_NET_ACTIVE_WINDOW_CHILDPID = 0;
    }
    print "\n";

  }
}

sub audio_check {
#flash doesn't close audio, after youtube playback has finished
#check for active card
  open ( AUDIO, "<", "/proc/asound/card1/pcm1p/sub0/hw_params") or die "could not open $!";
    my @AUDIO = <AUDIO>;
    print @AUDIO;
    if ( $AUDIO[0] !~ "closed" ) {
      print "Audio playing won't send SIGSTOP\n";
      next MAIN;
    }
}
#sub sigstop {
#        print "SIGSTOP sent to: \n";
#        foreach my $LAST_NET_ACTIVE_WINDOW_CHILDPID (@LAST_NET_ACTIVE_WINDOW_CHILDPID) {
#          system qq(kill -SIGSTOP $LAST_NET_ACTIVE_WINDOW_CHILDPID);
#          print `ps $PS_OPTS $LAST_NET_ACTIVE_WINDOW_CHILDPID`; 
#        }
#        system qq(kill -SIGSTOP $LAST_NET_ACTIVE_WINDOW_PPID);
#        print `ps $PS_OPTS $LAST_NET_ACTIVE_WINDOW_PPID`; 
#        $LAST_NET_ACTIVE_WINDOW = 0;
#        $LAST_NET_ACTIVE_WINDOW_PPID = 0;
#        @LAST_NET_ACTIVE_WINDOW_CHILDPID = 0;
#}

#TODO: send SIGCONT to all PIDs if main sub receives kill -15
#TODO: send SIGKILL to all PIDs if logout occurS
#close (XPROP) if ^C

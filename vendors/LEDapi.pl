#!/usr/bin/perl

# chmod 755
# sudo apt-get install libdevice-serialport-perl

my $inarg = $ARGV[0] ;
my $showIcon = $ARGV[1];

use Device::MiniLED;
use Switch;
my $sign=Device::MiniLED->new(devicetype => "sign");


# create icons
@icons = (
   "-----------XXX--" . "-----------XXX--" .
   "------XXX-X---X-" . "------XXX-X---X-" .
   "-XXX-X---XX----X" . "-XXX-X---XX----X" .
   "X--XX----X-----X" . "X--XX----X-----X" .
   "X--------------X" . "X--------------X" .
   "X--------------X" . "X--------------X" .
   "-X------------X-" . "-X------------X-" .
   "--XXXXXXXXXXXX--" . "--XXXXXXXXXXXX--" .
   "---X--------X---" . "----------------" .
   "----X---X-------" . "----X--------X--" .
   "---------X---X--" . "-----X---X------" .
   "-----X--------X-" . "----------X----X" .
   "-------X---X---X" . "------X---------" .
   "----------------" . "--------X---X---" .
   "----------------" . "---------X------" .
   "----------------" . "--------------X-",

   "----------------" . "----------------" .
   "-----------XXXX-" . "-----------XXXX-" .
   "---XXXX---X----X" . "---XXXX---X----X" .
   "--X----X-X-----X" . "--X----X-X-----X" .
   "-XX-----X------X" . "-XX-----X------X" .
   "X--------------X" . "X--------------X" .
   "X------XXXXXXXX-" . "X------XXXXXXXX-" .
   "-XXXXXX-----X---" . "-XXXXXX-----X---" .
   "-----X-------X--" . "-----X-------X--" .
   "--XXX-------XXX-" . "--XXX-------XXX-" .
   "-X-------------X" . "-X-------------X" .
   "-X-------------X" . "-X-------------X" .
   "--XXXXXXXXXXXXX-" . "--XXXXXXXXXXXXX-" .
   "----------------" . "----------------" .
   "----------------" . "----------------" .
   "----------------" . "----------------",

   "----------------" . "----------------" .
   "----------------" . "----------------" .
   "-----------X----" . "-----X----------" .
   "X----X----X-----" . "X----X----X-----" .
   "-X-------X------" . "-X-------X------" .
   "----XXX---------" . "----XXX---------" .
   "---X---XXXXXX---" . "---X---XXXXXX---" .
   "--X----X-----X--" . "--X----X-----X--" .
   "X-X--XX------X--" . "X-X--XX------X--" .
   "--XXX-------XXX-" . "--XXX-------XXX-" .
   "-X-------------X" . "-X-------------X" .
   "X-X------------X" . "--X------------X" .
   "---XXXXXXXXXXXX-" . "---XXXXXXXXXXXX-" .
   "----------------" . "----------------" .
   "----------------" . "----------------" .
   "----------------" . "----------------",

   "----------------" . "----------------" .
   "----------------" . "----------------" .
   "--X------------X" . "--------X-------" .
   "---X----X----X--" . "---X----X----X--" .
   "----X-------X---" . "----X-------X---" .
   "-------XXX------" . "-------XXX------" .
   "------X---X-----" . "------X---X-----" .
   "-----X-----X----" . "-----X-----X----" .
   "-XXX-X-----X-XXX" . "--XX-X-----X-XX-" .
   "-----X-----X----" . "-----X-----X----" .
   "------X---X-----" . "------X---X-----" .
   "-------XXX------" . "-------XXX------" .
   "----X------X----" . "----X------X----" .
   "---X----X---X---" . "---X----X---X---" .
   "--X----------X--" . "--------X-------" .
   "----------------" . "----------------");


if ($showIcon && $showIcon ne 'null') {
	switch ($showIcon) {
		case "rain"			{ $iconString = @icons[0] }
		case "overcast"		{ $iconString = @icons[1] }
		case "cloudy"		{ $iconString = @icons[2] }
		case "sunny"		{ $iconString = @icons[3] }
	}
	# translate X to 1, and - to 0
	$iconString=~tr/X-/10/;
	my $icon=$sign->addIcon(
		data => $iconString
	);
	if (length($inarg) > 200) {
	    # a long string isn't as long with an icon
	    my $picFromBits=$sign->addPix(
		    height => 16,
		    width  => 62,
		    data   =>  "$inarg"
		);
		$sign->addMsg(
		  data => "$picFromBits $icon",
		  effect => 'hold',
		);
	} else {
		# plain text with an icon
		$sign->addMsg(
			data => "$inarg $icon",
			effect => 'hold',
		);
	}
} elsif (length($inarg) > 200) {
    # no icon, but still a long string
    my $picFromBits=$sign->addPix(
	    height => 16,
	    width  => 96,
	    data   =>  "$inarg"
	);
	$sign->addMsg(
	  data => "$picFromBits",
	  effect => 'hold',
	);
} else {
	# just print the scrolling text
	$sign->addMsg(
	  data => "$inarg",
	  effect => 'scroll',
	);
}


$sign->send(device => "/dev/ttyUSB0");
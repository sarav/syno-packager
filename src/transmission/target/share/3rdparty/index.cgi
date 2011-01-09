#!/usr/bin/perl -w
# Copyright 2010 Antoine Bertin
# <diaoulael dot devel [ignore this] at users.sourceforge period net>
#
# This file is part of syno-packager.
#
# syno-packager is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# syno-packager is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with syno-packager.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use CGI;
use IO::Dir;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);

# Const
my $TRDIR = "/usr/local/transmission";
my $TRETC = "$TRDIR/etc";
my $TRBIN = "$TRDIR/bin";
my $TRUSRADD = "$TRBIN/transmission-adduser";
my $TRUSRDEL = "$TRBIN/transmission-deluser";
my $TRUSRSET = "$TRBIN/transmission-setting";
my $TRUSR = "$TRETC/users";
my $HOMEDIR = "/var/services/homes/";
my $SYAUTH = "/usr/syno/synoman/webman/modules/authenticate.cgi|";

# CGI
my $q = CGI->new;

# Start the renderer
print $q->header,
	$q->start_html(-title=>'Transmission User Manager', -style=>{'src'=>'index.css'});

# Controller
if (!&isAuthed()) {
	print $q->h1({-class => 'error'}, "You are not authenticated !");
} else {
	if (!&checkForSynoUsers()) {
		print $q->h1({-class => 'error'}, "Enable home service to continue !");
	} else {
		my @syno = &getSynoUsers();
		if ($q->param("submit")) {
			&processForm(@syno);
		}
		$q->delete_all();
		&displayForm(@syno);
	}
}
	
# End the renderer
print $q->end_html;





#################
# Subs are here #
#################
#
# Displays the form
sub displayForm {
	my %tr = &getTransmissionUsers();
	print $q->start_form,
		$q->start_table({-border=>1, -cellspacing=>0, -cellpadding=>3}),
		$q->start_Tr,
		$q->th("Service<br />enabled"),
		$q->th("Username"),
		$q->th("Port"),
		$q->th("Password"),
		$q->end_Tr;
	foreach (@_) {
		print $q->start_Tr,
			$q->td({-class => "check"}, $q->checkbox(-id => lc($_) . "_check", -name => 'users', -value => "$_", -label => "", -checked => defined($tr{"$_"}))),
			$q->td({-class => "username"}, $q->label({-for=>lc($_) . "_check"}, $_)),
			$q->td({-class => "port"}, $q->textfield(-name => lc($_) . "_port", -id => lc($_) . "_port", -maxlength => 5, -value => $tr{"$_"})),
			$q->td({-class => "password"}, $q->password_field(-name => lc($_) . "_password", -id => lc($_) . "_password")),
			$q->end_Tr;
	}
	print $q->end_table,
		$q->submit(-name => "submit", -id => "submit", -value => "Submit"),
		$q->end_form;
}

# Do the transmission stuff
sub processForm {
	print $q->h1("Form processed");
	my @syUsers = &getSynoUsers();
	my %trUsers = &getTransmissionUsers();
	my %fmUsers = map { $_ => 1 } $q->param("users");

	# Loop on each user
	foreach (@syUsers) {
		# Add the user
		if (exists($fmUsers{"$_"}) && !exists($trUsers{"$_"}) && $q->param(lc($_) . "_port") ne "" && $q->param(lc($_) . "_password") ne "") {
			system("$TRUSRADD $_ " . $q->param(lc($_) . "_port") . " " . $q->param(lc($_) . "_password") . " > /dev/null 2>&1");
			print $q->p("Added user : $_ with transmission UI port " . $q->param(lc($_) . "_port"));
		}
		
		# Remove the user
		if (!exists($fmUsers{"$_"}) && exists($trUsers{"$_"})) {
			system("$TRUSRDEL $_ > /dev/null 2>&1");
			print $q->p("Removed user : $_");
		}
		
		# Modify
		if (exists($fmUsers{"$_"}) && exists($trUsers{"$_"})) {
			# Changed password
			if ($q->param(lc($_) . "_password") ne "") {
				system("$TRUSRSET $_ password " . $q->param(lc($_) . "_password") . " > /dev/null 2>&1");
				print $q->p("Modified password for : $_");
			}
			# Changed port
			if ($q->param(lc($_) . "_port") != $trUsers{"$_"}) {
				system("$TRUSRSET $_ port " . $q->param(lc($_) . "_port") . " > /dev/null 2>&1");
				print $q->p("Changed port for : $_");
			}
		}
	}
}

# Check for user's authentication
sub isAuthed {
	my $user;
	if (open(IN,$SYAUTH)) {
		$user=<IN>;
		chop($user);
		close(IN);
	}
	if (!$user) {
		return 0;
	}
	return 1;
}

# Retrieve Transmission users as an array
sub getTransmissionUsers {
	my $f = IO::File->new($TRUSR, "r");
	my %tr;
	if (defined($f)) {
		while (<$f>) {
			chomp;
			(my $user, my $port) = split(/:/);
			$tr{"$user"} = "$port";
		}
	} else {
		die "Can't find the transmission users file !";
	}
	return %tr;
}

# Retrieve the DiskStation users as an array
sub getSynoUsers {
	my $d = IO::Dir->new($HOMEDIR);
	my @syno;
	if (defined $d) {
		while (defined($_ = $d->read)) {
			if ($_ ne "." && $_ ne "..") {
				push(@syno, $_);
			}
		}
	}
	undef $d;
	return sort(@syno);
}

# Checks for people so we can continue
sub checkForSynoUsers {
	my @syno = &getSynoUsers();
	my $count = @syno;
	if (!$count > 0) {
		return 0;
	}
	return 1;
}


#!/usr/bin/perl -w
# Copyright 2010 Antoine Bertin
# <diaoulael [ignore this] at users.sourceforge period net>
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
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);

# Const
my $SYAUTH = "/usr/syno/synoman/webman/modules/authenticate.cgi|";

# CGI
my $q = CGI->new;

# Controller
if (&isAuthed()) {
	print $q->redirect("mumble://".$ENV{SERVER_ADDR}."/?version=1.2.2");
} else {
	print $q->header;
	
	# Get the browser language
	my %languages = split(/[,;]/, $ENV{HTTP_ACCEPT_LANGUAGE});
	
	# Print specific content
	if (exists($languages{"fr"}) || exists($languages{"fr-FR"}) || exists($languages{"fr-fr"})) {
		print $q->start_html("uMurmur - Authentification requise");
		print $q->h4("Veuillez vous connecter au DSM pour continuer...");
	} else {
		print $q->start_html("uMurmur - Authentication required");
		print $q->h4("Please connect to DSM to continue...");
	}
	print $q->end_html;
}





#################
# Subs are here #
#################
#
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

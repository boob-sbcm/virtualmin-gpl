#!/usr/local/bin/perl
# Delete server aliases from a virtual server

require './virtual-server-lib.pl';
&ReadParse();
&error_setup($text{'aliases_derr'});
$d = &get_domain($in{'dom'});
&can_edit_domain($d) || &error($text{'aliases_ecannot'});
@aliases = &list_domain_aliases($d);
@del = split(/\0/, $in{'d'});
@del || &error($text{'aliases_ednone'});

# Do the deletion
foreach $a (@del) {
	($alias) = grep { $_->{'from'} eq $a } @aliases;
	if ($alias) {
		&delete_virtuser($alias);
		}
	}
&webmin_log("delete", "aliases", scalar(@del),
	    { 'dom' => $d->{'dom'} });
&redirect("list_aliases.cgi?dom=$in{'dom'}");


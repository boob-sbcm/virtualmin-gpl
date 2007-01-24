#!/usr/local/bin/perl
# Show a form for changing settings in multiple users at once

require './virtual-server-lib.pl';
&ReadParse();
&error_setup($text{'mass_err'});
$d = &get_domain($in{'dom'});
&can_edit_domain($d) || &error($text{'users_ecannot'});
&can_edit_users() || &error($text{'users_ecannot'});
@mass = split(/\0/, $in{'d'});
@mass || &error($text{'mass_enone'});

&ui_print_header(&domain_in($d), $text{'mass_title'}, "");
print &text('mass_desc', scalar(@mass)),"<p>\n";

print &ui_form_start("mass_change.cgi", "post");
foreach $d (@mass) {
	print &ui_hidden("d", $d),"\n";
	}
print &ui_hidden("dom", $in{'dom'}),"\n";
print &ui_table_start($text{'mass_header'}, undef, 2);

# Inputs for quotas
@qtypes = ( );
push(@qtypes, "quota") if (&has_home_quotas());
push(@qtypes, "mquota") if (&has_mail_quotas());
push(@qtypes, "qquota") if (&has_server_quotas());
foreach $quota (@qtypes) {
	print &ui_table_row($text{'mass_'.$quota},
	    &ui_radio($quota."_def", 0,
		      [ [ 0, $text{'mass_leave'} ],
			[ 1, $text{'mass_unlimited'} ],
			[ 2, $text{'mass_set'} ] ])."\n".
		      ($quota eq "qquota" ?
			&ui_textbox($quota, undef, 10) :
		        &quota_input($quota, undef,
				     $quota eq "quota" ? "home" : "mail")));
	}

# Primary email address
print &ui_table_row($text{'mass_email'},
	    &ui_radio('email', 0,
		      [ [ 0, $text{'mass_leave'} ],
			[ 1, $text{'mass_enable'} ],
			[ 2, $text{'mass_disable'} ] ]));

# FTP login
if (&can_mailbox_ftp()) {
	print &ui_table_row($text{'mass_ftp'},
		    &ui_radio('ftp', 0,
			      [ [ 0, $text{'mass_leave'} ],
				[ 1, $text{'mass_enable'} ],
				( $config{'jail_shell'} ?
					( [ 3, $text{'mass_jail'} ] ) : ( ) ),
				[ 2, $text{'mass_disable'} ] ]));
	}

# Disable or enable
print &ui_table_row($text{'mass_tempdisable'},
	    &ui_radio('disable', 0,
		      [ [ 0, $text{'mass_leave'} ],
			[ 1, $text{'mass_enable'} ],
			[ 2, $text{'mass_disable'} ] ]));

print &ui_table_end();
print &ui_form_end([ [ "mass", $text{'mass_ok'} ] ]);

&ui_print_footer("list_users.cgi?dom=$in{'dom'}", $text{'users_return'},
		 "", $text{'index_return2'});

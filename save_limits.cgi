#!/usr/local/bin/perl
# edit_limits.cgi
# Display access control and usage limits for this domain's user

require './virtual-server-lib.pl';
&ReadParse();
$d = &get_domain($in{'dom'});
&can_edit_limits($d) || &error($text{'edit_ecannot'});

# Validate and store inputs
&error_setup($text{'limits_err'});
$in{'mailboxlimit_def'} || $in{'mailboxlimit'} =~ /^[1-9]\d*$/ ||
	&error($text{'setup_emailboxlimit'});
$d->{'mailboxlimit'} = $in{'mailboxlimit_def'} ? undef : $in{'mailboxlimit'};
$in{'aliaslimit_def'} || $in{'aliaslimit'} =~ /^[1-9]\d*$/ ||
	&error($text{'setup_ealiaslimit'});
$d->{'aliaslimit'} = $in{'aliaslimit_def'} ? undef : $in{'aliaslimit'};
$in{'dbslimit_def'} || $in{'dbslimit'} =~ /^[1-9]\d*$/ ||
	&error($text{'setup_edbslimit'});
$d->{'dbslimit'} = $in{'dbslimit_def'} ? undef : $in{'dbslimit'};
$in{'domslimit_def'} || $in{'domslimit'} =~ /^\d+$/ ||
	&error($text{'limits_edomslimit'});
$d->{'domslimit'} = $in{'domslimit_def'} == 1 ? undef :
		    $in{'domslimit_def'} == 2 ? "*" : $in{'domslimit'};
$in{'aliasdomslimit_def'} || $in{'aliasdomslimit'} =~ /^\d+$/ ||
	&error($text{'limits_ealiasdomslimit'});
$d->{'aliasdomslimit'} = $in{'aliasdomslimit_def'} == 1 ? undef
		   					: $in{'aliasdomslimit'};
$in{'realdomslimit_def'} || $in{'realdomslimit'} =~ /^\d+$/ ||
	&error($text{'limits_erealdomslimit'});
$d->{'realdomslimit'} = $in{'realdomslimit_def'} == 1 ? undef
		   				      : $in{'realdomslimit'};
$d->{'nodbname'} = $in{'nodbname'};
$d->{'norename'} = $in{'norename'};
$d->{'forceunder'} = $in{'forceunder'};
$d->{'demo'} = $in{'demo'};
%sel_features = map { $_, 1 } split(/\0/, $in{'features'});
foreach $f (@opt_features, "virt", @feature_plugins) {
	next if (!&can_use_feature($f));
	next if ($config{$f} == 3);
	$d->{"limit_".$f} = $sel_features{$f};
	}
if (&can_webmin_modules()) {
	$d->{'webmin_modules'} = $in{'modules'};
	}

# Save edit options
%sel_edits = map { $_, 1 } split(/\0/, $in{'edit'});
foreach $ed (@edit_limits) {
	$d->{"edit_".$ed} = $sel_edits{$ed};
	}

# Save plugin inputs
foreach $f (@feature_plugins) {
	$err = &plugin_call($f, "feature_limits_parse", $d, \%in);
	&error($err) if ($err);
	}

# Update files
&set_all_null_print();
&save_domain($d);
if (defined($in{'shell'})) {
	# Update shell
	$user = &get_domain_owner($d);
	$olduser = { %$user };
	$user->{'shell'} = $in{'shell'};
	&modify_user($user, $olduser, undef);
	}
&refresh_webmin_user($d);
&run_post_actions();
&webmin_log("limits", "domain", $d->{'dom'}, $d);

&domain_redirect($d);



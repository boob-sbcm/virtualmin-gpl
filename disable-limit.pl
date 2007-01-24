#!/usr/local/bin/perl
# Disable some limit for a domain from the command line

package virtual_server;
$main::no_acl_check++;
$ENV{'WEBMIN_CONFIG'} ||= "/etc/webmin";
$ENV{'WEBMIN_VAR'} ||= "/var/webmin";
if ($0 =~ /^(.*\/)[^\/]+$/) {
	chdir($1);
	}
chop($pwd = `pwd`);
$0 = "$pwd/disable-limit.pl";
require './virtual-server-lib.pl';
$< == 0 || die "disable-limit.pl must be run as root";

$first_print = \&first_text_print;
$second_print = \&second_text_print;
$indent_print = \&indent_text_print;
$outdent_print = \&outdent_text_print;

# Parse command-line args
while(@ARGV > 0) {
	local $a = shift(@ARGV);
	if ($a eq "--domain") {
		push(@dnames, shift(@ARGV));
		}
	elsif ($a eq "--all-domains") {
		$all_doms = 1;
		}
	elsif ($a eq "--dbname") {
		$nodbname = 1;
		}
	elsif ($a =~ /^--(\S+)$/ &&
	       &indexof($1, @features) >= 0) {
		$config{$1} || &usage("The $a option cannot be used unless the feature is enabled in the module configuration");
		$feature{$1}++;
		}
	elsif ($a =~ /^--(\S+)$/ &&
	       &indexof($1, @feature_plugins) >= 0) {
		$plugin{$1}++;
		}
	elsif ($a =~ /^--cannot-edit-(\S+)$/ &&
	       &indexof($1, @edit_limits) >= 0) {
		$edit{$1}++;
		}
	}
@dnames || $all_doms || usage();

# Get domains to update
if ($all_doms) {
	@doms = &list_domains();
	@doms = grep { $_->{'unix'} && !$_->{'alias'} } @doms;
	}
else {
	foreach $n (@dnames) {
		$d = &get_domain_by("dom", $n);
		$d || &usage("Domain $n does not exist");
		$d->{'unix'} && !$d->{'alias'} || &usage("Domain $n doesn't have limits");
		push(@doms, $d);
		}
	}

# Do it for all domains
foreach $d (@doms) {
	&$first_print("Updating server $d->{'dom'} ..");
	&$indent_print();
	@dom_features = $d->{'alias'} ? @alias_features :
			$d->{'parent'} ? ( grep { $_ ne "webmin" } @features ) :
					 @features;

	# Disable access to a bunch of features
	foreach $f (@dom_features, @feature_plugins) {
		if ($feature{$f} || $plugin{$f}) {
			$d->{"limit_$f"} = 0;
			}
		}

	# Disallow choice of DB name
	if ($nodbname) {
		$d->{'nodbname'} = 1;
		}

	# Update edits
	foreach $ed (@edit_limits) {
		$d->{'edit_'.$ed} = 0 if ($edit{$ed});
		}

	# Save new domain details
	&save_domain($d);

	&refresh_webmin_user($d);

	&$outdent_print();
	&$second_print(".. done");
	}

&run_post_actions();

sub usage
{
print "$_[0]\n\n" if ($_[0]);
print "Enables limits for one or more domains specified on the command line.\n";
print "\n";
print "usage: disable-limit.pl [--domain name] | [--all-domains]\n";
print "                        [--dbname]\n";
foreach $f (@features) {
	print "                         [--$f]\n" if ($config{$f});
	}
foreach $f (@feature_plugins) {
	print "                         [--$f]\n";
	}
foreach $f (@edit_limits) {
	print "                         [--cannot-edit-$f]\n";
	}
exit(1);
}


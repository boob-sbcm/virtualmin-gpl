#!/usr/local/bin/perl

=head1 info.pl

Show general information about this Virtualmin system.

This command is useful when debugging or configuring a system that you
don't know much about, to fetch general information about Webmin, Virtualmin,
IP usage and installed programs.

By default it outputs all available data, most of which is generated by
Virtualmin's background collection job that runs every 5 minutes. However,
you can limit it to a subset by adding command like parameters corresponding
to sections of the full output. For example :

  [root@fudu ~]# virtualmin info host
  host:
      hostname: fudu.home
      module root: /usr/local/webadmin/virtual-server
      os: Redhat Linux Fedora 9
      root: /usr/local/webadmin
      theme version: 6.6
      virtualmin version: 3.65
      webmin version: 1.449

=cut

package virtual_server;
if (!$module_name) {
	$main::no_acl_check++;
	$ENV{'WEBMIN_CONFIG'} ||= "/etc/webmin";
	$ENV{'WEBMIN_VAR'} ||= "/var/webmin";
	if ($0 =~ /^(.*)\/[^\/]+$/) {
		chdir($pwd = $1);
		}
	else {
		chop($pwd = `pwd`);
		}
	$0 = "$pwd/info.pl";
	require './virtual-server-lib.pl';
	$< == 0 || die "info.pl must be run as root";
	}

while(@ARGV > 0) {
	local $a = shift(@ARGV);
	if ($a eq "--help") {
		&usage();
		}
	elsif ($a eq "--search") {
		push(@searches, shift(@ARGV));
		}
	else {
		push(@searches, $a);
		}
	}

$info = &get_collected_info();
%tinfo = &get_theme_info($current_theme);
$info->{'host'} = { 'hostname', &get_system_hostname(),
		    'os' => $gconfig{'real_os_type'}.' '.
			    $gconfig{'real_os_version'},
		    'webmin version' => &get_webmin_version(),
		    'virtualmin version' => $module_info{'version'},
		    'theme version' => $tinfo{'version'},
		    'root' => $root_directory,
		    'module root' => $module_root_directory,
		  };
$info->{'status'} = $info->{'startstop'};
foreach $s (@{$info->{'status'}}) {
	delete($s->{'desc'});
	delete($s->{'longdesc'});
	delete($s->{'links'});
	delete($s->{'restartdesc'});
	delete($s->{'startdesc'});
	delete($s->{'stopdesc'});
	}
delete($info->{'startstop'});
delete($info->{'quota'});
delete($info->{'inst'}) if (!@{$info->{'inst'}});
delete($info->{'poss'}) if (!@{$info->{'poss'}});
delete($info->{'allposs'}) if (!@{$info->{'allposs'}});
delete($info->{'fextra'});
delete($info->{'fhide'});
delete($info->{'fmax'});
foreach my $k (keys %$info) {
	delete($info->{$k}) if (!&info_search_match($k));
	}
&recursive_info_dump($info, "");

sub recursive_info_dump
{
local ($info, $indent) = @_;

# Dump object, depending on type
if (ref($info) eq "ARRAY") {
	foreach $k (@$info) {
		print $indent,"* ";
		if (ref($k)) {
			print "\n";
			&recursive_info_dump($k, $indent."    ");
			}
		else {
			print $k,"\n";
			}
		}
	}
elsif (ref($info) eq "HASH") {
	foreach $k (sort { $a cmp $b } keys %$info) {
		print $indent,$k,": ";
		if (ref($info->{$k})) {
			print "\n";
			&recursive_info_dump($info->{$k}, $indent."    ");
			}
		else {
			print $info->{$k},"\n";
			}
		}
	}
else {
	print $indent,$info,"\n";
	}
}

sub info_search_match
{
local ($i) = @_;
if (@searches && !ref($i)) {
	foreach my $s (@searches) {
		return 1 if ($i =~ /\Q$s\E/i);
		}
	return 0;
	}
return 1;
}

sub usage
{
print "$_[0]\n\n" if ($_[0]);
print "Displays information about this Virtualmin system.\n";
print "\n";
print "virtualmin info [--search 'info'|'ips'|'mem'|'progs'|...]\n";
exit(1);
}


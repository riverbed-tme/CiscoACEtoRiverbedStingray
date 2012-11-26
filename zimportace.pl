#!/usr/bin/perl 
# Script to convert Cisco ACE Configuration file to Stingray Traffic Manager Configuration.
#
# Author: Vinay Reddy
# 10/12
#
# Usage: perl zimportace.pl <ace_config_file> 
#
#
#
# Note: This script is not intended for complete migration. Please contact your sales engineer or Riverbed Technical support for getting help on complete migration.
#use strict;
use feature qw(say switch);
use Findbin;
use lib "$FindBin::Bin";
use modules::pool;
use modules::vserver;
use modules::monitor;
use Archive::Tar;
use File::Find;
use File::Path;


#if ($#ARGV < 1) { print "Usage: perl zimportace.pl <ace_config_file> <Traffic Manager Name> \n"; exit };
print "Enter the Cisco ACE configuration file:";
$config = <>;
open("config","<$config") or die "Cannot read file $config.";
print "Enter the directory name that contains ACE SSl Certificates and Keys:";
our $ace_ssl_dir= <>;
open(LOGFILE,">log.txt") or die "Cannot read file log.txt.";
$stmname = $ARGV[1];
my %classl3l4_to_vip = ();
my %classvip_to_pol_slb = ();
my %classvip_ssl = ();
my %classl3l4_to_ssl = ();
my %serverfarm_nodes = ();
my %ssl_service = ();
my %pol_slb_to_l7 = ();
my %pol_mm_class_vip = ();
my %class_l7_to_serverfarm = ();
my %rserver_ip = ();
my %rserver_status = ();
my %rserver_probe = ();
my $count = 1;
my @words =();
my @pools =();
my %allPools = ();
my %allProbes = ();
my %allvirtual = ();
my %allsticky = ();
my %pol_slb_to_serverfarm = ();
my $line;
print LOGFILE "Following Configuration sections could not be migrated!!!\n";
print LOGFILE "#################################################\n";
#################### Main Loop #############################
while ($line = <config>) {
	$line =~ s/^\s+//;
	my @words = split (" ",$line);
	
#########Probe Extraction#####################
	if ( $words[0] eq "probe" ) {
		my $probe_type = $words[1];
		my $probe_name = $words[2];
		my $monitor = new monitor ( "$probe_name");
		$monitor->setType("$probe_type");
		print LOGFILE "$line";
		if ( $probe_type eq "tcp" or $probe_type eq "http" or $probe_type eq "https" ) {
monLoop:	while ( $line = <config> ) {
				$line =~ s/^\s+//;
				@words = split(" ",$line);
				if (  $line eq "\r"  or $line =~ m/^!/i or $line eq "" ) { last monLoop ; }
				if ( $words[0] eq "probe") { seek("config", -(length($line)+1), 1);last monLoop;}
				if ( $line =~ m/request method get url\s(.*)/) { $monitor->setPath("$1"); next}
				if ( $words[0] eq "interval" ) { $monitor->setDelay("$words[1]"); next}
				if ($words[0] eq "faildetect") { $monitor->setFailure("$words[1]");next}
				if ($words[0] eq "expect" and $words[1] eq "status") { $monitor->setStatus("$words[2] $words[3]");next}
				if ($words[0] eq "expect" and $words[1] eq "regex") { $monitor->setBody("$words[2]");next}
				if ($words[0] eq "header" and $words[1] eq "host" ) { $monitor->setHeader("$words[3]");next}
				else { print LOGFILE "!$line"; }	
			}
			
		}
	
	$allProbes{$monitor->getName()} = $monitor;
	}
######## Node Name to IP  Extraction #######################
	if  ( $words[0] eq "rserver" and $words[1] eq "host") {
        my $rservername = $words[2]; 
		print LOGFILE "$line";
rsLoop: while( $line = <config> ) {
			$line =~ s/^\s+//;
            @words = split(" ",$line);
			if (  $line eq "\r"  or $line =~ m/^!/i or $line eq "" ) {
				last rsLoop;
			}
			if ( $words[0] eq  "rserver" or $words[0] eq "serverfarm"  ) {
            	seek("config", -(length($line)+1), 1);
			    last rsLoop;
            }
			 elsif ($words[0] eq "ip" or $words[0] eq "inservice" ) {
                given ($words[0]) {
                    when ("ip") { $rserver_ip{$rservername} = $words[2]; }
                    when ("inservice") { $rserver_status{$rservername} = "Active"; }
                   #when ("probe") { $rserver_probe{$rservername} = $words[1]; }
                    }
					next;
                }
			else { print LOGFILE "$line"; }	
        }
	}
####### Pools Extraction ########
	if ( $words[0] eq "serverfarm" and $words[1] eq "host") {
		my $sfname = $words[2];
		push( @pools , $sfname);
		my $pool = new pool ("$sfname");
		print LOGFILE "$line";
sfLoop:	while( $line = <config> ) {
			$line =~ s/^\s+//;
			@words = split(" ",$line);
			if (  $line eq "\r"  or $line =~ m/^!/i or $line eq "" ) {
				last sfLoop;
			}
			if ( $words[0] eq "serverfarm" ) {
				seek("config", -(length($line)+1), 1);
				last sfLoop;
			} 
			if ($line =~ m/description\s(.*?)$/ ) {
				$pool->setNote($1);
			} else {
				given ($words[0]) {
					when ("rserver") {
						my $nodename = $words[1];
						my $nodeport = $words[2];
						$pool->addNode("$rserver_ip{$nodename}:$nodeport");
						 next;
					}
					when ("predictor") { 
						if ( $words[1] 	eq "hash") {
							print LOGFILE "!$line";print "ACE using HASH based Load balancing. Create TrafficScript manually on Stingray\n"; next;
						}
						if ( $words[1] eq "least-bandwidth" ) {
							print LOGFILE "!$line";print "ACE using least-bandwidth based Load balancing. Create TrafficScript manually on Stingray\n"; next;
						}
						if ( $words[1] eq "leastconns" ){
							$pool->setLB("connections"); next;
						}
						if ( $words[1] eq "roundrobin" ) {
							$pool->setLB("Round Robin");next;
						}
						if ( $words[1] eq "response" ) {
							$pool->setLB("responsetimes");next;
						}
						if ( $words[1] eq "least-loaded" ) {
							print LOGFILE "!$line";print "ACE using least-loaded based Load balancing. Create TrafficScript manually on Stingray\n";next;
						}
					}
					when ("probe") { $pool->setMonitor("$words[1]"); next;}
					when ("transparent"){ print LOGFILE "!$line"; print "Currently Stingray doesn't support Transparent feature which is used in DSR\n"; next;}
					when ("inservice") { $pool->setState("active");next;}
					when ("weight"){ $pool->setWeight("$words[1]");next;}
					default { print LOGFILE "!$line";next; }
				}
			}
		}
		$allPools{$pool->getName()} = $pool ;
	}
####### Sticky Serverfarm Extraction #########
	if ($line =~ m/sticky\sip-netmask\s\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}\saddress\s((source)|(destination)|(both))\s(\w.*)/ ) {
		my $stickyname = $5;
		my $stickytype = "ip";
		print LOGFILE "$line";
		while ( $line = <config>) {
			$line =~ s/^\s+//;
			@words = split(" ",$line);
			if (  $line eq "\r"  or $line =~ m/^!/i or $line eq "" ) { last;}
			if ($words[0] eq "sticky") { seek("config", -(length($line)+1), 1);last;}
			if ($words[0] eq "serverfarm") { 
				$allsticky{$stickyname} = $words[1];
				$allPools{$words[1]}->setPersist("$stickyname"); 
				$allPools{$words[1]}->setPersistType($stickytype);
				next;
			}
			else { print LOGFILE "!$line"; }
		}
	}
	if ($line =~ m/sticky\shttp-cookie\s(\w.*)\s(\w.*)/ ) {
		my $cookiename = $1;
		my $stickyname = $2;
		print LOGFILE "$line";
		if ($cookiename eq "JSESSIONID") {  $stickytype = "j2ee"; } else {  $stickytype = "kipper";}
		#print "sticky-name:$stickyname -cookiename:$cookiename  - Stickytype:$stickytype\n";
		while ( $line = <config>) {
			$line =~ s/^\s+//;
			@words = split(" ",$line);
			if (  $line eq "\r"  or $line =~ m/^!/i or $line eq "" ) { last;}
			if ($words[0] eq "sticky") { seek("config", -(length($line)+1), 1);last;}
			if ( $words[0] eq "cookie" and $words[1] eq "insert") { my $stickytype = "sardine"; next; }
			if ($words[0] eq "serverfarm") { 
				$allsticky{$stickyname} = $words[1];
				$allPools{$words[1]}->setPersist($stickyname); 
				$allPools{$words[1]}->setPersistType($stickytype); 
				$allPools{$words[1]}->setPersistCookie($cookiename);
				next;
			}
			else { print LOGFILE "!$line"; }
		}
	}	
####### SSL Proxy Extraction #######################
	if ( $words[0] eq "ssl-proxy" and $words[1] eq "service") {
		my $ssl_name = $words[2];
		print LOGFILE "$line";
sslLoop: while ( $line = <config> ) {
			$line =~ s/^\s+//;
			@words = split(" ",$line);
			if (  $line eq "\r"  or $line =~ m/^!/i or $line eq "" ) { last sslLoop ; }
			if ( $words[0] eq "ssl-proxy" and $words[1] eq "service") { seek("config", -(length($line)+1), 1);last ;}
			if ( $words[0] eq "key" ) { push ( @{$ssl_service{ $ssl_name }},$words[1]); next;}
			if ( $words[0] eq "cert" ) { push ( @{$ssl_service{ $ssl_name }},$words[1]); next;}
			else { print LOGFILE "!$line";}
		}
	}
	
####### Class-Map Virtual Server Extraction and should have only one Virtual Server per Class-map ###### 
	if ( $words[0] eq "class-map" and $words[1] eq ("match-all" or "match-any") ) {
		my $vsname= $words[2];
		my $vserver = new vserver( "$vsname");
		print LOGFILE "$line";
		#print "$line";
		while ($line = <config>) {
			$line =~ s/^\s+//;
			#print "$line";
			@words = split (" ",$line);
			if (  $line eq "\r"  or $line =~ m/^!/i or $line eq "" ) { last; }
			if ( $words[0] eq "class-map" and $words[1] eq ("match-all" or "match-any") ) { seek("config", -(length($line)+1), 1);  last ;}
			if ( $words[0] eq "class-map" and $words[1] eq "type" ) { print LOGFILE "!$line";seek("config", -(length($line)+1), 1);  last ;}
			if ( $words[1] eq "match" and $words[2] eq "virtual-address" ) {
				my $tip = $words[3];
				$vserver->setTip("$tip");
				$vserver->setEnable("no");
				if ( $words[4] eq "tcp" and $words[5] eq "eq" ) {
					my $vport = $words[6];
					given ($vport) {
						when("http") { $vserver->setVport("80"); $vserver->setVprotocol("http"); next;}
						when("www") { $vserver->setVport("80"); $vserver->setVprotocol("http"); next;}
						when("https") { $vserver->setVport("443"); $vserver->setVprotocol("http");next;}
						when("smtp") { $vserver->setVport("25"); $vserver->setVprotocol("smtp");next;}
						when("pop3") { $vserver->setVport("110"); $vserver->setVprotocol("pop3");next;}
						when("ftp") { $vserver->setVport("21");$vserver->setVprotocol("ftp");next;}
						when(/\d{1,5}/) { $vserver->setVport("$vport");$vserver->setVprotocol("http");next;}
						default { print LOGFILE "!$line"; next;}
					}
				}
				if ( $words[4] eq "any" ){
					print "Configuring $vsname for HTTP protocol and PORT 80!! Check configuration if this is not the case\n";
					$vserver->setVport("80");
					$vserver->setVprotocol("http");next;
				}
				
				if ( $words[4] eq "udp" and $words[5] eq "eq" ) {
					my $vport = $words[6];
					given ($vport) {
						when("domain") { $vserver->setVport("53"); $vserver->setVprotocol("dns");next }
						when("sip") { $vserver->setVport("5060"); $vserver->setVprotocol("sip");next}
						default { print LOGFILE "!$line"; next;}
					}
				}
			last;
			}
		}
		$allvirtual{$vserver->getName()} = $vserver;
	}
####### Load Balancing Policy Match Extraction ##########
	if ( $line =~ m/policy-map type\sloadbalance\s(http)?\s?first-match\s(.*?)$/){
		$pol_lb_name = $2;
		print LOGFILE "$line";
lbLoop:	while ($line = <config> ) {
			$line =~ s/^\s+//;
			#chomp $line;
			#my $flag = "on";
			@words = split(" ",$line);
			if (  $line eq "\r"  or $line =~ m/^!/i or $line eq "" ) {last lbLoop;} 
			if ( $line =~ m/policy-map type\s(.*?)$/) { seek("config", -(length($line)+1), 1);last lbLoop;}
			if ($words[0] eq "class" and $words[1] eq "class-default") {  $flag = "off"; next;}
			if ($words[0] eq "sticky-serverfarm" and $flag eq "off") { $pol_slb_to_serverfarm{$pol_lb_name} = $allsticky{$words[1]};next;}
			if ($words[0] eq "serverfarm" and $flag eq "off") {	$pol_slb_to_serverfarm{$pol_lb_name} = $words[1]; next;}
			else { print LOGFILE "!$line";}
			}
	}
	if ( $line =~ m/policy-map type\sloadbalance\sgeneric\sfirst-match\s(.*?)$/){
		print LOGFILE "!$line"; print "Policy-Map Generic found !!!Stingray needs to be manually configured with Traffic Script\n";
	}
####### Policy Multi Match Extraction ##########	
	if ( $line =~ m/policy-map multi-match\s(.*?)$/){
	my $pol_mm_name = $1;
	print LOGFILE "$line";
mmLoop:	while ($line = <config> ) {
			$line =~ s/^\s+//;
			@words = split(" ",$line);
			if (  $line eq "\r"  or $line =~ m/^!/i or $line eq "" ) {last mmLoop;} 
			if ($words[0] eq "class") { 
				print LOGFILE "$line";
				push ( @ {$pol_mm_class_vip{ $pol_mm_name}} ,"$words[1]"); $class_vip = $words[1];
				while($line = <config> ) {
					$line =~ s/^\s+//;
					@words = split(" ",$line);
					if (  $line eq "\r"  or $line =~ m/^!/i or $line eq "" ) {last;}
					if ( $words[0] eq "class" ) { seek("config", -(length($line)+1), 1);last ;}
					if ($words[0] eq "loadbalance" and $words[1] eq "policy") { $classvip_to_pol_slb{$class_vip} = $words[2]; next;}
					if ($words[0] eq "loadbalance" and $words[1] eq "vip" and $words[2] eq "inservice") {
						$name = $allvirtual{$class_vip}->getName();
						$allvirtual{$class_vip}->setEnable("yes"); next;
					}
					if ($words[0] eq "ssl-proxy" and $words[1] eq "server") { $classvip_ssl{$class_vip} = $words[2]; next;}
					else { print LOGFILE "!$line";}
				}
			}
		}
	}
	
}
foreach $mm (keys %pol_mm_class_vip) {
	my @vips = @ {$pol_mm_class_vip{$mm}};
	foreach $vip (@vips) {
	    $name = $allvirtual{$vip}->getName();
		$pol_slb = $classvip_to_pol_slb{ $name };
		#$allvirtual{$vip}->setEnable("yes");
		$sf = $pol_slb_to_serverfarm{$pol_slb};
		$ssl = $classvip_ssl {$name};
		($key ,$cert) = @ { $ssl_service{ $ssl }};
		foreach $i ( @pools) {
			if ($i eq $sf ) {
				$allvirtual{$name}->setPool($sf);
			}
		}
		$allvirtual{$name}->setSTMname($stmname);
		$allvirtual{$name}->setSSLname($ssl);
		$allvirtual{$name}->setCert($cert);
		$allvirtual{$name}->setKey($key);
		$allvirtual{$name}->setVport("80");
	}
}
#####Create all necessary files and directories for Stingray Configuration ########
mkdir "conf", 0777 unless -d "conf"; 
mkdir "conf/pools", 0777 unless -d "conf/pools";
mkdir "conf/vservers", 0777 unless -d "conf/vservers";
mkdir "conf/monitors",0777 unless -d "conf/monitors";
mkdir "conf/persistence",0777 unless -d "conf/persistence";
mkdir "conf/flipper",0777 unless -d "conf/flipper";
mkdir "conf/ssl",0777 unless -d "conf/ssl";
mkdir "conf/ssl/server_keys",0777 unless -d "conf/ssl/server_keys";

my $atime = $mtime = time;
my $version = "conf/VERSION_9.0r2";
#open(VERSION_9,'>',$version) or die "Cannot read file conf/VERSION_9.0";
open(TIMESTAMP,">conf/TIMESTAMP") or die "Cannot read file conf/TIMESTAMP.";
open(PARTIAL,">conf/PARTIAL") or die "Cannot read file conf/PARTIAL.";
#open(TIMESTAMP,">conf/VERSION_9.0r2") or die "Cannot read file conf/VERSION_9.0r2.";
system ("touch conf/VERSION_9.0r2");
#utime $atime, $mtime, VERSION_9;
utime $atime, $mtime, TIMESTAMP;
utime $atime, $mtime, PARTIAL;
close PARTIAL;
close TIMESTAMP;
#############Create Stingray Pool and Monitor Configuration files ##########
foreach $poolName ( sort keys %allPools ) {
   	my $name = $allPools{$poolName}->getName(); #print LOGFILE "*** $name\n";
	my $probe = $allPools{$poolName}->getMonitor();
	#print LOGFILE "***Pname: $name --- Probe: $probe\n";
	$allPools{$poolName}->setPoolConfig($name);
	if ($probe ne "") { $allProbes{$probe}->setMonitorConfig(); }
}
############Create Stingray Virtual Server and Traffic IP Configuration files ###########
foreach $mm (keys %pol_mm_class_vip) {
	my @vips = @ {$pol_mm_class_vip{$mm}};
	foreach $vip (@vips) {
		my $name = $allvirtual{$vip}->getName();
		#print "name:$name\n";
		$allvirtual{$vip}->setConfig($name);
	}
}
############Create SSL ZCLI files########
if ( -e 'sslzcli.txt') {
	$file = 'sslzcli.txt';
	open(ZCLI,">zcli_for_ssl") or die "Cannot read file zcli_for_ssl";
	open(SSLZCLI , $file);
	print ZCLI "zcli <<EOF\n";
	foreach $line (<SSLZCLI>) {
		chomp ($line);
		print ZCLI "Catalog.SSL.Certificates.importCertificate $line {private_key:<(\"$line.private\"), public_cert:<(\"$line.public\") }\n";
	}
print ZCLI "EOF\n";
close ZCLI;
close SSLZCLI;
unlink 'sslzcli.txt';
}
############Tar the directory ##########
if ( -d "conf") {
	$fol = "conf";	
	my $tar = Archive::Tar->new();
	my @inventory = ();
	find (sub { push @inventory, $File::Find::name }, $fol);
	$tar->add_files( @inventory );
	$tar->write( "$fol.tar" );
	rmtree("$fol");
	
}
if (-d "STM_SSL") {
$fol = "STM_SSL";	
	my $tar = Archive::Tar->new();
	my @inventory = ();
	find (sub { push @inventory, $File::Find::name }, $fol);
	$tar->add_files( @inventory );
	$tar->write( "$fol.tar" );
	rmtree("$fol");
}
                                                                                             
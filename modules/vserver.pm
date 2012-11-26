#!/usr/bin/perl 

package vserver;
use File::Copy qw(copy);
sub new
{
    my $class = shift;
    my $self = { _vserverName => shift };
    bless $self, $class;
    return $self;
}
sub getName {
	my ($self) = @_;
	return $self->{_vserverName};
}
sub setSTMname {
	my ($self, $stmname) = @_;
	$self->{_STMNAME} = $stmname;
}
sub getSTMname {
	my ($self) = @_;
	return $self->{_STMNAME};
}
sub setEnable {
	my ($self,$enable) = @_;
	$self->{_ENABLE} = $enable;
}
sub setTip {
	my ($self,$TIP) = @_;
	$self->{_TIP} = $TIP;
}
sub setVport {
	my ($self,$port) = @_;
	$self->{_PORT} = $port;
}
sub setVprotocol {
	my ($self, $protocol) = @_;
	$self->{_PROTOCOL} = $protocol;
}
sub setPool {
	my($self, $pool) = @_;
	$self->{_POOL} = $pool;
	}
sub setSSLname {
	my ($self, $name) = @_;
	$self->{_SSLNAME} = $name;
}
sub setCert {
	my($self, $cert) = @_;
	$self->{_CERT} = $cert;
}
sub setKey {
	my($self, $key) = @_;
	$self->{_KEY} = $key;
}
sub getVport {
	my ($self) = @_;
	return $self->{_PORT};
}
sub getVprotocol {
	my ($self) = @_;
	return $self->{_PROTOCOL};
}
sub getPool {
	my($self) = @_;
	return $self->{_POOL};
}
sub getSSLname {
	my ($self) = @_;
	return $self->{_SSLNAME};
}
sub getCert {
	my($self) = @_;
	return $self->{_CERT};
}
sub getKey {
	my($self) = @_;
	return $self->{_KEY};
}
sub getEnable {
	my ($self) = @_;
	$self->{_ENABLE};
}
sub getTip {
	my ($self) = @_;
	return $self->{_TIP};
}
sub setConfig {
	my ($self,$vsName) = @_;
	   	my $vport = $self->getVport();
		my $vprotocol = $self->getVprotocol();
		my $pool = $self->getPool();
		my $cert = $self->getCert();
		my $key = $self->getKey();
		my $enable = $self->getEnable();
		my $tip = $self->getTip();
		my $sslname = $self->getSSLname();
		my $vname = $self->getName();
		my $stmname = $self->getSTMname();
		my $ace_ssl_dir = "ace_ssl";
		mkdir "conf/vservers", 0777 unless -d "conf/vservers";
		mkdir "conf/flipper",0777 unless -d "conf/flipper";
		open(VSFILE,">conf/vservers/$vsName") or die "Cannot read file conf/vservers/$vsName.";
		open(TIPFILE,">conf/flipper/$tip") or die "Cannot read file conf/flipper/$tip.";
		print TIPFILE "ipaddresses		$tip\n";
		print TIPFILE "machines		$stmname\n";
		print TIPFILE "mode		singlehosted\n";
		print VSFILE "address	!$tip\n";
		if ($enable eq "yes") { print VSFILE "enabled	Yes\n"; }
		print VSFILE "pool	$pool\n";
		print VSFILE "port	$vport\n";
		print VSFILE "protocol	$vprotocol\n" if ($vprotocol ne "http" );
		if ($cert ne "" and $key ne "") {
			mkdir "conf/ssl",0777 unless -d "conf/ssl";
			mkdir "conf/ssl/server_keys",0777 unless -d "conf/ssl/server_keys";
			open(SSLCONF,">>conf/ssl/servers_keys_config") or die "Cannot read file conf/ssl/servers_keys_config.";
			#open(SSLZCLI,">>sslzcli.txt") or die "Cannot read file sslzcli.txt.";
			print VSFILE "private_key	$sslname.private\n";
			print VSFILE "public_cert	$sslname.public\n";
			print VSFILE "ssl_decrypt	Yes\n";
			#print SSLZCLI "$name\n";
			#mkdir "STM_SSL", 0777 unless -d "STM_SSL";
			if ( -e "$ace_ssl_dir/$cert") {
				copy("$ace_ssl_dir/$cert","conf/ssl/server_keys/$sslname.public");
				#copy("$ace_ssl_dir/$cert","STM_SSL/$sslname.public");
				print SSLCONF "$sslname!public\t%zeushome%/zxtm/conf/ssl/server_keys/$sslname.public\n";
				
			} else { print "ACE SSL Cert:$cert not found in directory $ace_ssl_dir\n"; }
			if ( -e "$ace_ssl_dir/$key") { 
				copy("$ace_ssl_dir/$key","conf/ssl/server_keys/$sslname.private");
				#copy("$ace_ssl_dir/$key","STM_SSL/$sslname.private");
				print SSLCONF "$sslname!private\t%zeushome%/zxtm/conf/ssl/server_keys/$sslname.private\n";
				
			} else { print "ACE SSL Key:$key not found in directory $ace_ssl_dir\n";}
			print SSLCONF "$sslname!managed\tyes\n";
			print SSLCONF "$sslname!note\n";
		close SSLCONF;	
		}
		close VSFILE;
		close TIPFILE;
}
1;

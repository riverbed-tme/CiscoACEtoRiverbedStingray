#!/usr/bin/perl 

package vserver;
use File::Touch;
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
	   open(VSFILE,">conf/vservers/$vsName") or die "Cannot read file conf/vservers/$vsName.";
	   open(TIPFILE,">conf/flipper/$vsName") or die "Cannot read file conf/flipper/$vsName.";
	   	my $vport = $self->getVport();
		my $vprotocol = $self->getVprotocol();
		my $pool = $self->getPool();
		my $cert = $self->getCert();
		my $key = $self->getKey();
		my $enable = $self->getEnable();
		my $tip = $self->getTip();
		my $name = $self->getSSLname();
		my $vname = $self->getName();
		my $stmname = $self->getSTMname();
		print TIPFILE "ipaddresses		$tip\n";
		print TIPFILE "machines		$stmname\n";
		print TIPFILE "mode		singlehosted\n";
		print VSFILE "address	!$vname\n";
		if ($enable eq "yes") { print VSFILE "enabled	Yes\n"; }
		print VSFILE "pool	$pool\n";
		print VSFILE "port	$vport\n";
		print VSFILE "protocol	$vprotocol\n" if ($vprotocol ne "http" );
		if ($cert ne "" and $key ne "") {
			open(SSLFILE,">>sslfiles_to_rename.txt") or die "Cannot read file sslfiles_to_rename.txt.";
			open(SSLZCLI,">>sslzcli.txt") or die "Cannot read file sslzcli.txt.";
			print VSFILE "private_key	$name.private\n";
			print VSFILE "public_cert	$name.public\n";
			print VSFILE "ssl_decrypt	Yes\n";
			print SSLFILE "$key -> $name.private , $cert -> $name.public\n";
			print SSLZCLI "$name\n";
			touch("conf/ssl/server_keys/$name.private");
			touch("conf/ssl/server_keys/$name.pubilc");
			#print SSLZCLI "zcli <<EOF\nCatalog.SSL.Certificates.importCertificate $name {private_key:<(\"$name.private\"), public_cert:<(\"$name.public\") }\nEOF\n";
		}
		close SSLFILE;
		close SSLZCLI;
		close VSFILE;
		close TIPFILE;
		
}
1;

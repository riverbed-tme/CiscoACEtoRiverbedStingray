#!/usr/bin/perl 
use feature qw(say switch);
package monitor;
sub new
{
    my $class = shift;
    my $self = { _monitorName => shift };
    bless $self, $class;
    return $self;
}
sub getName {
	my ($self) = @_;
	return $self->{_monitorName};
}
sub setType {
	my ( $self, $type) = @_;
	$self->{__TYPE} = $type;
}
sub setPath {
	my ( $self, $path) = @_;
	$self->{__PATH} = $path;
}
sub setHeader {
	my ( $self, $header) = @_;
	$self->{__HEADER} = $header;
}
sub setStatus {
	my ( $self, $status) = @_;
	$self->{__STATUS} = $status;
}
sub setBody {
	my ( $self, $body) = @_;
	$self->{__BODY} = $body;
}
sub setFailure {
	my ( $self, $failure) = @_;
	$self->{__FAILURE} = $failure;
}
sub setDelay {
	my ( $self, $delay) = @_;
	$self->{__DELAY} = $delay;
}
sub getType {
	my ( $self) = @_;
	return $self->{__TYPE};
}
sub getPath {
	my ( $self) = @_;
	$self->{__PATH};
}
sub getHeader {
	my ( $self) = @_;
	$self->{__HEADER};
}
sub getStatus {
	my ( $self) = @_;
	$self->{__STATUS};
}
sub getBody {
	my ( $self) = @_;
	$self->{__BODY} ;
}
sub getFailure {
	my ( $self) = @_;
	$self->{__FAILURE} ;
}
sub getDelay {
	my ( $self) = @_;
	$self->{__DELAY};
}
sub setMonitorConfig {
	my ($self) = @_;
	$monName = $self->getName();
	open(MONFILE,">conf/monitors/$monName") or die "Cannot read file conf/pools/$monName.";
	my $type = $self->getType();
	my $status = $self->getStatus();
	my $failure = $self->getFailure();
	my $delay = $self->getDelay();
	given ($type) {
		when("http") { 
			my $path = $self->getPath();
			if ($path eq "") { $path = "/" ;}
			if ($delay ne "3" ) { print MONFILE "delay		$delay\n";}
			if ($failure ne "3") { print MONFILE "failures		$failure\n";}
			if(($header=$self->getHeader()) ne "") { print MONFILE "host_header		$header\n"; }
			print MONFILE "path		$path\n";
			print MONFILE "type		$type\n";
		}
		when("https") { 
			my $path = $self->getPath();
			if ($path eq "") { $path = "/" ;}
			if ($delay ne "5" ) { print MONFILE "delay		$delay\n";}
			if ($failure ne "3") { print MONFILE "failures		$failure\n";}
			if(($header=$self->getHeader()) ne "") { print MONFILE "host_header		$header\n"; }
			print MONFILE "path		$path\n";
			print MONFILE "type		$type\n";
			print MONFILE "use_ssl	Yes\n";
		}
	}
	close MONFILE;
}

1;
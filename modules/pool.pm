#!/usr/bin/perl 
package pool;
sub new
{
    my $class = shift;
    my $self = { _poolName => shift };
    bless $self, $class;
    return $self;
}
sub getName {
	my ($self) = @_;
	return $self->{_poolName};
}
sub setNote {
	my ($self, $note) = @_;
	$self->{_NOTE} = $note;
}
sub getNote {
	my ($self) = @_;
	return $self->{_NOTE};
}
sub addNode {
	my( $self,$newNode ) = @_;
	push ( @ {$self->{_poolNodes}}, $newNode);
}
sub setState {
	my ( $self, $state) = @_;
	if( $state eq "active") {
		push ( @ {$self->{_STATE}},$state);
	}
}
sub setWeight {
	my ( $self, $weight) = @_;
	push ( @ {$self->{_WEIGHT}},$wright);
}
sub getNodes {
	my( $self ) = @_;
	return @ {$self->{_poolNodes}};
}
sub getState {
	my ( $self) = @_;
	return @ {$self->{_STATE}};
}
sub getWeight {
	my ( $self) = @_;
	return  @ {$self->{_WEIGHT}};
}
sub setLB {
	my ( $self, $lb_method) = @_;
	$self->{_poolLB} = $lb_method;
}
sub setPersist {
	my ( $self, $persistname) = @_;
	$self->{_PERSISTNAME} = $persistname;
}
sub setPersistType {
	my ( $self, $persisttype) = @_;
	$self->{_PERSISTTYPE} = $persisttype;
}
sub setPersistCookie {
	my ( $self, $cookie ) = @_;
	$self->{_COOKIE} = $cookie;
}
	
sub getLB {
	my ( $self) = @_;
	return $self->{_poolLB};
}
sub setMonitor {
	my ( $self, $monitor) = @_;
	$self->{_poolMonitor} = $monitor;
}
sub getMonitor {
	my ( $self) = @_;
	return $self->{_poolMonitor} ;
}
sub getPersist {
	my ( $self) = @_;
	return $self->{_PERSISTNAME};
}
sub getPersistType {
	my ( $self) = @_;
	return $self->{_PERSISTTYPE} ;
}
sub getPersistCookie {
	my ( $self ) = @_;
	return $self->{_COOKIE};
}
sub setPoolConfig {
	my ($self,$poolName) = @_;
		mkdir "conf/pools", 0777 unless -d "conf/pools";
		open(POOLFILE,">conf/pools/$poolName") or die "Cannot read file conf/pools/$poolName.";
		my @nodes = $self->getNodes();
		my @state = $self->getState();
		my $monitor = $self->getMonitor();
		my $algorithm = $self->getLB(); 
		my $note = $self->getNote();
		chomp $algorithm;
		$count = @nodes;
		if ( $algorithm ne "" ) { print POOLFILE "load_balancing!algorithm		$algorithm\n"; }
		if ( $monitor ne "" ) { print POOLFILE "monitors	$monitor\n"; }
		foreach $i ( @nodes ) {
			print POOLFILE "load_balancing!weighting!$i		1\n";
		}
		print POOLFILE "nodes	";
		print POOLFILE "@nodes\n";
		print POOLFILE "note	$note\n";
		my $persist = $self->getPersist();
		if ( $persist ne "" ) { 
			$persisttype = $self->getPersistType();
			$cookie = $self->getPersistCookie();
			print POOLFILE "persistence		$persist\n";
			mkdir "conf/persistence",0777 unless -d "conf/persistence";
			open (PERSISTFILE, ">conf/persistence/$persist") or die "Cannot read file conf/persistence/$persist.";
			if ($persisttype eq "ip") { print PERSISTFILE "type		$persisttype\n";}
			else { print PERSISTFILE "cookie	$cookie\ntype	$persisttype\n"; }
			close PERSISTFILE;
		}
		
		close POOLFILE;
}
	
1;
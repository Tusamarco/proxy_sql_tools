#!/usr/bin/perl
use strict;
use DBI;
use Time::HiRes qw(gettimeofday);

# This tool is "fat-packed": most of its dependent modules are embedded
# in this file.  

use Getopt::Long;
$Getopt::Long::ignorecase = 0;


my $Param = {};
my $user = "admin";
my $pass = "admin";
my $help = '';
my $host = '' ;
my $outfile;
my $strMySQLVersion="";

my $CurrentTime;
my $CurrentDate;
my $baseSP;
my $debug = 0 ;
my %hostgroups;

my %processState;
my %processCommand;
my @HGIds;


######################################################################
#Local functions
######################################################################

sub URLDecode {
    my $theURL = $_[0];
    $theURL =~ tr/+/ /;
    $theURL =~ s/%([a-fA-F0-9]{2,2})/chr(hex($1))/eg;
    $theURL =~ s/<!--(.|\n)*-->//g;
    return $theURL;
}
sub URLEncode {
    my $theURL = $_[0];
   $theURL =~ s/([\W])/"%" . uc(sprintf("%2.2x",ord($1)))/eg;
   return $theURL;
}

# return a proxy object
sub get_proxy($$$){
    my $dns = shift;
    my $user = shift;
    my $pass = shift;
    my $proxynode = ProxySqlNode->new();
    $proxynode->dns($dns);
    $proxynode->user($user);
    $proxynode->password($pass);
    
    return $proxynode;
    
}

######################################################################
## get_cluster return a cluster object poulate with the whole info including the 
## $dbh -- a non-null database handle, as returned from get_connection()
##
sub get_cluster($$) {
  my $dbh = shift;
  my $debug = shift;
  
  my $cluster=Galeracluster->new();
  @HGIds=split('\,', $Param->{hostgroups});
  $cluster->get_nodes($dbh,$debug);
  return \$cluster;
}




# ============================================================================
#+++++ INITIALIZATION
# ============================================================================

$Param->{user}       = '';
$Param->{password}   = '';
$Param->{host}       = '';
$Param->{port}       = 3306;
$Param->{debug}      = 0; 
$Param->{processlist} = 0;
$Param->{OS} = $^O;


if (
    !GetOptions(
        'user|u:s'       => \$Param->{user},
        'password|p:s'   => \$Param->{password},
        'host|h:s'       => \$host,
        'port|P:i'       => \$Param->{port},
        'debug|d:i'      => \$Param->{debug},
        'hostgroups|H:s'=> \$Param->{hostgroups},
        'help:s'       => \$Param->{help}

    )
  )
{
    ShowOptions();
    exit(0);
}
else{
     $Param->{host} = URLDecode($host);
     if(defined $outfile){
          $Param->{outfile} = URLDecode($outfile);
     }
}

if ( defined $Param->{help}) {
    ShowOptions();
    exit(0);
}

die "Option --hostgroups not specified.\n" unless defined($Param->{hostgroups});
die "Option --host not specified.\n" unless exists $Param->{host};
die "Option --user not specified.\n" unless exists $Param->{user};
die "Option --port not specified.\n" unless exists $Param->{port};



if($Param->{debug}){
    Utils::debugEnv();
}

# $dsn = "DBI:mysql:database=mysql;mysql_socket=/tmp/mysql.sock";
# my $dbh = DBI->connect($dsn, 'pythian','22yr106xhsy96f4');

my $dsn  = "DBI:mysql:host=$Param->{host};port=$Param->{port}";
if(defined $Param->{user}){
	$user = "$Param->{user}";
}
if(defined $Param->{password}){
	$pass = "$Param->{password}";
}


#============================================================================
# Execution
#============================================================================

my $proxy_sql_node = get_proxy($dsn, $user, $pass);
$proxy_sql_node->hostgroups($Param->{hostgroups}) ;

$proxy_sql_node->connect();

# create basic galera cluster object and fill info
my $galera_cluster = $proxy_sql_node->get_galera_cluster();

if( defined $galera_cluster){
    $galera_cluster->get_nodes();
}

if(defined $galera_cluster->nodes){
    $galera_cluster->process_nodes();
    
}


#my $dbh = get_connection($dsn, $user, $pass,' ');

#my $variables = get_variables($dbh,$debug);
#my $cluster = get_cluster($dbh,$debug);

exit(0);






{
    package Galeracluster;
    use threads;
    use threads::shared;
    use strict;
    use warnings;
    use Time::HiRes qw(gettimeofday usleep);
    
    sub new {
        my $class = shift;
        my $SQL_get_mysql_servers="SELECT * FROM mysql_servers WHERE status not in ('OFFLINE_HARD','SHUNNED')";
        
        
        # Variable section for  looping values
        #Generalize object for now I have conceptualize as:
        # Cluster (generic container)
        # Cluster->{name}     This is the cluster name
        # Cluster->{nodes}       the nodes in the cluster Map by node name
        # Cluster->{status}     cluster status [Primary|not Primary]
        # Cluster->{size}     cluster status [Primary|not Primary]
        # Cluster->{singlenode}=0;  0 if false 1 if true meaning only one ACTIVE node in the cluster 
        # Cluster->{haswriter}=0;  0 if false 1 if true at least a node is fully active as writer
        
        
        my $self = {
            _name      => undef,
            _hosts  => {},
            _status    => undef,
            _size  => 0,
            _singlenode  => 0,
            _haswriter => 0,
            _SQL_get_mysql_servers => $SQL_get_mysql_servers,
            _hostgroups => undef,
            _dbh_proxy => undef,
            _debug => undef,
            _monitor_user => undef,
            _monitor_password => undef,
            _nodes => {},
            _check_timeout => 100, #timeout in ms
            #_hg => undef,
        };
        bless $self, $class;
        return $self;
        
    }

    sub check_timeout{
        my ( $self, $check_timeout ) = @_;
        $self->{_check_timeout} = $check_timeout if defined($check_timeout);
        return $self->{_check_timeout};
    }

    sub debug{
        my ( $self, $debug ) = @_;
        $self->{_debug} = $debug if defined($debug);
        return $self->{_debug};
    }

    
    sub dbh_proxy{
        my ( $self, $dbh_proxy ) = @_;
        $self->{_dbh_proxy} = $dbh_proxy if defined($dbh_proxy);
        return $self->{_dbh_proxy};
    }
    
    sub name {
        my ( $self, $name ) = @_;
        $self->{_name} = $name if defined($name);
        return $self->{_name};
    }

    sub nodes {
        my ( $self, $nodes ) = @_;
        $self->{_nodes} = $nodes if defined($nodes);
        return $self->{_nodes};
    }
    sub status {
        my ( $self, $status ) = @_;
        $self->{_status} = $status if defined($status);
        return $self->{_status};
    }

    sub size {
        my ( $self, $size ) = @_;
        $self->{_size} = $size if defined($size);
        return $size->{_size};
    }

    sub singlenode {
        my ( $self, $singlenode ) = @_;
        $self->{_singlenode} = $singlenode if defined($singlenode);
        return $self->{_singlenode};
    }

    sub haswriter {
        my ( $self, $haswriter ) = @_;
        $self->{_haswriter} = $haswriter if defined($haswriter);
        return $self->{_haswriter};
    }
    
    sub hostgroups {
        my ( $self, $hostgroups ) = @_;
        $self->{_hostgroups} = $hostgroups if defined($hostgroups);
        return $self->{_hostgroups};
    }
        sub monitor_user{
        my ( $self, $monitor_user ) = @_;
        $self->{_monitor_user} = $monitor_user if defined($monitor_user);
        return $self->{_monitor_user};
    }
    sub monitor_password {
        my ( $self, $monitor_password ) = @_;
        $self->{_monitor_password} = $monitor_password if defined($monitor_password);
        return $self->{_monitor_password};
    }
    # this function is used to identify the nodes in the cluster
    # using the HG as reference
    sub get_nodes{
        my ( $self) = @_;
        
        my $dbh = $self->{_dbh_proxy};
        my $cmd =$self->{_SQL_get_mysql_servers}." AND hostgroup_id IN (".$self->hostgroups.") order by hostgroup_id, hostname";
        my $sth = $dbh->prepare($cmd);
        $sth->execute();
        my $i = 1;
        while (my $ref = $sth->fetchrow_hashref()) {
            my $node = GaleraNode->new();
            $node->dns("DBI:mysql:host=".$ref->{hostname}.";port=".$ref->{port});
            $node->hostgroups($ref->{hostgroup_id});
            $node->ip($ref->{hostname});
            $node->weight($ref->{weight});
            $node->user($self->{_monitor_user});
            $node->password($self->{_monitor_password});
            $node->proxy_status($ref->{status});
            $self->{_nodes}->{$i++}=$node;
        }
    }
    #Processing the nodes in the cluster and identify which node is active and which is to remove
    
    sub process_nodes{
        my ( $self) = @_;

        my $nodes = $self->{_nodes} ;
        my $start = gettimeofday();
        my $run_milliseconds=0;
        my $init =0;
        my $irun = 1;
        my %Threads;
        my $new_nodes ={} ;
        
        #using multiple threads to connect if a node is present in more than one HG it will have 2 threads
        while($irun){
            $irun = 0;
            foreach my $key (sort keys %{$self->{_nodes}}){
                if(!exists $Threads{$key} ){
                    $new_nodes->{$key} =  $self->{_nodes}->{$key};
                    $new_nodes->{$key}->{_process_status} = -1;
                    #  debug senza threads
                    $Threads{$key}=threads->create(sub  {return get_node_info($self,$key)});
                    #$new_nodes->{$key} = get_node_info($self,$key);
                }
            }
            #DEBUG SENZA THREADS coomenta da qui
            foreach my $thr (sort keys %Threads) {
                if ($Threads{$thr}->is_running()) {
                    my $tid = $Threads{$thr}->tid;
                    #print "  - Thread $tid running\n";
                   
                    if($run_milliseconds >  $self->{_check_timeout} ){
                       $irun = 0 ; 
                    }
		    else{
			$irun = 1;
		    }
                } 
                elsif ($Threads{$thr}->is_joinable()) {
                    my $tid = $Threads{$thr}->tid;
                    ( $new_nodes->{$thr} ) = $Threads{$thr}->join;
                    #print "  - Results for thread $tid:\n";
                    #print "  - Thread $tid has been joined\n";
                }
                print ".";
            }
	    # a qui
            $run_milliseconds = (gettimeofday() -$start ) *1000;
            #sleep for a time equal to the half of the timeout to save cpu cicle
            #usleep(($self->{_check_timeout} * 1000)/2);
        }
        $self->{_nodes} = $new_nodes;
        $run_milliseconds = (gettimeofday() -$start ) *1000;
	
	foreach my $key (sort keys $new_nodes){
	    if($new_nodes->{$key}->{_process_status} == 1){
		print $new_nodes->{$key}->{_ip}." Processed \n";
	    }
	    else{
		print $new_nodes->{$key}->{_ip}." NOT Processed\n";
	    }
	}
        print "done $run_milliseconds\n";
        
        
    }
    
    sub get_node_info($$){
        my $self = shift;
        my $key = shift;
        my $nodes =shift;
        my ( $node ) = $self->{_nodes}->{$key};
        $node->get_node_info();
        return $node;
        
    }

    #sub setValue{
    #    my ( $self, $TempValue) = @_;
    #    if(!defined $self->{_previous} && !defined  $self->{_current}){
    #        $self->{_previous} = $TempValue;
    #        $self->{_current} = $TempValue;
    #        
    #    }
    #    else{
    #        $self->{_previous} = $self->{_current};
    #        $self->{_current} = $TempValue;       
    #    }
    #    
    #    if( defined  $self->{_max}){
    #        if ($self->{_max} =~ /^\d+?$/  && $self->{_current} =~ /^\d+?$/) {
    #           $self->{_max} = ($self->{_current} > $self->{_max})?$self->{_current}:$self->{_max};
    #        }
    #    }
    #    else
    #    {
    #         $self->{_max} = $self->{_current};
    #    }
    #    
    #    if( defined  $self->{_min}){
    #        if ($self->{_min} =~ /^\d+?$/  && $self->{_current} =~ /^\d+?$/)  {
    #            $self->{_min} = ($self->{_current} < $self->{_min})?$self->{_current}:$self->{_min};
    #        }
    #    }
    #    else
    #    {
    #         $self->{_min} = $self->{_current};
    #    }
    #    
    #    if(defined $self->{_calculated} && $self->{_calculated} > 0 ){
    #        #DEBUG
    #        #if($self->{name} eq "innodb_IBmergedinsert"){
    #        #print $self->{name}."\n";
    #        #print $self->{_current}."\n";
    #        #print $self->{_previous}."\n";
    #        #my $aa =  ($self->{_current} - $self->{_previous});
    #        #print $aa."\n";
    #        #}
    #        if($self->{_current}  > 0){
    #            $self->{_relative} = ( $self->{_current} - $self->{_previous});
    #        }
    #        else{
    #            $self->{_relative} = $self->{_current};
    #        }
    #    }
    #    else
    #    {
    #        $self->{_relative} = ( $self->{_current});
    #        
    #    }
    #    
    #    return;
    #}

    
}



#status
#wsrep_connected   ON
#wsrep_desync_count  = 0
#wsrep_local_recv_queue
#wsrep_local_state = 4
#wsrep_ready = ON
#WSREP_CLUSTER_STATUS =Primary
#WSREP_CLUSTER_SIZE = 5
#
#variables:
#wsrep_cluster_name
#wsrep_desync
#wsrep_node_name
#wsrep_reject_queries=none
#wsrep_sst_donor_rejects_queries=off


{
    package GaleraNode;
        
    sub new {
        my $class = shift;
        my $SQL_get_variables="SHOW GLOBAL VARIABLES LIKE 'wsrep%";
        my $SQL_get_status="SHOW GLOBAL VARIABLES LIKE 'wsrep%";
        my $SQL_get_read_only="SHOW GLOBAL VARIABLES LIKE 'read_only'";  
        
        # Variable section for  looping values
        #Generalize object for now I have conceptualize as:
        # Node (generic container)
        # Node->{name}     This is the cluster name
        # Node->{IP}
        # Node->{hostgroups}
        # Node->{clustername} This is the cluster name
        # Node->{read_only} Read only node
        # Node->{wsrep_status}     node status (OPEN 0,Primary 1,Joiner 2,Joined 3,Synced 4,Donor 5)
        # Node->{wsrep_rejectqueries} (NON, ALL,ALL_KILL)
        # Node->{wsrep_donorrejectqueries} If true the node when donor 
        # Node->{wsrep_connected}=0;   if false 1 if true meaning only one ACTIVE node in the cluster 
        # Node->{wsrep_desinccount}=0;  0 if false 1 if true at least a node is fully active as writer
        # Node->{wsrep_ready}  ON -OFF 
        
        my $self = {
            _name      => undef,
            _ip  => undef,
            _hostgroups => undef,
            _clustername    => undef,
            _read_only    => undef,
            _wsrep_status  => -1,
            _wsrep_rejectqueries => undef,
            _wsrep_donorrejectqueries => undef,
            _wsrep_connected => undef,
            _wsrep_desinccount => undef,
            _wsrep_ready => undef,
            _wsrep_provider => [],
            _wsrep_segment => 0,
            _wsrep_pc_weight => 1,
            _SQL_get_variables => $SQL_get_variables,
            _SQL_get_status=> $SQL_get_status,
            _SQL_get_read_only=> $SQL_get_read_only,
            _dns  => undef,
            _user => undef,
            _password => undef,
            _port => undef,
            _proxy_status    => undef,
            _weight => 1,
            _cluster_status    => undef,
            _cluster_size  => 0,

            
        };
        bless $self, $class;
        return $self;
        
    }
    sub cluster_status {
        my ( $self, $status ) = @_;
        $self->{_cluster_status} = $status if defined($status);
        return $self->{_cluster_status};
    }

    sub cluster_size {
        my ( $self, $size ) = @_;
        $self->{_cluster_size} = $size if defined($size);
        return $size->{_cluster_size};
    }
    
    sub weight {
        my ( $self, $weight ) = @_;
        $self->{_weight} = $weight if defined($weight);
        return $self->{_weight};
    }
    
    sub proxy_status {
        my ( $self, $status ) = @_;
        $self->{_proxy_status} = $status if defined($status);
        return $self->{_proxy_status};
    }
    
    sub dns {
        my ( $self, $dns ) = @_;
        $self->{_dns} = $dns if defined($dns);
        return $self->{_dns};
    }
    
    sub user{
        my ( $self, $user ) = @_;
        $self->{_user} = $user if defined($user);
        return $self->{_user};
    }
    sub password {
        my ( $self, $password ) = @_;
        $self->{_password} = $password if defined($password);
        return $self->{_password};
    }
    sub name {
        my ( $self, $name ) = @_;
        $self->{_name} = $name if defined($name);
        return $self->{_name};
    }

    sub ip {
        my ( $self, $ip ) = @_;
        $self->{_ip} = $ip if defined($ip);
        return $self->{_ip};
    }

    sub hostgroups {
        my ( $self, $hostgroups ) = @_;
        $self->{_hostgroups} = $hostgroups if defined($hostgroups);
        return $self->{_hostgroups};
    }
    
    sub clustername {
        my ( $self, $clustername ) = @_;
        $self->{_clustername} = $clustername if defined($clustername);
        return $self->{_clustername};
    }

    sub read_only {
        my ( $self, $read_only ) = @_;
        $self->{_read_only} = $read_only if defined($read_only);
        return $self->{_read_only};
    }

    sub wsrep_status {
        my ( $self, $wsrep_status ) = @_;
        $self->{_wsrep_status} = $wsrep_status if defined($wsrep_status);
        return $self->{_wsrep_status};
    }

    sub wsrep_rejectqueries {
        my ( $self, $wsrep_rejectqueries ) = @_;
        $self->{_wsrep_rejectqueries} = $wsrep_rejectqueries if defined($wsrep_rejectqueries);
        return $self->{_wsrep_rejectqueries};
    }

    sub wsrep_donorrejectqueries {
        my ( $self, $wsrep_donorrejectqueries ) = @_;
        $self->{_wsrep_donorrejectqueries} = $wsrep_donorrejectqueries if defined($wsrep_donorrejectqueries);
        return $self->{_wsrep_donorrejectqueries};
    }

    sub wsrep_connected {
        my ( $self, $wsrep_connected ) = @_;
        $self->{_wsrep_connected} = $wsrep_connected if defined($wsrep_connected);
        return $self->{_wsrep_connected};
    }

    sub wsrep_desinccount {
        my ( $self, $wsrep_desinccount ) = @_;
        $self->{_wsrep_desinccount} = $wsrep_desinccount if defined($wsrep_desinccount);
        return $self->{_wsrep_desinccount};
    }


    sub wsrep_ready {
        my ( $self, $wsrep_ready ) = @_;
        $self->{_wsrep_ready} = $wsrep_ready if defined($wsrep_ready);
        return $self->{_wsrep_ready};
    }

    sub wsrep_segment {
        my ( $self, $wsrep_segment ) = @_;
        $self->{_wsrep_segment} = $wsrep_segment if defined($wsrep_segment);
        return $self->{_wsrep_segment};
    }

    sub wsrep_pc_weight {
        my ( $self, $wsrep_pc_weight ) = @_;
        $self->{_wsrep_pc_weight} = $wsrep_pc_weight if defined($wsrep_pc_weight);
        return $self->{_wsrep_pc_weight};
    }

    sub wsrep_provider {
        my ( $self, $wsrep_provider ) = @_;
        my @array = @{$wsrep_provider};
        my %provider_map ;
        foreach my $item (@array){
          my @items = split('\=', $item);
          $provider_map{Utils::trim($items[0])}=$items[1];
        }
        $self->{_wsrep_provider} = %provider_map;
        $self->wsrep_segment($provider_map{"gmcast.segment"});
        $self->wsrep_pc_weight($provider_map{"pc.weight"});
        return $self->{_wsrep_provider};
    }

    sub get_node_info($$){
        my ( $self ) = @_;
        #print $self->{_ip}."\n";
        my $dbh = Utils::get_connection($self->{_dns},$self->{_user},$self->{_password},' ');
        my $variables = Utils::get_variables($dbh,0);
        my $status = Utils::get_status_by_name($dbh,0,"wsrep_%");
        
        $self->{_name} = $variables->{wsrep_node_name};
        $self->{_clustername} = $variables->{wsrep_cluster_name};
        $self->{_read_only} = $variables->{read_only};
        $self->{_wsrep_rejectqueries} = $variables->{wsrep_reject_queries};
        $self->{_wsrep_donorrejectqueries} = $variables->{wsrep_sst_donor_rejects_queries};
        #my ( @provider ) =  split('\;', $variables->{wsrep_provider_options});
        $self->wsrep_provider([split('\;', $variables->{wsrep_provider_options})]);
        $self->{_wsrep_status} = $status->{wsrep_local_state};
        $self->{_wsrep_connected} = $status->{wsrep_connected};
        $self->{_wsrep_desinccount} = $status->{wsrep_desync_count};
        $self->{_wsrep_ready} = $status->{wsrep_ready};
        $self->{_cluster_status} = $status->{wsrep_cluster_status};
        $self->{_cluster_size} = $status->{wsrep_cluster_size};
        
        $dbh->disconnect if (!defined $dbh);
	#sleep 5;
        $self->{_process_status} = 1;
        return $self;
        
    }
    
}

{
    package ProxySqlNode;
    
    
    sub new {
        my $class = shift;

        my $SQL_get_monitor = "select variable_name name,variable_value value from global_variables where variable_name in( 'mysql-monitor_username','mysql-monitor_password','mysql-monitor_read_only_timeout' ) order by 1";
        my $SQL_get_hostgroups = "select distinct hostgroup_id hg_isd from mysql_servers order by 1;";
        my $SQL_get_rep_hg = "select writer_hostgroup,reader_hostgroup from mysql_replication_hostgroups order by 1;";

        # Variable section for  looping values
        #Generalize object for now I have conceptualize as:
        # Proxy (generic container)
        # Proxy->{DNS} conenction reference
        # Proxy->{PID} processes pid (angel and real)
        # Proxy->{hostgroups}
        # Proxy->{user} This is the user name
        # Proxy->{password} 
        # Proxy->{port}     node status (OPEN 0,Primary 1,Joiner 2,Joined 3,Synced 4,Donor 5)
        
        my $self = {
            _dns  => undef,
            _pid  => undef,
            _hostgroups => undef,
            _user => undef,
            _password => undef,
            _port => undef,
            _monitor_user => undef,
            _monitor_password => undef,
            _SQL_get_monitor => $SQL_get_monitor,
            _SQL_get_hg=> $SQL_get_hostgroups,
            _SQL_get_replication_hg=> $SQL_get_rep_hg,
            _dbh_proxy => undef,
            _check_timeout => 100, #timeout in ms
        };
        bless $self, $class;
        return $self;
        
    }
    
    sub dns {
        my ( $self, $dns ) = @_;
        $self->{_dns} = $dns if defined($dns);
        return $self->{_dns};
    }

    sub dbh_proxy{
        my ( $self, $dbh_proxy ) = @_;
        $self->{_dbh_proxy} = $dbh_proxy if defined($dbh_proxy);
        return $self->{_dbh_proxy};
    }

    sub pid {
        my ( $self, $pid ) = @_;
        $self->{_pid} = $pid if defined($pid);
        return $self->{_pid};
    }

    sub hostgroups {
        my ( $self, $hostgroups ) = @_;
        $self->{_hostgroups} = $hostgroups if defined($hostgroups);
        return $self->{_hostgroups};
    }
    
    sub user{
        my ( $self, $user ) = @_;
        $self->{_user} = $user if defined($user);
        return $self->{_user};
    }
    sub password {
        my ( $self, $password ) = @_;
        $self->{_password} = $password if defined($password);
        return $self->{_password};
    }
    
        sub monitor_user{
        my ( $self, $monitor_user ) = @_;
        $self->{_monitor_user} = $monitor_user if defined($monitor_user);
        return $self->{_monitor_user};
    }
    sub monitor_password {
        my ( $self, $monitor_password ) = @_;
        $self->{_monitor_password} = $monitor_password if defined($monitor_password);
        return $self->{_monitor_password};
    }

    sub port {
        my ( $self, $port ) = @_;
        $self->{_port} = $port if defined($port);
        return $self->{_port};
    }

    sub check_timeout{
        my ( $self, $check_timeout ) = @_;
        $self->{_check_timeout} = $check_timeout if defined($check_timeout);
        return $self->{_check_timeout};
    }
    
    #Connect method connect an populate the cluster returns the Galera cluster
    sub connect{
        my ( $self, $port ) = @_;
        my $dbh = Utils::get_connection($self->{_dns}, $self->{_user}, $self->{_password},' ');
        $self->{_dbh_proxy} = $dbh;
        
        # get monitor user/pw                
        my $cmd = $self->{_SQL_get_monitor};


        my $sth = $dbh->prepare($cmd);
        $sth->execute();
        while (my $ref = $sth->fetchrow_hashref()) {
            if($ref->{'name'} eq 'mysql-monitor_password' ){$self->{_monitor_password} = $ref->{'value'};}
            if($ref->{'name'} eq 'mysql-monitor_username' ) {$self->{_monitor_user} = $ref->{'value'};}
            if($ref->{'name'} eq 'mysql-monitor_read_only_timeout' ) {$self->{_check_timeout} = $ref->{'value'};}
            
        }
        
    }

    sub get_galera_cluster(){
        my ( $self, $port ) = @_;
        my $galera_cluster = Galeracluster->new();
        $galera_cluster->hostgroups($self->hostgroups);
        $galera_cluster->dbh_proxy($self->dbh_proxy);
        $galera_cluster->check_timeout($self->check_timeout);
        $galera_cluster->monitor_user($self->monitor_user);
        $galera_cluster->monitor_password($self->monitor_password);
        $galera_cluster->debug($debug);
        return $galera_cluster;
    }

}

#{
#    package ProxySqlHG;
#    
#    sub new {
#        my $class = shift;
#        # Variable section for  looping values
#        #Generalize object for now I have conceptualize as:
#        # HG (generic container)
#        # HG->{IDW}
#        # HG->{IDR} 
#        
#        my $self = {
#            _idw  => undef,
#            _idr  => undef,
#            _ipsr => undef,
#            _ipsw => undef,
#            
#        };
#        bless $self, $class;
#        return $self;
#        
#    }
#    
#    sub idw {
#        my ( $self, $idw ) = @_;
#        $self->{_idw} = $idw if defined($idw);
#        return $self->{_idw};
#    }
#
#    sub idr {
#        my ( $self, $idr ) = @_;
#        $self->{_idr} = $idr if defined($idr);
#        return $self->{_idr};
#    }
#
#    sub ipsr {
#        my ( $self, $ipsr ) = @_;
#        $self->{_ipsr} = $ipsr if defined($ipsr);
#        return $self->{_ipsr};
#    }
#    
#    sub ipsw{
#        my ( $self, $ipsw ) = @_;
#        $self->{_ipsw} = $ipsw if defined($ipsw);
#        return $self->{_ipsw};
#    }
# 
#
#}

{
    package Utils;
    #============================================================================
    ## get_connection -- return a valid database connection handle (or die)
    ## $dsn  -- a perl DSN, e.g. "DBI:mysql:host=ltsdbwm1;port=3311"
    ## $user -- a valid username, e.g. "check"
    ## $pass -- a matching password, e.g. "g33k!"
    
    sub get_connection($$$$) {
      my $dsn  = shift;
      my $user = shift;
      my $pass = shift;
      my $SPACER = shift;
      my $dbh = DBI->connect($dsn, $user, $pass);
    
      if (!defined($dbh)) {
        print "$SPACER&red Cannot connect to $dsn as $user\n";
        die();
      }
      
      return $dbh;
    }
    
    ######################################################################
    ## collection functions -- fetch datbases from the instance
    ## get_databases -- return a hash ref to SHOW DATABASES output
    ## $dbh -- a non-null database handle, as returned from get_connection()
    
    sub get_databases($) {
      my $dbh = shift;
      
      my @v;
      my $cmd = "show databases";
    
      my $sth = $dbh->prepare($cmd);
      $sth->execute();
      my $i = 0;
      while (my $ref = $sth->fetchrow_hashref()) {
        
        $v[$i] = $ref->{'Database'};
        $i++;
      }
    
        
      return \@v;
    }



    ######################################################################
    ## get_accounts -- return a hash ref to SHOW GLOBAL VARIABLES output
    ## $dbh -- a non-null database handle, as returned from get_connection()
    ##
    sub get_accounts($) {
      my $dbh = shift;
    
      my %v;
      my $cmd = "select user,host from mysql.user where user !='' order by 1,2;";
    
      my $sth = $dbh->prepare($cmd);
      $sth->execute();
      while (my $ref = $sth->fetchrow_hashref()) {
        my $index = index($ref->{'host'},":");
        my $n;
        my $host="";
        
        $n = $ref->{'user'};
        if ($index > 0){ 
            $n = $ref->{'user'};#."_".substr($ref->{'host'},0,$index);
            $n=~ s/[% .]/_/g; 
        }
        else
        {
            $n = $ref->{'user'};#."_".$ref->{'host'};
            $n=~ s/[% .]/_/g; 
         
        }
        $v{$n} = 0;
      }
      return \%v;
    }
    
    ######################################################################
    ## collection functions -- fetch status data from db
    ## get_status -- return a hash ref to SHOW GLOBAL STATUS output
    ## $dbh -- a non-null database handle, as returned from get_connection()
    ##
    
    sub get_status($$) {
      my $dbh = shift;
      my $debug = shift;
      my %v;
      my $cmd = "show /*!50000 global */ status";
    
      my $sth = $dbh->prepare($cmd);
      $sth->execute();
      while (my $ref = $sth->fetchrow_hashref()) {
        my $n = $ref->{'Variable_name'};
        $v{"\L$n\E"} = $ref->{'Value'};
        if ($debug>0){print "MySQL status = ".$n."\n";}
      }
    
      return \%v;
    }
    ######################################################################
    ## collection functions -- fetch status data from db
    ## get_status -- return a hash ref to SHOW GLOBAL STATUS output
    ## $dbh -- a non-null database handle, as returned from get_connection()
    ##
    
    sub get_status_by_name($$) {
      my $dbh = shift;
      my $debug = shift;
      my $name  = shift ; 
      my %v;
      my $cmd = "show /*!50000 global */ status like '$name'";
    
      my $sth = $dbh->prepare($cmd);
      $sth->execute();
      while (my $ref = $sth->fetchrow_hashref()) {
        my $n = $ref->{'Variable_name'};
        $v{"\L$n\E"} = $ref->{'Value'};
        if ($debug>0){print "MySQL status = ".$n."\n";}
      }
    
      return \%v;
    }
    ##
    ## get_variables -- return a hash ref to SHOW GLOBAL VARIABLES output
    ##
    ## $dbh -- a non-null database handle, as returned from get_connection()
    ##
    sub get_variables($$) {
      my $dbh = shift;
      my $debug = shift;
      my %v;
      my $cmd = "show variables";
    
      my $sth = $dbh->prepare($cmd);
      $sth->execute();
      while (my $ref = $sth->fetchrow_hashref()) {
        my $n = $ref->{'Variable_name'};
        $v{"\L$n\E"} = $ref->{'Value'};
      }
      
     
      return \%v;
    }
    ##
    ## get_variables -- return a hash ref to SHOW GLOBAL VARIABLES output
    ##
    ## $dbh -- a non-null database handle, as returned from get_connection()
    ##
    sub get_variablesByName($$) {
      my $dbh = shift;
      my $variableName = shift;
      #my $debug = shift;
      my %v;
      my $cmd = "show variables like '$variableName'";
    
      my $sth = $dbh->prepare($cmd);
      $sth->execute();
      while (my $ref = $sth->fetchrow_hashref()) {
        my $n = $ref->{'Variable_name'};
        $v{"\L$n\E"} = $ref->{'Value'};
      }
      
     
      return \%v;
    }
    
    ##
    ## get_slave_status -- return a hash ref to SHOW SLAVE STATUS output
    ##
    ## $dbh -- a non-null database handle, as returned from get_connection()
    ##
    sub get_slave_status($) {
      my $dbh = shift;
      
      my $cmd = "show slave status";
      my $sth = $dbh->prepare($cmd);
      $sth->execute();
      my $ref = $sth->fetchrow_hashref();
      if (!defined($ref)) {
        # not a slave
        return undef;
      }
      my %v = %$ref;
    
      return \%v;
    }
    
    ##
    ## get_processlist -- return a an array of hash refs
    ##                    containing SHOW FULL PROCESSLIST output
    ##
    ## $dbh -- a non-null database handle, as returned from get_connection()
    ##
    sub get_processlist($) {
      my $dbh = shift;
      
      my @v;
      my $count = 0;
      my $cmd = "show full processlist";
    
      my $sth = $dbh->prepare($cmd);
      $sth->execute();
      while (my $ref = $sth->fetchrow_hashref()) {
        my %line = map { defined($_)?$_:"(null)" } %$ref;
        $v[$count++] = \%line;
      }
    
      return \@v;
    }

    
    # ============================================================================
    # Subtract two big integers as accurately as possible with reasonable effort.
    # 
    # ============================================================================
    sub big_sub ($$) {
        
        my $left = shift;
        my $right = shift;
       # my $force = shift;
       
        if($left=~ m/.[ABCDF]/){
            $left = hex($left);
            return $left;
       }
    
        if($right=~ m/.[ABCDF]/){
            $right = hex($right);
            return $right;
       }
       
       if ( !defined $left  ) { $left = 0; }
       if ( !defined $right ) { $right = 0; }
       
       #return ()
        my $x = Math::BigInt->new($left);
        my $xint = $x->bsub($right);
        return $xint->{value}[0];
    }
    
    # ============================================================================
    # Returns a bigint from two ulint or a single hex number.  
    # ============================================================================
    sub make_bigint ($$) {
       my $hi = shift;
       my $lo = shift;
       if($hi=~ m/.[ABCDF]/){
            $hi = hex($hi);
            return $hi;
       }
       
       
       if (defined $lo ) {
          # Assume it is a hex string representation.
          my $x = Math::BigInt->new($hi);
          my $xint = $x->as_number;
          return $xint->{value}[0];
       }
       else {
          $hi = $hi ? $hi : '0'; # Handle empty-string or whatnot
          $lo = $lo ? $lo : '0';
          return big_add(big_multiply($hi, 4294967296), $lo);
       }
    }
    
    # ============================================================================
    # Multiply two big integers together as accurately as possible with reasonable
    # effort. 
    # ============================================================================
    sub big_multiply ($$$) {
       my $left = shift;
       my $right = shift;
       my $force = shift;
       
        if($left=~ m/.[ABCDF]/){
            $left = hex($left);
            return $left;
       }
    
        if($right=~ m/.[ABCDF]/){
            $right = hex($right);
            return $right;
       }
       
       
       my $x = Math::BigInt->new($left);
       my $bx = $x->bmul($right);
       return $bx->{value}[0];
      
     
    }
    # ============================================================================
    # Add two big integers together as accurately as possible with reasonable
    # effort.  
    # ============================================================================
    sub big_add ($$$) {
        my $left = shift;
        my $right = shift;
        my $force = shift;
        
         if($left=~ m/.[ABCDF]/){
            $left = hex($left);
            return $left;
       }
    
        if($right=~ m/.[ABCDF]/){
            $right = hex($right);
            return $right;
       }
        
       if ( !defined $left )
          {
             $left = 0;
        }
       if ( !defined $right) { $right = 0; }
      
        my $x = Math::BigInt->new($left);
        my $bx = $x->badd($right);
         return $bx->{value}[0];
     
       
     
    }
    
    
    # ============================================================================
    # Safely increments a value that might be null.
    # ============================================================================
    sub increment(\%$$) {
       my $hash = shift;
       my $key = shift;
       my $howmuch = shift;
        
       if ( defined $hash->{$key}) {
          if ($hash->{$key} > 0)
          {
            my $value = int($hash->{$key});
            $hash->{$key} = ($value + $howmuch);
          }
          else
          {
            $hash->{$key} = ($howmuch);
          }
       }
       else
       {
            $hash->{$key} = $howmuch;
    
       }
       return $hash;
    }
    
    # ============================================================================
    # Sum the content of the array assuming it is numeric 
    # ============================================================================
    sub array_sum(@){
        my @array = shift;
        my $acc = 0;
        foreach (@array){
          $acc += $_;
        }
        return $acc;
    }
    
    sub debugEnv{
        my $key = keys %ENV;
        foreach $key (sort(keys %ENV)) {
    
           print $key, '=', $ENV{$key}, "\n";
    
        }
    
    }
    
    sub  trim {
        my $s = shift;
        $s =~ s/^\s+|\s+$//g;
        return $s
    };
}

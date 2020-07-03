#!/usr/bin/perl
# This tool is "fat-packed": most of its dependent modules are embedded
# in this file.
#######################################
#
# ProxySQL galera check v1 
#
# Author Marco Tusa 
# Copyright (C) (2016 - 2020)
# 
#
#THIS PROGRAM IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
#WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
#MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#This program is free software; you can redistribute it and/or modify it under
#the terms of the GNU General Public License as published by the Free Software
#Foundation, version 2; OR the Perl Artistic License.  On UNIX and similar
#systems, you can issue `man perlgpl' or `man perlartistic' to read these
#licenses.
#
#You should have received a copy of the GNU General Public License along with
#this program; if not, write to the Free Software Foundation, Inc., 59 Temple
#Place, Suite 330, Boston, MA  02111-1307  USA.

#######################################

package galera_check ;
use Time::HiRes qw(gettimeofday);
use strict;
use DBI;
use Getopt::Long;
use Pod::Usage;


$Getopt::Long::ignorecase = 0;
my $Param = {};
my $user = "admin";
my $pass = "admin";
my $help = '';
my $host = '' ;
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
sub get_proxy($$$$){
    my $dns = shift;
    my $user = shift;
    my $pass = shift;
    my $debug = shift;
    my $proxynode = ProxySqlNode->new();
    $proxynode->dns($dns);
    $proxynode->user($user);
    $proxynode->password($pass);
    $proxynode->debug($debug);
    
    return $proxynode;
    
}

 sub main{
    # ============================================================================
    #+++++ INITIALIZATION
    # ============================================================================
    if($#ARGV < 0){
        pod2usage(-verbose => 2) ;
       	exit 1;
    }
    
    if($#ARGV < 3){
      #given a ProxySQL scheduler
      #limitation we will pass the whole set of params as one
      # and will split after
      @ARGV = split('\ ',$ARGV[0]);
    }
    
    $Param->{user}       = '';
    $Param->{log}       = undef ;
    $Param->{password}   = '';
    $Param->{host}       = '';
    $Param->{port}       = 3306;
    $Param->{debug}      = 0; 
    $Param->{processlist} = 0;
    $Param->{OS} = $^O;
    $Param->{main_segment} = 1;
    $Param->{retry_up} = 0;
    $Param->{retry_down} = 0;
    $Param->{print_execution} = 1;
    $Param->{development} = 0;
    $Param->{development_time} = 2;
    $Param->{active_failover} = 0;
    $Param->{single_writer} = 1;
    $Param->{writer_is_reader} = 1;
    $Param->{check_timeout} = 800;
    
    my $run_pid_dir = "/tmp" ;
    
    #if (
    GetOptions(
        'user|u:s'       => \$Param->{user},
        'password|p:s'   => \$Param->{password},
        'host|h:s'       => \$host,
        'port|P:i'       => \$Param->{port},
        'debug|d:i'      => \$Param->{debug},
        'log:s'      => \$Param->{log},
        'hostgroups|H:s'=> \$Param->{hostgroups},
        'main_segment|S:s'=> \$Param->{main_segment},
        'retry_up:i' =>	\$Param->{retry_up},
        'retry_down:i' =>	\$Param->{retry_down},
        'execution_time:i' => \$Param->{print_execution},
        'development:i' => \$Param->{development},
        'development_time:i' => \$Param->{development_time},
        'single_writer:i' => \$Param->{single_writer},
        'writer_is_also_reader:i' => \$Param->{writer_is_reader},        
        'active_failover:i' => \$Param->{active_failover},
        'check_timeout:i' => \$Param->{check_timeout},
        
        'help|?'       => \$Param->{help}
       
    ) or pod2usage(2);
    pod2usage(-verbose => 2) if $Param->{help};

    die print Utils->print_log(1,"Option --hostgroups not specified.\n") unless defined($Param->{hostgroups});
    die print Utils->print_log(1,"Option --host not specified.\n") unless defined $Param->{host};
    die print Utils->print_log(1,"Option --user not specified.\n") unless defined $Param->{user};
    die print Utils->print_log(1,"Option --port not specified.\n") unless defined $Param->{port};
    die print Utils->print_log(1,"Option --active_failover has an invalid value ($Param->{active_failover}).\n"
                               ."Valid values are:\n"
                               ." 0 [default] do not make failover\n"
                               ." 1 make failover only if HG 8000 is specified in ProxySQL mysl_servers\n"
                               ." 2 use PXC_CLUSTER_VIEW to identify a server in the same segment\n"
                               ." 3 do whatever to keep service up also failover to another segment (use PXC_CLUSTER_VIEW) ") unless $Param->{active_failover} < 4;
    #die "Option --log not specified. We need a place to log what is going on, don't we?\n" unless defined $Param->{log};
    print Utils->print_log(2,"Option --log not specified. We need a place to log what is going on, don't we?\n") unless defined $Param->{log};
    
    if($Param->{debug}){
       Utils::debugEnv();
    }
    
    $Param->{host} = URLDecode($host);    
    my $dsn  = "DBI:mysql:host=$Param->{host};port=$Param->{port}";
    
    if(defined $Param->{user}){
      $user = "$Param->{user}";
    }
    if(defined $Param->{password}){
	    $pass = "$Param->{password}";
    }
    my $hg =$Param->{hostgroups};
    $hg =~ s/[\:,\,]/_/g;
    my $base_path = "${run_pid_dir}/proxysql_galera_check_${hg}.pid";
    
    
    
    #============================================================================
    # Execution
    #============================================================================
    if(defined $Param->{log}){
       open(FH, '>>', $Param->{log}."_".$hg.".log") or die Utils->print_log(1,"cannot open file");
       FH->autoflush if $Param->{development} < 2;
       select FH;
    }
    
    if($Param->{development} < 2){
      if(!-e $base_path){
         `echo "$$" > $base_path`
      }
      else{
          my $existing_pid=`cat $base_path`;
          my $exists = kill 0, $existing_pid;
          if($exists > 0){
             print STDOUT "Another process is running using the same HostGroup and settings,\n Or orphan pid file. check in $base_path \n";
             print Utils->print_log(1,"Another process is running using the same HostGroup and settings,\n Or orphan pid file. check in $base_path \n");
             exit 1;
          }
          else{
               `echo "$$" > $base_path`;
          }
      }    
    }
     
    # for test only purpose comment for prod

    my $xx =1;
    my $y =0;
    $xx=2000000000 if($Param->{development} > 0);
 	
    while($y < $xx){
       ++$y ;
	
       my $start = gettimeofday();    
       if($Param->{debug} >= 1){
          print Utils->print_log(3,"START EXECUTION\n");
       }
       
   
       
       my $proxy_sql_node = get_proxy($dsn, $user, $pass ,$Param->{debug}) ;
       $proxy_sql_node->retry_up($Param->{retry_up});
       $proxy_sql_node->retry_down($Param->{retry_down});
       $proxy_sql_node->hostgroups($Param->{hostgroups}) ;
       $proxy_sql_node->require_failover($Param->{active_failover});
       $proxy_sql_node->check_timeout($Param->{check_timeout});
       
       $proxy_sql_node->connect();
       
       # create basic galera cluster object and fill info
       $proxy_sql_node->set_galera_cluster();
       my $galera_cluster = $proxy_sql_node->get_galera_cluster();
       
       if( defined $galera_cluster){
           $galera_cluster->main_segment($Param->{main_segment});
           $galera_cluster->cluster_identifier($hg);
           $galera_cluster->get_nodes();
       }
       
       # Retrive the nodes state
       if(defined $galera_cluster->nodes){
          $galera_cluster->process_nodes();
    
       }
       
       #Analyze nodes state from ProxySQL prospective;
       if(defined  $galera_cluster->nodes){
          my %action_node = $proxy_sql_node->evaluate_nodes($galera_cluster);
    
       }
       
       if(defined $proxy_sql_node->action_nodes){
          $proxy_sql_node->push_changes;
       }
       
       my $end = gettimeofday();
       print Utils->print_log(3,"END EXECUTION Total Time(ms):".($end - $start) * 1000 ."\n") if $Param->{print_execution} >0; 
       if($Param->{debug} >= 1){
          print Utils->print_log(3,"\n");
       }
       FH->flush(); 
       
       $proxy_sql_node->disconnect();
    
       #debug braket 	
        sleep $Param->{development_time} if($Param->{development} > 0);

    }
    
    if(defined $Param->{log}){
       close FH;  # in the end
    }
    
    `rm -f $base_path`;
    
      
    exit(0);
    
    
 }

# ############################################################################
# Run the program.
# ############################################################################
    exit main(@ARGV);

{
    package Galeracluster;
    use threads;
    use threads::shared;
    use strict;
    use warnings;
    use Time::HiRes qw(gettimeofday usleep);
    
    sub new {
        my $class = shift;
        my $SQL_get_mysql_servers=" SELECT a.* FROM runtime_mysql_servers a join stats_mysql_connection_pool b on a.hostname=b.srv_host and a.port=b.srv_port and a.hostgroup_id=b.hostgroup  WHERE b.status not in ('OFFLINE_HARD','SHUNNED') ";
        
        # Variable section for  looping values
        #Generalize object for now I have conceptualize as:
        # Cluster (generic container)
        # Cluster->{name}     This is the cluster name
        # Cluster->{nodes}       the nodes in the cluster Map by node name
        # Cluster->{status}     cluster status [Primary|not Primary]
        # Cluster->{size}     cluster status [Primary|not Primary]
        # Cluster->{singlenode}=0;  0 if false 1 if true meaning only one ACTIVE node in the cluster 
        # Cluster->{haswriter}=0;  0 if false 1 if true at least a node is fully active as writer
        # Cluster->{singlewriter}=1;  0 if false 1 if true this cluster can have ONLY one writer a time [true default]
        
        my $self = {
            _name      => undef,
            _hosts  => {},
            _status    => undef,
            _size  => {},
            _singlenode  => 0,
            _haswriter => 0,
            _singlewriter => 1,
            _main_segment => 0,
            _SQL_get_mysql_servers => $SQL_get_mysql_servers,
            _hostgroups => undef,
            _dbh_proxy => undef,
            _debug => 0,
            _monitor_user => undef,
            _monitor_password => undef,
            _nodes => {},
            _nodes_maint => {},
            _check_timeout => 100, #timeout in ms
            _cluster_identifier => undef,
            _hg_writer_id => 0,
            _hg_reader_id => 0,
            _writer_is_reader => 0,
            _reader_nodes => [] ,
            _writer_nodes => [] ,
            _has_failover_node =>0,
            _writers =>0,
            #_hg => undef,
        };
        bless $self, $class;
        return $self;
        
    }

   sub has_failover_node{
        my ( $self, $in ) = @_;
        $self->{_has_failover_node} = $in if defined($in);
        return $self->{_has_failover_node};
    }
   
   sub writer_nodes{
        my ( $self, $in ) = @_;
        $self->{_writer_nodes} = $in if defined($in);
        return $self->{_writer_nodes};
    }

    sub reader_nodes{
        my ( $self, $in ) = @_;
        $self->{_reader_nodes} = $in if defined($in);
        return $self->{_reader_nodes};
    }

    sub cluster_identifier{
        my ( $self, $in ) = @_;
        $self->{_cluster_identifier} = $in if defined($in);
        return $self->{_cluster_identifier};
    }

    sub main_segment{
        my ( $self, $main_segment ) = @_;
        $self->{_main_segment} = $main_segment if defined($main_segment);
        return $self->{_main_segment};
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

    sub nodes_maint {
        my ( $self, $nodes ) = @_;
        $self->{_nodes_maint} = $nodes if defined($nodes);
        return $self->{_nodes_maint};
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
    
    sub singlewriter {
        my ( $self, $singlewriter ) = @_;
        $self->{_singlewriter} = $singlewriter if defined($singlewriter);
        return $self->{_singlewriter};
    }

    sub writer_is_reader {
        my ( $self, $writer_is_reader ) = @_;
        $self->{_writer_is_reader} = $writer_is_reader if defined($writer_is_reader);
        return $self->{_writer_is_reader};
    }
    sub writers {
        my ( $self, $in ) = @_;
        $self->{_writers} = $in if defined($in);
        return $self->{_writers};
    }

    sub hostgroups {
        my ( $self, $hostgroups ) = @_;
        $self->{_hostgroups} = $hostgroups if defined($hostgroups);
        return $self->{_hostgroups};
    }
    sub hg_writer_id {
        my ( $self, $hostgroups ) = @_;
        $self->{_hg_writer_id} = $hostgroups if defined($hostgroups);
        return $self->{_hg_writer_id};
    }

    sub hg_reader_id {
        my ( $self, $hostgroups ) = @_;
        $self->{_hg_reader_id} = $hostgroups if defined($hostgroups);
        return $self->{_hg_reader_id};
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
        my $cmd =$self->{_SQL_get_mysql_servers}." AND hostgroup_id IN (".join(",",sort keys(%{$self->hostgroups})).") order by hostgroup_id, hostname";
        my $sth = $dbh->prepare($cmd);
        $sth->execute();
        my $i = 1;
        my $locHg = $self->{_hostgroups};
        
       while (my $ref = $sth->fetchrow_hashref()) {
            my $node = GaleraNode->new();
            $node->debug($self->debug);
            $node->dns("DBI:mysql:host=".$ref->{hostname}.";port=".$ref->{port});
            $node->hostgroups($ref->{hostgroup_id});
            if($node->{_hostgroups} > 8000
               && exists $locHg->{$node->{_hostgroups}}){
                  $self->{_has_failover_node} = 1;
                
            }
            $node->ip($ref->{hostname});
            $node->port($ref->{port});
            $node->weight($ref->{weight});
            $node->connections($ref->{max_connections});
            $node->user($self->{_monitor_user});
            $node->password($self->{_monitor_password});
            $node->proxy_status($ref->{status});
            $node->comment($ref->{comment});
            $node->set_retry_up_down($self->{_cluster_identifier});
            
            $node->gtid_port($ref->{gtid_port});
            $node->compression($ref->{compression});
            $node->use_ssl($ref->{use_ssl});
            $node->max_latency($ref->{max_latency_ms});
            $node->max_replication_lag($ref->{max_replication_lag});
	    
     
            $self->{_nodes}->{$i++}=$node;
            $node->debug($self->debug);
            
            if($self->debug){print Utils->print_log(3," Galera cluster node   " . $node->ip.":". $node->port.":HG=".$node->hostgroups."\n" ) }
        }
	
       if($self->debug){print Utils->print_log(3," Galera cluster nodes loaded \n") ; }
    }
    #Processing the nodes in the cluster and identify which node is active and which is to remove
    
    sub process_nodes{
        my ( $self ) = @_;

        my $nodes = $self->{_nodes} ;
        my $start = gettimeofday();
        my $run_milliseconds=0;
        my $init =0;
        my $irun = 1;
        my %Threads;
        my $new_nodes ={} ;
        my $processed_nodes ={} ;
        
        #using multiple threads to connect if a node is present in more than one HG it will have 2 threads
        while($irun){
            $irun = 0;
            foreach my $key (sort keys %{$self->{_nodes}}){
                if(!exists $Threads{$key}){
                   if($self->debug){print Utils->print_log(3, " Creating new thread to manage server check:".
                      $self->{_nodes}->{$key}->ip.":".
                      $self->{_nodes}->{$key}->port.":HG".$self->{_nodes}->{$key}->hostgroups."\n" ) }
                    $new_nodes->{$key} =  $self->{_nodes}->{$key};
                    $new_nodes->{$key}->{_process_status} = -1;
                    #  debug senza threads comment next line
                    $Threads{$key}=threads->create(sub  {return get_node_info($self,$key)});
                    
                    #DEBUG Without threads uncomment from here
            #        next unless  $new_nodes->{$key} = get_node_info($self,$key);
            #        evaluate_joined_node($self, $key, $new_nodes, $processed_nodes) ;
    
             # to here
		    
                }
            }
            ##DEBUG SENZA THREADS commenta da qui
            foreach my $thr (sort keys %Threads) {
                if($new_nodes->{$thr}->{_process_status} eq -100){
                    next;
                }
                
                if ($Threads{$thr}->is_running()) {
                    my $tid = $Threads{$thr}->tid;
                    #print "  - Thread $tid running\n";
                   
                    if($run_milliseconds >  $self->{_check_timeout} ){
                       if($self->debug >=0){
                         my $timeout = ($run_milliseconds -  $self->{_check_timeout});  
                         print print Utils->print_log(2,"Check timeout Node ip : $new_nodes->{$thr}->{_ip} ,  THID " . $tid." (taken: $run_milliseconds   max_allowed: $self->{_check_timeout}  over for ms: $timeout  \n")
                        }	
                          $irun = 0 ; 
                    }
                    else{
                         $irun = 1;
                    }
                } 
                elsif ( $Threads{$thr}->is_joinable()) {
                 
                       my $tid = $Threads{$thr}->tid;
                       ( $new_nodes->{$thr} ) = $Threads{$thr}->join;
                       #$processed_nodes =
                       evaluate_joined_node($self, $thr, $new_nodes, $processed_nodes) ;
                     
                     if($self->debug){print Utils->print_log(3," Thread joined :   " . $tid."\n" ) }	
                        #print "  - Results for thread $tid:\n";
                        #print "  - Thread $tid has been joined\n";
                }
                #print ".";
            }
            # a qui
            if($self->debug){$run_milliseconds = (gettimeofday() -$start ) *1000};
            #sleep for a time equal to the half of the timeout to save cpu cicle
            #usleep(($self->{_check_timeout} * 1000)/2);
        }

        $self->{_nodes} = $new_nodes;
        if($self->debug){$run_milliseconds = (gettimeofday() -$start ) *1000};
	
        if($debug>=3){
            foreach my $key (sort keys %{$new_nodes}){
              if($new_nodes->{$key}->{_process_status} == 1){
                  print Utils->print_log(4,$new_nodes->{$key}->{_ip}.":".$new_nodes->{$key}->{_hostgroups}." Processed \n");
              }
              else{
                  print Utils->print_log(4,$new_nodes->{$key}->{_ip}.":".$new_nodes->{$key}->{_hostgroups}." NOT Processed\n");
              }
           }
        }
       	if($self->debug){print Utils->print_log(3," Multi Thread execution done in :   " . $run_milliseconds. "(ms) \n"  )}	
    
    }
    
    sub evaluate_joined_node($$$$){
        my $self = shift;
        my $thr = shift;
        my $new_nodes = shift;
        my $processed_nodes = shift;
        
            #count the number of nodes by segment
         if($new_nodes->{$thr}->{_proxy_status} ne "OFFLINE_SOFT"
            && $new_nodes->{$thr}->{_proxy_status} ne "SHUNNED"
            && ($new_nodes->{$thr}->{_process_status} < 0 ||
             !exists $processed_nodes->{$new_nodes->{$thr}->{_ip}})
             && defined $new_nodes->{$thr}->{_wsrep_segment} 
           ){
                $self->{_size}->{$new_nodes->{$thr}->{_wsrep_segment}} = (($self->{_size}->{$new_nodes->{$thr}->{_wsrep_segment}}|| 0) +1);
                $processed_nodes->{$new_nodes->{$thr}->{_ip}}=$self->{_size}->{$new_nodes->{$thr}->{_wsrep_segment}};
         }
      
      #assign size to HG
        if($new_nodes->{$thr}->{_proxy_status} ne "OFFLINE_SOFT"
           && defined $new_nodes->{$thr}->{_wsrep_segment} 
           ){
            $self->{_hostgroups}->{$new_nodes->{$thr}->{_hostgroups}}->{_size} = ($self->{_hostgroups}->{$new_nodes->{$thr}->{_hostgroups}}->{_size}) + 1;
        }
        
     #checks for ONLINE writer(s)

       if(defined $new_nodes->{$thr}->{_read_only}
          && $new_nodes->{$thr}->{_read_only} eq "OFF"
          && ($new_nodes->{$thr}->{_proxy_status} eq "ONLINE" || $new_nodes->{$thr}->{_proxy_status} eq "OFFLINE_SOFT")
          && ($new_nodes->{$thr}->{_hostgroups} == $self->hg_writer_id || $new_nodes->{$thr}->{_hostgroups} == ($self->hg_writer_id +9000))
         ){
           if($new_nodes->{$thr}->{_hostgroups} == $self->hg_writer_id
              && $new_nodes->{$thr}->{_proxy_status} eq "ONLINE"
             ){
              $self->{_haswriter} = 1 ;
              $self->{_writers} = $self->{_writers} +1;
           }
             push (@{$self->{_writer_nodes}}, "$new_nodes->{$thr}->{_ip}:$new_nodes->{$thr}->{_port}");  
        }
       elsif(($new_nodes->{$thr}->{_proxy_status} eq "ONLINE" || $new_nodes->{$thr}->{_proxy_status} eq "OFFLINE_SOFT")
          && ($new_nodes->{$thr}->{_hostgroups} == $self->hg_reader_id || $new_nodes->{$thr}->{_hostgroups} == ($self->hg_reader_id +9000))
       ){
            push (@{$self->{_reader_nodes}}, "$new_nodes->{$thr}->{_ip}:$new_nodes->{$thr}->{_port}");  
       }
       else{
             if($self->debug
                && $new_nodes->{$thr}->{_hostgroups} == $self->hg_writer_id){
                   print Utils->print_log(3," Not a writer :" .$new_nodes->{$thr}->{_ip} . " HG: $new_nodes->{$thr}->{_hostgroups}  \n" )
             }	
       }
      # check if under maintenance
       if($new_nodes->{$thr}->{_proxy_status} eq "OFFLINE_SOFT"
          && $new_nodes->{$thr}->{_pxc_maint_mode} eq "MAINTENANCE"){
             $self->{_nodes_maint}->{$thr} =  $new_nodes->{$thr};
        }
       #return $processed_nodes;
     
    }
    
    sub get_node_info($$){
        my $self = shift;
        my $key = shift;
        my $nodes =shift;
        my ( $node ) = $self->{_nodes}->{$key};
        if(!defined $node->get_node_info()){
           $node->{_process_status}=-100;
         }
	
        return $node;
        
    }
    
}

{
    package GaleraNode;
    #Node Proxy States
    sub new {
        my $class = shift;
        my $SQL_get_variables="SHOW GLOBAL VARIABLES LIKE 'wsrep%";
        my $SQL_get_status="SHOW GLOBAL STATUS LIKE 'wsrep%";
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
            _port => 3306,
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
            _wsrep_segment => 1000,
            _wsrep_pc_weight => 1,
            _SQL_get_variables => $SQL_get_variables,
            _SQL_get_status=> $SQL_get_status,
            _SQL_get_read_only=> $SQL_get_read_only,
            _dns  => undef,
            _user => undef,
            _password => undef,
            _debug => 0,
            _port => undef,
            _proxy_status    => undef,
            _weight => 1,
            _connections => 2000,
            _cluster_status    => undef,
            _cluster_size  => 0,
            _process_status => -1, 
            _MOVE_UP_OFFLINE => 1000, #move a node from OFFLINE_SOFT 
            _MOVE_UP_HG_CHANGE => 1010, #move a node from HG 9000 (plus hg id) to reader HG 
            _MOVE_DOWN_HG_CHANGE => 3001, #move a node from original HG to maintenance HG (HG 9000 (plus hg id) ) kill all existing connections
            _MOVE_DOWN_OFFLINE => 3010 , # move node to OFFLINE_soft keep existing connections, no new connections.
            _MOVE_TO_MAINTENANCE => 3020 , # move node to OFFLINE_soft keep existing connections, no new connections because maintenance.
            _MOVE_OUT_MAINTENANCE => 3030 , # move node to OFFLINE_soft keep existing connections, no new connections because maintenance.
            _INSERT_READ => 4010, # Insert a node in the reader host group
            _INSERT_WRITE => 4020, # Insert a node in the writer host group
            _DELETE_NODE => 5000, # this remove the node from the hostgroup
            _SAVE_RETRY => 9999, # this reset the retry counter in the comment 
            #_MOVE_SWAP_READER_TO_WRITER => 5001, #Future use
            #_MOVE_SWAP_WRITER_TO_READER => 5010, #Future use
            _retry_down_saved => 0, # number of retry on a node before declaring it as failed.
            _retry_up_saved => 0, # number of retry on a node before declaring it OK.
            _comment => undef,
            _gtid_port => 0,
            _compression => 0,
            _use_ssl => 0,
            _max_latency => 0,
            _max_replication_lag => 0,
            _wsrep_gcomm_uuid => undef,
            _wsrep_local_index => 0,
            _pxc_maint_mode => undef,

        };
        bless $self, $class;
        return $self;
        
    }

    sub max_replication_lag{
        my ( $self, $in ) = @_;
        $self->{_max_replication_lag} = $in if defined($in);
        return $self->{_max_replication_lag};
    }

    sub max_latency{
        my ( $self, $in ) = @_;
        $self->{_max_latency} = $in if defined($in);
        return $self->{_max_latency};
    }
    
    sub use_ssl{
        my ( $self, $in ) = @_;
        $self->{_use_ssl} = $in if defined($in);
        return $self->{_use_ssl};
    }

    sub compression{
        my ( $self, $in ) = @_;
        $self->{_compression} = $in if defined($in);
        return $self->{_compression};
    }

    sub gtid_port{
        my ( $self, $in ) = @_;
        $self->{_gtid_port} = $in if defined($in);
        return $self->{_gtid_port};
    }

    sub pxc_maint_mode{
        my ( $self, $in ) = @_;
        $self->{_pxc_maint_mode} = $in if defined($in);
        return $self->{_pxc_maint_mode};
    }
    sub wsrep_local_index{
        my ( $self, $in ) = @_;
        $self->{_wsrep_local_index} = $in if defined($in);
        return $self->{_wsrep_local_index};
    }

    sub comment{
        my ( $self, $in ) = @_;
        $self->{_comment} = $in if defined($in);
        return $self->{_comment};
    }

    sub wsrep_gcomm_uuid{
        my ( $self, $in ) = @_;
        $self->{_wsrep_gcomm_uuid} = $in if defined($in);
        return $self->{_wsrep_gcomm_uuid};
    }
    
    sub retry_down_saved{
        my ( $self, $in ) = @_;
        $self->{_retry_down_saved} = $in if defined($in);
        return $self->{_retry_down_saved};
    }

    sub retry_up_saved{
        my ( $self, $in ) = @_;
        $self->{_retry_up_saved} = $in if defined($in);
        return $self->{_retry_up_saved};
    }
    
    sub process_status {
        my ( $self, $process_status ) = @_;
        $self->{_process_status} = $process_status if defined($process_status);
        return $self->{_process_status};
    }

    sub debug{
        my ( $self, $debug ) = @_;
        $self->{_debug} = $debug if defined($debug);
        return $self->{_debug};
    }

    sub SAVE_RETRY {
        my ( $self) = @_;
        return $self->{_SAVE_RETRY};
    }

    sub MOVE_UP_OFFLINE {
        my ( $self) = @_;
        return $self->{_MOVE_UP_OFFLINE};
    }

    sub MOVE_UP_HG_CHANGE {
        my ( $self) = @_;
        return $self->{_MOVE_UP_HG_CHANGE};
    }
    
    sub MOVE_DOWN_OFFLINE {
        my ( $self) = @_;
        return $self->{_MOVE_DOWN_OFFLINE};
    }
    
    
    sub MOVE_TO_MAINTENANCE {
        my ( $self) = @_;
        return $self->{_MOVE_TO_MAINTENANCE};
    }
    
    sub MOVE_OUT_MAINTENANCE {
        my ( $self) = @_;
        return $self->{_MOVE_OUT_MAINTENANCE};
    }

    sub MOVE_DOWN_HG_CHANGE {
        my ( $self) = @_;
        return $self->{_MOVE_DOWN_HG_CHANGE};
    }
    sub DELETE_NODE {
        my ( $self) = @_;
        return $self->{_DELETE_NODE};
    }
    sub INSERT_READ {
        my ( $self) = @_;
        return $self->{_INSERT_READ};
    }
    sub INSERT_WRITE {
        my ( $self) = @_;
        return $self->{_INSERT_WRITE};
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

    sub connections {
        my ( $self, $connections ) = @_;
        $self->{_connections} = $connections if defined($connections);
        return $self->{_connections};
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
    sub port {
        my ( $self, $port ) = @_;
        $self->{_port} = $port if defined($port);
        return $self->{_port};
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
        my ( @array)= @{$wsrep_provider} ;
        my %provider_map ;
        foreach my $item (@array){
          my @items = split('\=', $item);
          $provider_map{Utils::trim($items[0])}=$items[1];
        }
        ($self->{_wsrep_provider}) = {%provider_map} ;
        $self->wsrep_segment($provider_map{"gmcast.segment"});
        $self->wsrep_pc_weight($provider_map{"pc.weight"});
        return $self->{_wsrep_provider};
    }

    sub get_node_info($$){
        my ( $self ) = @_;
        
        if($self->debug >=1){
           print Utils->print_log(4," Node check START "
            .$self->{_ip}
            .":".$self->{_port}
            .":HG".$self->{_hostgroups}
            ."\n"  );
        }	
	       if($self->debug >=1){
           print Utils->print_log(4," Getting connection START "
            .$self->{_ip}
            .":".$self->{_port}
            .":HG".$self->{_hostgroups}." \n"  );
        }	
        my $dbh = Utils::get_connection($self->{_dns},$self->{_user},$self->{_password},' ');
        if(!defined $dbh){
           print Utils->print_log(1," Node is not responding setting it as SHUNNED (ProxySQL bug - #2658)"
             .$self->{_ip}
            .":".$self->{_port}
            .":HG".$self->{_hostgroups}." \n"  );
           $self->{_proxy_status} = "SHUNNED";
           return $self ; 
           
        }
	       if($self->debug >=1){
           print Utils->print_log(4," Getting connection END "
             .$self->{_ip}
            .":".$self->{_port}
            .":HG".$self->{_hostgroups}." \n"  );

        }	

	       if($self->debug >=1){
           print Utils->print_log(4," Getting NODE info START "
             .$self->{_ip}
            .":".$self->{_port}
            .":HG".$self->{_hostgroups}." \n"  );
        }	

        my $variables = Utils::get_variables($dbh,0);
        my $status = Utils::get_status_by_name($dbh,0,"wsrep_%");
        my $pxc_view = Utils::get_pxc_clusterview($dbh, $status->{wsrep_gcomm_uuid} );

	       if($self->debug >=1){
           print Utils->print_log(4," Getting NODE info END "
             .$self->{_ip}
            .":".$self->{_port}
            .":HG".$self->{_hostgroups}." \n"  );
        }	
        
        $self->{_name} = $variables->{wsrep_node_name};
        $self->{_clustername} = $variables->{wsrep_cluster_name};
        $self->{_read_only} = $variables->{read_only};
        $self->{_wsrep_rejectqueries} = $variables->{wsrep_reject_queries};
        #print "AAAAAAAAAAAAAAAAAAAAA  $self->{_ip}  $self->{_wsrep_rejectqueries} \n";
        $self->{_wsrep_donorrejectqueries} = $variables->{wsrep_sst_donor_rejects_queries};
        my ( @provider ) =  split('\;', $variables->{wsrep_provider_options});
        $self->{_pxc_maint_mode} = $variables->{pxc_maint_mode};
        
        $self->wsrep_provider( [ @provider]) ;
        $self->{_wsrep_status} = $status->{wsrep_local_state};
        $self->{_wsrep_connected} = $status->{wsrep_connected};
        $self->{_wsrep_desinccount} = $status->{wsrep_desync_count};
        $self->{_wsrep_ready} = $status->{wsrep_ready};
        $self->{_cluster_status} = $status->{wsrep_cluster_status};
        $self->{_cluster_size} = $status->{wsrep_cluster_size};
        $self->{_wsrep_gcomm_uuid} = $status->{wsrep_gcomm_uuid};
        $self->{wsrep_segment} = ($self->{_wsrep_provider}->{"gmcast.segment"} );
        $self->{wsrep_segment} =~ s/^\s+|\s+$//g;
        $self->{_wsrep_local_index} = $pxc_view->{local_index};
        if($self->{wsrep_segment} == 0){
           $self->{_wsrep_segment} = $pxc_view->{segment};
        }
                
        $dbh->disconnect if (defined $dbh);
	#sleep 5;
	
        $self->{_process_status} = 1;
        if($self->debug>=1){
            print Utils->print_log(4," Node check END "
            .$self->{_ip}
            .":".$self->{_port}
            .":HG".$self->{_hostgroups}
            ."\n"  );}	

        return $self;
        
    }
    
    sub set_retry_up_down(){
      my ( $self, $hg ) = @_;
      if($self->debug >=1){print Utils->print_log(4,"Calculate retry from comment Node:".$self->ip." port:".$self->port . " hg:".$self->hostgroups ." Time IN \n");}
	
     	my %comments = split /[;=]/, $self->{_comment};
      if(exists $comments{$hg."_retry_up"}){
          $self->{_retry_up_saved} = $comments{$hg."_retry_up"};
      }
      else{
          $self->{_retry_up_saved} = 0;
      }
      if(exists $comments{$hg."_retry_down"}){
          $self->{_retry_down_saved} = $comments{$hg."_retry_down"};
      }
      else{
          $self->{_retry_down_saved} = 0;
      }
      my $removeUp=$hg."_retry_up=".$self->{_retry_up_saved}.";";
      my $removeDown=$hg."_retry_down=".$self->{_retry_down_saved}.";";
      $self->{_comment} =~ s/$removeDown//ig ;
      $self->{_comment} =~ s/$removeUp//ig ;
      
      if($self->debug >=1){print Utils->print_log(4,"Calculate retry from comment Node:".$self->ip." port:".$self->port . " hg:".$self->hostgroups ." Time OUT \n");}
    }
    
    sub get_retry_up(){
      my ( $self,$in) = @_;
      $self->{_retry_up_saved} = $in if defined($in);
      return $self->{_retry_up_saved};
    }

    sub get_retry_down(){
      my ( $self,$in) = @_;
      $self->{_retry_down_saved} = $in if defined($in);
      return $self->{_retry_down_saved};
    }
    
    sub promote_writer(){
      my ( $self,$proxynode,$Galera_cluster,$exclude_delete ) = @_;
      if($self->{_hostgroups} > 8000){
         print Utils->print_log(3,"Special Backup - Group found! I am electing a node to writer following the indications\n This Node Try to become the new"
                                  ." WRITER for HG $proxynode->{_hg_writer_id} Server details: " 
             .$self->{_ip}
             .":".$self->{_port}
             .":HG".$self->{_hostgroups}
             ."\n"  );	
       
      }
      print Utils->print_log(3,"This Node Try to become a WRITER promoting to HG $proxynode->{_hg_writer_id} " 
          .$self->{_ip}
          .":".$self->{_port}
          .":HG ".$self->{_hostgroups}
          ."\n"  );	
	
      #my $dbh = Utils::get_connection($self->{_dns},$self->{_user},$self->{_password},' ');
      #if(!defined $dbh){
      #    return undef;
      #}
      #(9000 + $proxynode->{_hg_writer_id})
      
      my $proxy_sql_command= "INSERT INTO mysql_servers (hostname,hostgroup_id,port,weight,max_connections) VALUES ('$self->{_ip}',$proxynode->{_hg_writer_id},$self->{_port},$self->{_weight},$self->{_connections});";
      if($Galera_cluster->{_singlewriter} > 0){
         my $delete = "DELETE from mysql_servers where hostgroup_id in ($proxynode->{_hg_writer_id},".(9000 + $proxynode->{_hg_writer_id}).") ".$exclude_delete;
        print Utils->print_log(2," DELETE from writer group as: " 
            ." SQL:" .$delete
            ."\n" );			    
         
         $proxynode->{_dbh_proxy}->do($delete) or die "Couldn't execute statement: " .  $proxynode->{_dbh_proxy}->errstr;
      }
      #if the writer is NOT a reader by default remove it from reader groups also the 
      if($Galera_cluster->{_writer_is_reader} < 1 ){
        my $delete = "DELETE from mysql_servers where hostgroup_id in ($proxynode->{_hg_reader_id},".(9000 + $proxynode->{_hg_reader_id}).") and hostname = '$self->{_ip}' and port=$self->{_port}  ";
        $proxynode->{_dbh_proxy}->do($delete) or die "Couldn't execute statement: " .  $proxynode->{_dbh_proxy}->errstr; 
        
      }  
      $proxynode->{_dbh_proxy}->do($proxy_sql_command) or die "Couldn't execute statement: " .  $proxynode->{_dbh_proxy}->errstr;
      $proxynode->{_dbh_proxy}->do("LOAD MYSQL SERVERS TO RUNTIME") or die "Couldn't execute statement: " .  $proxynode->{_dbh_proxy}->errstr;
      $proxynode->{_dbh_proxy}->do("SAVE MYSQL SERVERS TO DISK") or die "Couldn't execute statement: " .  $proxynode->{_dbh_proxy}->errstr;
        print Utils->print_log(2," Move node:"
            .$self->{_ip}.":"
            .$self->{_port}
            .$self->{_weight}
            .$self->{_connections}
            .$proxynode->{hg_writer_id}
            ." SQL:" .$proxy_sql_command
            ."\n" );			    

      
      
      return 1;
    }
    
    sub move_to_writer_hg(){
      my ( $self ) = @_;
        
      print Utils->print_log(3,"This Node Try to become a WRITER set READ_ONLY to 0 " 
          .$self->{_ip}
          .":".$self->{_port}
          .":HG".$self->{_hostgroups}
          ."\n"  );	
	
      my $dbh = Utils::get_connection($self->{_dns},$self->{_user},$self->{_password},' ');
      if(!defined $dbh){
          return undef;
      }
      if($dbh->do("SET GLOBAL READ_ONLY=0")){
         print Utils->print_log(3,"This Node NOW HAS READ_ONLY = 0 "
             .$self->{_ip}
             .":".$self->{_port}
             .":HG".$self->{_hostgroups}
             ."\n"  );	
      }
      else{
          die "Couldn't execute statement: " .  $dbh->errstr;
      }
     	$dbh->disconnect if (defined $dbh);
      #or die "Couldn't execute statement: " .  $dbh->errstr;
      return 1;
    }
}

{
    package ProxySqlNode;
    sub new {
        my $class = shift;

        my $SQL_get_monitor = "select variable_name name,variable_value value from global_variables where variable_name in( 'mysql-monitor_username','mysql-monitor_password','mysql-monitor_read_only_timeout' ) order by 1";
        my $SQL_get_hostgroups = "select distinct hostgroup_id hg_isd from runtime_mysql_servers order by 1;";
        my $SQL_get_rep_hg = "select writer_hostgroup,reader_hostgroup from mysql_replication_hostgroups order by 1;";
        my $SQL_get_pxc_cluster_view = "select * from performance_schema.pxc_cluster_view order by  SEGMENT, LOCAL_INDEX;";

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
            _hg_writer_id => 0,
            _hg_reader_id => 0,
            _user => undef,
            _password => undef,
            _port => undef,
            _monitor_user => undef,
            _monitor_password => undef,
            _SQL_get_monitor => $SQL_get_monitor,
            _SQL_get_hg=> $SQL_get_hostgroups,
            _SQL_get_replication_hg=> $SQL_get_rep_hg,
            _dbh_proxy => undef,
            _check_timeout => 800, #timeout in ms
            _action_nodes => {},
            _retry_down => 0, # number of retry on a node before declaring it as failed.
            _retry_up => 0, # number of retry on a node before declaring it OK.
            _status_changed => 0, #if 1 something had happen and a node had be modify
            _require_failover => 0, # Valid values are:
                                      # 0 [default] do not make failover
                                      # 1 make failover only if HG 8000 is specified in ProxySQL mysl_servers
                                      # 2 use PXC_CLUSTER_VIEW to identify a server in the same segment
                                      # 3 do whatever to keep service up also failover to another segment (use PXC_CLUSTER_VIEW) 
                                                 

        };
        bless $self, $class;
        return $self;
        
    }
    sub require_failover{
        my ( $self, $in ) = @_;
        $self->{_require_failover} = $in if defined($in);
        return $self->{_require_failover};
    }

    sub hg_reader_id{
        my ( $self, $in ) = @_;
        $self->{_hg_reader_id} = $in if defined($in);
        return $self->{_hg_reader_id};
    }
    
    sub status_changed{
        my ( $self, $in ) = @_;
        $self->{_status_changed} = $in if defined($in);
        return $self->{_status_changed};
    }

    sub retry_down{
        my ( $self, $in ) = @_;
        $self->{_retry_down} = $in if defined($in);
        return $self->{_retry_down};
    }

    sub retry_up{
        my ( $self, $in ) = @_;
        $self->{_retry_up} = $in if defined($in);
        return $self->{_retry_up};
    }

    
    sub debug{
        my ( $self, $debug ) = @_;
        $self->{_debug} = $debug if defined($debug);
        return $self->{_debug};
    }

    sub action_nodes {
        my ( $self, $action_nodes ) = @_;
        $self->{_action_nodes} = $action_nodes if defined($action_nodes);
        return $self->{_action_nodes};
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

    sub hg_writer_id {
        my ( $self, $pid ) = @_;
        $self->{_hg_writer_id} = $pid if defined($pid);
        return $self->{_hg_writer_id};
    }
    
    sub hostgroups {
        my ( $self, $hostgroups ) = @_;
        if (defined $hostgroups){
            my @HGIds=split('\,', $Param->{hostgroups});
            
            foreach my $hg (@HGIds){
               my $proxy_hg = ProxySqlHG->new();
               my $proxy_hgM = ProxySqlHG->new();
               my $proxy_hgB = ProxySqlHG->new();
               my  ($id,$type) = split /:/, $hg;
               $proxy_hg->id($id);
               $proxy_hg->type(lc($type));
               if(lc($type) eq 'w'){
                  $self->hg_writer_id($id); 
               }
               if(lc($type) eq 'r'){
                  $self->hg_reader_id($id); 
               }

               $self->{_hostgroups}->{$id}=($proxy_hg);
               $proxy_hgM->id(($id + 9000));
               $proxy_hgM->type("m".lc($type));
               $self->{_hostgroups}->{$proxy_hgM->id(($id + 9000))}=($proxy_hgM);
               #add a special group in case of back server for failover
               if(lc($type) eq "w"){
                  $proxy_hgM->id(($id + 8000));
                  $proxy_hgM->type("b".lc($type));
                  $self->{_hostgroups}->{$proxy_hgM->id(($id + 8000))}=($proxy_hgM);
               }
               if(lc($type) eq "r"){
                  $proxy_hgM->id(($id + 8000));
                  $proxy_hgM->type("b".lc($type));
                  $self->{_hostgroups}->{$proxy_hgM->id(($id + 8000))}=($proxy_hgM);
               }

               if($self->debug >=1){print Utils->print_log(3," Inizializing hostgroup " . $proxy_hg->id ." ".$proxy_hg->type . "with maintenance HG ". $proxy_hgM->id ." ".$proxy_hgM->type."\n") ; }
            }
        }
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
            #This is for now comment out.
            # this is related to issue #10, where the node is not answering in time to the check.
            # The timeout cannot be the same of the the ProxySQL read_only check
            #if($ref->{'name'} eq 'mysql-monitor_read_only_timeout' ) {$self->{_check_timeout} = $ref->{'value'};}
            
        }
        if($self->debug >=1){print Utils->print_log(3," Connecting to ProxySQL " . $self->{_dns}. "\n" ); }
        
    }
    
    sub disconnect{
        my ( $self, $port ) = @_;
        $self->{_dbh_proxy}->disconnect;
	
        
    }
    sub get_galera_cluster{
        my ( $self, $in ) = @_;
        $self->{_galera_cluster} = $in if defined($in);
        return $self->{_galera_cluster};
    }

    sub set_galera_cluster(){
        my ( $self, $port ) = @_;
        my $galera_cluster = Galeracluster->new();
        
        $galera_cluster->hostgroups($self->hostgroups);
        $galera_cluster->dbh_proxy($self->dbh_proxy);
        $galera_cluster->check_timeout($self->check_timeout);
        $galera_cluster->monitor_user($self->monitor_user);
        $galera_cluster->monitor_password($self->monitor_password);
        $galera_cluster->debug($self->debug);
        $galera_cluster->hg_writer_id($self->hg_writer_id);
        $galera_cluster->hg_reader_id($self->hg_reader_id);
        $galera_cluster->singlewriter($Param->{single_writer});
        $galera_cluster->writer_is_reader($Param->{writer_is_reader});
        
        $self->get_galera_cluster($galera_cluster);
       if($self->debug >=1){print Utils->print_log(3," Galera cluster object created  " . caller(3). "\n" ); }
    }
    
    sub evaluate_nodes{
      my ($proxynode,$GGalera_cluster)  = @_ ;
      my ( $nodes ) = $GGalera_cluster->{_nodes};
      my $action_nodes = undef;


     #Rules:
	    #see rules in the doc
	    
     #do the checks
     if($proxynode->debug >=1){print Utils->print_log(3," Evaluate nodes state \n" ) }	
       foreach my $key (sort keys %{$nodes}){
         if(defined $nodes->{$key} ){
	
            #only if node has HG that is not maintenance it can evaluate to be put down in some way
            if($nodes->{$key}->{_hostgroups} < 8000
               && $nodes->{$key}->{_process_status} > 0){
                #Check major exclusions
                # 1) wsrep state
                # 2) Node is not read only
                # 3) at least another node in the HG 
          
                if( $nodes->{$key}->wsrep_status == 2
                  && $nodes->{$key}->read_only eq "OFF"
                  #&& $GGalera_cluster->{_main_segment} != $nodes->{$key}->wsrep_segment
                  && $nodes->{$key}->proxy_status ne "OFFLINE_SOFT"
                  ){
                     if($GGalera_cluster->{_hostgroups}->{$nodes->{$key}->{_hostgroups}}->{_size} <= 1){
                        print Utils->print_log(3," Node ".$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups."; Is in state ".$nodes->{$key}->wsrep_status
                                               .". But I will not move to OFFLINE_SOFT given last node left in the Host group \n");
                        next;
                     }
                     $action_nodes->{$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_MOVE_DOWN_OFFLINE}}= $nodes->{$key};
                     #if retry is > 0 then it's managed
                     if($proxynode->retry_down > 0){
                         $nodes->{$key}->get_retry_down($nodes->{$key}->get_retry_down + 1);
                     }
                     if($proxynode->debug >=1){print Utils->print_log(3," Evaluate nodes state "
                         .$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_MOVE_DOWN_OFFLINE}
                         ." Retry #".$nodes->{$key}->get_retry_down."\n" ) }	
                     next;
                   }
             
               if( $nodes->{$key}->wsrep_status ne 4
                && $nodes->{$key}->wsrep_status ne 2){
                     $action_nodes->{$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_MOVE_DOWN_HG_CHANGE}}= $nodes->{$key};
             
                     #if retry is > 0 then it's managed
                     if($proxynode->retry_down > 0){
                         $nodes->{$key}->get_retry_down($nodes->{$key}->get_retry_down + 1);
                     }
             
                    if($proxynode->debug >=1){print Utils->print_log(3," Evaluate nodes state "
                        .$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_MOVE_DOWN_HG_CHANGE}
                        ." Retry #".$nodes->{$key}->get_retry_down."\n" )   }	
             
                   next;
               }
              
               #3) Node/cluster in non primary
               if($nodes->{$key}->cluster_status ne "Primary"){
                  $action_nodes->{$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_MOVE_DOWN_HG_CHANGE}}= $nodes->{$key};
             
                  #if retry is > 0 then it's managed
                  if($proxynode->retry_down > 0){
                      $nodes->{$key}->get_retry_down($nodes->{$key}->get_retry_down + 1);
                  }
              
                  if($proxynode->debug >=1){print Utils->print_log(3," Evaluate nodes state "
                      .$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_MOVE_DOWN_HG_CHANGE}
                      ." Retry #".$nodes->{$key}->get_retry_down."\n" )   }	
                  next;
               }		
    
               # 4) wsrep_reject_queries=NONE
               if($nodes->{$key}->wsrep_rejectqueries ne "NONE" && $nodes->{$key}->proxy_status ne "OFFLINE_SOFT"){
                  my $inc =0;
                  if($nodes->{$key}->wsrep_rejectqueries eq "ALL"){
                      $action_nodes->{$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_MOVE_DOWN_HG_CHANGE}}= $nodes->{$key};
                      $inc=1;
                  }else{
                      $action_nodes->{$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_MOVE_DOWN_HG_CHANGE}}= $nodes->{$key};
                      $inc=1;
                  }
                  #if retry is > 0 then it's managed
                  if($proxynode->retry_down > 0 && $inc > 0){
                      $nodes->{$key}->get_retry_down($nodes->{$key}->get_retry_down + 1);
                  }
               
                  if($proxynode->debug >=1){
                     print Utils->print_log(3," Evaluate nodes state "
                        .$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_MOVE_DOWN_HG_CHANGE}
                        ." Retry #".$nodes->{$key}->get_retry_down."\n" )   }	
                  next;
               }
               
               #5) Donor, node reject queries =1 size of cluster > 2 of nodes in the same segments
               if($nodes->{$key}->wsrep_status eq 2
                  && $nodes->{$key}->wsrep_donorrejectqueries eq "ON"){
                  $action_nodes->{$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_MOVE_DOWN_HG_CHANGE}}= $nodes->{$key};
                  #if retry is > 0 then it's managed
                  if($proxynode->retry_down > 0){
                      $nodes->{$key}->get_retry_down($nodes->{$key}->get_retry_down + 1);
                  }
               
                  if($proxynode->debug >=1){
                     print Utils->print_log(3," Evaluate nodes state "
                        .$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_MOVE_DOWN_HG_CHANGE}
                        ." Retry #".$nodes->{$key}->get_retry_down."\n" )   }	
               
                  next;
               }
               
               #Set OFFLINE_SOFT a writer: 
               #1) donor node reject queries - 0
               #2)size of cluster > 2 of nodes in the same segments
               #3) more then one writer in the same HG
               #4) Node had pxc_maint_mode set to anything except DISABLED, not matter what it will go in OFFLINE_SOFT
               
               if(
                  $nodes->{$key}->read_only eq "ON"
                  && $nodes->{$key}->{_hostgroups} ==  $GGalera_cluster->{_hg_writer_id}
                  && $nodes->{$key}->wsrep_donorrejectqueries eq "OFF"
                  && $nodes->{$key}->proxy_status ne "OFFLINE_SOFT"
                  ){
                    ## In case READ_ONLY is OFF and we have only a node left but desync do not put it down
                    #if( $GGalera_cluster->{_size}->{$nodes->{$key}->{_wsrep_segment}} == 1
                    #    &&$nodes->{$key}->read_only eq "OFF"){
                    #    next; 
                    #}
                    $action_nodes->{$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_MOVE_DOWN_OFFLINE}}= $nodes->{$key};
                    #if retry is > 0 then it's managed
                    if($proxynode->retry_down > 0){
                        $nodes->{$key}->get_retry_down($nodes->{$key}->get_retry_down + 1);
                    }
                 
                    if($proxynode->debug >=1){print Utils->print_log(3," Evaluate nodes state "
                        .$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_MOVE_DOWN_OFFLINE}
                        ." Retry #".$nodes->{$key}->get_retry_down."\n" ) }	
                 
                    next;
               }
               
               #4) Node had pxc_maint_mode set to anything except DISABLED, not matter what it will go in OFFLINE_SOFT
               if( defined $nodes->{$key}->pxc_maint_mode 
                && $nodes->{$key}->pxc_maint_mode ne "DISABLED"
                && $nodes->{$key}->proxy_status ne "OFFLINE_SOFT"){
                     $action_nodes->{$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_MOVE_TO_MAINTENANCE}}= $nodes->{$key};
             
                     #if retry is > 0 then it's managed
                     if($proxynode->retry_down > 0){
                         $nodes->{$key}->get_retry_down($proxynode->retry_down ); # this is a known state and we do not want any delay set the retry to his max
                     }
                    
                    if(
                      $nodes->{$key}->{_hostgroups} ==  $GGalera_cluster->{_hg_writer_id}
                      && $GGalera_cluster->{_singlewriter} > 0
                      ){
                       $GGalera_cluster->{_haswriter} = $GGalera_cluster->{_haswriter} -1;
                    }
                    
                    
                    if($proxynode->debug >=1){print Utils->print_log(3," Evaluate nodes state "
                        .$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_MOVE_TO_MAINTENANCE}
                        ." Retry #".$nodes->{$key}->get_retry_down."\n" )   }	
             
                   next;
               }
       
               # Node must be removed if writer is reader is disable and node is in writer group
               if($nodes->{$key}->wsrep_status eq 4
                    && $nodes->{$key}->wsrep_rejectqueries eq "NONE"
                    && $nodes->{$key}->read_only eq "OFF"
                    && $nodes->{$key}->cluster_status eq "Primary"
                    && $nodes->{$key}->hostgroups == $proxynode->{_hg_reader_id}
                    && $GGalera_cluster->{_writer_is_reader} < 1
                    && $nodes->{$key}->proxy_status eq "ONLINE"
                    ){
                      #my $nodes_read_ips = join(',', @{$GGalera_cluster->{_reader_nodes}});
                      my $nodes_write_ips = join(',', @{$GGalera_cluster->{_writer_nodes}});
                      
                      my $ip = "$nodes->{$key}->{_ip}:$nodes->{$key}->{_port}";
                      
                      if($nodes_write_ips =~ m/$ip/ ){
                        $action_nodes->{$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_DELETE_NODE}}= $nodes->{$key}; 
                         #if retry is > 0 then it's managed
                         if($proxynode->retry_up > 0){
                             $nodes->{$key}->get_retry_up($nodes->{$key}->get_retry_up +1);
                         }
                         print Utils->print_log(3," Writer is also reader disabled removing node from reader Hostgroup "
                               .$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_DELETE_NODE}
                               ." Retry #".$nodes->{$key}->get_retry_up."\n" );
                         
                        next;
                      }

                 }
      
               
            }    
            #Node comes back from offline_soft when (all of them):
            # 1) Node state is 4
            # 3) wsrep_reject_queries = none
            # 4) Primary state
            # 5) pxc_maint_mode is DISABLED or undef
   
            if($nodes->{$key}->wsrep_status eq 4
               && $nodes->{$key}->proxy_status eq "OFFLINE_SOFT"
               && $nodes->{$key}->wsrep_rejectqueries eq "NONE"
               && $nodes->{$key}->read_only eq "OFF"
               &&$nodes->{$key}->cluster_status eq "Primary"
               &&(!defined $nodes->{$key}->pxc_maint_mode || $nodes->{$key}->pxc_maint_mode eq "DISABLED") 
               && $nodes->{$key}->hostgroups < 8000
               ){
                  if($GGalera_cluster->haswriter > 0
                     && $GGalera_cluster->singlewriter > 0
                     && $nodes->{$key}->hostgroups == $GGalera_cluster->hg_writer_id
                     ){
                     $action_nodes->{$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_DELETE_NODE}}= $nodes->{$key};
                     #if retry is > 0 then it's managed
                     if($proxynode->retry_up > 0){
                         $nodes->{$key}->get_retry_up($nodes->{$key}->get_retry_up +1);
                     }
                     if($proxynode->debug <=1){
                        print Utils->print_log(3, " Evaluate nodes state "
                            .$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_DELETE_NODE}
                            ." Retry #".$nodes->{$key}->get_retry_up."\n" ) }			    
                     next;
                  }
                 else{
                     $action_nodes->{$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_MOVE_UP_OFFLINE}}= $nodes->{$key};
                     #if retry is > 0 then it's managed
                     if($proxynode->retry_up > 0){
                         $nodes->{$key}->get_retry_up($nodes->{$key}->get_retry_up +1);
                     }
                     if($proxynode->debug <=1){
                        print Utils->print_log(3, " Evaluate nodes state "
                            .$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_MOVE_UP_OFFLINE}
                            ." Retry #".$nodes->{$key}->get_retry_up."\n" ) }			    
                     next;
                 }
            }
            
            # Node comes back from maintenance HG when (all of them):
            # 1) node state is 4
            # 3) wsrep_reject_queries = none
            # 4) Primary state
            if($nodes->{$key}->wsrep_status eq 4
               && $nodes->{$key}->wsrep_rejectqueries eq "NONE"
               && $nodes->{$key}->cluster_status eq "Primary"
               && $nodes->{$key}->hostgroups >= 9000
               ){
                 $action_nodes->{$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_MOVE_UP_HG_CHANGE}}= $nodes->{$key};
                 #if retry is > 0 then it's managed
                 if($proxynode->retry_up > 0){
                     $nodes->{$key}->get_retry_up($nodes->{$key}->get_retry_up +1);
                 }
                 if($proxynode->debug >=1){
                    print Utils->print_log(3," Evaluate nodes state "
                       .$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_MOVE_UP_HG_CHANGE}
                       ." Retry #".$nodes->{$key}->get_retry_up."\n" ) }			    
                 next;
            }
   
           #Special case when a node goes down it goes through several state and the check disable it moving form original group
           #This is to remove it to his original HG when is not reachable
           if($nodes->{$key}->{_process_status} < 0 
              && $nodes->{$key}->hostgroups >= 9000
             ){
                 #if retry is > 0 then it's managed
                 if($proxynode->retry_up > 0){
                     $nodes->{$key}->get_retry_up($nodes->{$key}->get_retry_up +1);
                 }
              
                 $action_nodes->{$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_MOVE_UP_HG_CHANGE}}= $nodes->{$key};
                 if($proxynode->debug >=1){
                    print Utils->print_log(3," Evaluate nodes state "
                       .$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_MOVE_UP_HG_CHANGE}
                       ." Retry #".$nodes->{$key}->get_retry_up."\n" ) }			    
                 next;
           }
           
           #Check if any node that is in the read backup host group is not present in the readhostgroup while it should.
           #If identify it will add to the read HG
           
           if($nodes->{$key}->wsrep_status eq 4
               && $nodes->{$key}->wsrep_rejectqueries eq "NONE"
               && $nodes->{$key}->cluster_status eq "Primary"
               && $nodes->{$key}->hostgroups == (8000 + $proxynode->{_hg_reader_id})
               ){
                 my $nodes_read_ips = join(',', @{$GGalera_cluster->{_reader_nodes}});
                 my $nodes_write_ips = join(',', @{$GGalera_cluster->{_writer_nodes}});
                 
                 my $ip = "$nodes->{$key}->{_ip}:$nodes->{$key}->{_port}";
                 
                 if($nodes_read_ips =~ m/$ip/
                    || ( $nodes_write_ips =~ m/$ip/ 
                        && $GGalera_cluster->{_writer_is_reader} < 1)){
                  if($proxynode->debug >=1){
                    print Utils->print_log(3," Node already ONLINE in read hg "
                       .$nodes->{$key}->ip.";".$nodes->{$key}->port.";\n" ) }			 
                 }else{
                    $action_nodes->{$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_INSERT_READ}}= $nodes->{$key}; 
                    #if retry is > 0 then it's managed
                    if($proxynode->retry_up > 0){
                        $nodes->{$key}->get_retry_up($nodes->{$key}->get_retry_up +1);
                    }
                    if($proxynode->debug >=1){
                       print Utils->print_log(3," Evaluate nodes state "
                          .$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_INSERT_READ}
                          ." Retry #".$nodes->{$key}->get_retry_up."\n" )
                    }
                 }
                 next;
            }

           #Check if any node that is in the write backup host group is not present in the WRITE hostgroup while it should WHEN MULTIPLE WRITERS.
           #If identify it will add to the read HG
           
           if($nodes->{$key}->wsrep_status eq 4
               && $nodes->{$key}->wsrep_rejectqueries eq "NONE"
               && $nodes->{$key}->read_only eq "OFF"
               && $nodes->{$key}->cluster_status eq "Primary"
               && $nodes->{$key}->hostgroups == (8000 + $proxynode->{_hg_writer_id})
               && $GGalera_cluster->{_singlewriter} < 1
               ){
                 #my $nodes_read_ips = join(',', @{$GGalera_cluster->{_reader_nodes}});
                 my $nodes_write_ips = join(',', @{$GGalera_cluster->{_writer_nodes}});
                 
                 my $ip = "$nodes->{$key}->{_ip}:$nodes->{$key}->{_port}";
                 
                 if($nodes_write_ips =~ m/$ip/ 
                     && $GGalera_cluster->{_single_writer} < 1){
                  if($proxynode->debug >=1){
                    print Utils->print_log(3," Node already ONLINE in write hg "
                       .$nodes->{$key}->ip.";".$nodes->{$key}->port.";\n" ) }			 
                 }else{
                    $action_nodes->{$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_INSERT_WRITE}}= $nodes->{$key}; 
                    #if retry is > 0 then it's managed
                    if($proxynode->retry_up > 0){
                        $nodes->{$key}->get_retry_up($nodes->{$key}->get_retry_up +1);
                    }
                    if($proxynode->debug >=1){
                       print Utils->print_log(3," Evaluate nodes state "
                          .$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_INSERT_WRITE}
                          ." Retry #".$nodes->{$key}->get_retry_up."\n" )
                    }
                 }
                 next;
            }
           
           
           # in the case node is not in one of the declared state
           # BUT it has the counter retry set THEN I reset it to 0 whatever it was because
           # I assume it is ok now
           if($proxynode->retry_up > 0
              && $nodes->{$key}->get_retry_up > 0){
               $nodes->{$key}->get_retry_up(0);
               $action_nodes->{$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_SAVE_RETRY}}= $nodes->{$key};
           }
           if($proxynode->retry_down > 0
              && $nodes->{$key}->get_retry_down > 0){
               $nodes->{$key}->get_retry_down(0);
               $action_nodes->{$nodes->{$key}->ip.";".$nodes->{$key}->port.";".$nodes->{$key}->hostgroups.";".$nodes->{$key}->{_SAVE_RETRY}}= $nodes->{$key};
           }
		
         }
       }
       $proxynode->action_nodes($action_nodes);
       
      #failover has higher priority BUT if it happens before other action will interfere with recovery and move nodes that may prevent the failover to happen
      # and it will ends the script work (if successful)
      #if($GGalera_cluster->{_writers} > 1
      #   && $GGalera_cluster->{_singlewriter} > 0)
      #{
      #  $proxynode->{_require_failover} = 1;
      #}
      
      
      
      if($proxynode->require_failover > 0
         && !defined $action_nodes
         ){
        if($GGalera_cluster->haswriter < 1
           || ( $GGalera_cluster->{_writers} > 1 && $GGalera_cluster->{_singlewriter} > 0)
           ){
          print Utils->print_log(2,"Fail-over in action Using Method = $proxynode->{_require_failover}\n" );
          if($proxynode->initiate_failover($GGalera_cluster) >0){
             #if($proxynode->debug >=1){
               print Utils->print_log(2,"!!!! FAILOVER !!!!! \n Cluster was without WRITER I have try to restore service promoting a node\n" );
               #exit 0;
             #}
          }
        }
      }
      elsif($proxynode->require_failover > 0
            && $GGalera_cluster->haswriter < 1){
       print Utils->print_log(2,"PXC maintenance on single writer, is asking for failover. Fail-over in action Using Method = $proxynode->{_require_failover}\n" );
       $proxynode->push_changes;
       if($proxynode->initiate_failover($GGalera_cluster) >0){
             #if($proxynode->debug >=1){
               print Utils->print_log(2,"!!!! FAILOVER !!!!! \n Cluster was without WRITER I have try to restore service promoting a node\n" );
               #exit 0;
             #}
        }
      }

    }
    
    sub push_changes{
        my ($proxynode)  = @_ ;
        my $node = GaleraNode->new();
        my $SQL_command="";
        
        
        foreach my $key (sort keys %{$proxynode->{_action_nodes}}){
            my ($host,  $port, $hg, $action) = split /s*;\s*/, $key;
           
            SWITCH: {
                     if ($action == $node->MOVE_DOWN_OFFLINE) { if($proxynode->{_action_nodes}->{$key}->get_retry_down >= $proxynode->retry_down){$proxynode->move_node_offline($key,$proxynode->{_action_nodes}->{$key})}; last SWITCH; }
                     if ($action == $node->MOVE_DOWN_HG_CHANGE) { if($proxynode->{_action_nodes}->{$key}->get_retry_down >= $proxynode->retry_down){ $proxynode->move_node_down_hg_change($key,$proxynode->{_action_nodes}->{$key})}; last SWITCH; }
                     if ($action == $node->MOVE_UP_OFFLINE) { if($proxynode->{_action_nodes}->{$key}->get_retry_up >= $proxynode->retry_up){ $proxynode->move_node_up_from_offline($key,$proxynode->{_action_nodes}->{$key})}; last SWITCH; }
                     if ($action == $node->MOVE_UP_HG_CHANGE) { if($proxynode->{_action_nodes}->{$key}->get_retry_up >= $proxynode->retry_up){$proxynode->move_node_up_from_hg_change($key,$proxynode->{_action_nodes}->{$key})}; last SWITCH; }
                     if ($action == $node->MOVE_TO_MAINTENANCE) { if($proxynode->{_action_nodes}->{$key}->get_retry_down >= $proxynode->retry_down){$proxynode->move_node_to_maintenance($key,$proxynode->{_action_nodes}->{$key})}; last SWITCH; }
                     if ($action == $node->DELETE_NODE) {
                         if($proxynode->{_action_nodes}->{$key}->get_retry_up >= $proxynode->retry_up){
                          $proxynode->delete_node_from_hostgroup($key,$proxynode->{_action_nodes}->{$key})}; last SWITCH; }
                     if($action == $node->INSERT_READ){if($proxynode->{_action_nodes}->{$key}->get_retry_up >= $proxynode->retry_up){
                          $proxynode->insert_reader($key,$proxynode->{_action_nodes}->{$key})
                          }; last SWITCH;                      
                     }
                                          
                     if($action == $node->INSERT_WRITE){if($proxynode->{_action_nodes}->{$key}->get_retry_up >= $proxynode->retry_up){
                          $proxynode->insert_writer($key,$proxynode->{_action_nodes}->{$key})
                          }; last SWITCH;                      
                     }

            }
            if($proxynode->retry_up > 0 || $proxynode->retry_down > 0){
               save_retry($proxynode,$key,$proxynode->{_action_nodes}->{$key});
            }      
        }   
        $proxynode->{_action_nodes} = undef;
    }
    
    sub save_retry{
        #this action will take place only if retry is active
        my ($self,$key,$node) = @_;
        my ($host,  $port, $hg,$action) = split /s*;\s*/, $key;
        
        if($self->debug >=1){print Utils->print_log(4,"Check retry Node:".$host." port:".$port . " hg:".$hg ." Time IN \n");}
       
        my $sql_string = "UPDATE mysql_servers SET comment='"
            .$node->{_comment}
            .$self->get_galera_cluster->cluster_identifier."_retry_up=".$node->get_retry_up
            .";".$self->get_galera_cluster->cluster_identifier."_retry_down=".$node->get_retry_down
            .";' WHERE hostgroup_id=$hg AND hostname='$host' AND port='$port'";
       
        $self->{_dbh_proxy}->do($sql_string) or die "Couldn't execute statement: " .  $self->{_dbh_proxy}->errstr;
        $self->{_dbh_proxy}->do("LOAD MYSQL SERVERS TO RUNTIME") or die "Couldn't execute statement: " .  $self->{_dbh_proxy}->errstr;
        
        if($self->debug >=1){print Utils->print_log(2," Reset retry to UP:".$node->get_retry_up." Down:".$node->get_retry_down."for node:" .$key
              ." SQL:" .$sql_string
              ."\n")}  ;			    
        if($self->debug >=1){print Utils->print_log(4,"Check retry Node:".$host." port:".$port . " hg:".$hg ." Time OUT \n");}
    }
 
    sub move_node_offline{
        #this action involve only the proxy so we will 
        my ($proxynode, $key,$node) = @_;
        
        my ($host,  $port, $hg,$action) = split /s*;\s*/, $key;
        my $proxy_sql_command= " UPDATE mysql_servers SET status='OFFLINE_SOFT' WHERE hostgroup_id=$hg AND hostname='$host' AND port='$port'";
        $proxynode->{_dbh_proxy}->do($proxy_sql_command) or die "Couldn't execute statement: " .  $proxynode->{_dbh_proxy}->errstr;
        $proxynode->{_dbh_proxy}->do("LOAD MYSQL SERVERS TO RUNTIME") or die "Couldn't execute statement: " .  $proxynode->{_dbh_proxy}->errstr;
        
        print Utils->print_log(2," Move node:" .$key
              ." SQL:" .$proxy_sql_command
              ."\n")  ;			    
    }
    sub move_node_to_maintenance{
        #this action involve only the proxy so we will 
        my ($proxynode, $key,$node) = @_;
        
        my ($host,  $port, $hg,$action) = split /s*;\s*/, $key;
        my $proxy_sql_command= " UPDATE mysql_servers SET status='OFFLINE_SOFT' WHERE hostgroup_id=$hg AND hostname='$host' AND port='$port'";
        $proxynode->{_dbh_proxy}->do($proxy_sql_command) or die "Couldn't execute statement: " .  $proxynode->{_dbh_proxy}->errstr;
        $proxynode->{_dbh_proxy}->do("LOAD MYSQL SERVERS TO RUNTIME") or die "Couldn't execute statement: " .  $proxynode->{_dbh_proxy}->errstr;
        
        print Utils->print_log(2," Move node:" .$key
              ." SQL:" .$proxy_sql_command
              ."\n")  ;			    
    }

    #remove a node from an hostgroup
    sub delete_node_from_hostgroup{
        #this action involve only the proxy so we will 
        my ($proxynode, $key,$node) = @_;
        
        my ($host,  $port, $hg,$action) = split /s*;\s*/, $key;
        my $proxy_sql_command= " DELETE from mysql_servers WHERE hostgroup_id=$hg AND hostname='$host' AND port='$port'";
        $proxynode->{_dbh_proxy}->do($proxy_sql_command) or die "Couldn't execute statement: " .  $proxynode->{_dbh_proxy}->errstr;
        $proxynode->{_dbh_proxy}->do("LOAD MYSQL SERVERS TO RUNTIME") or die "Couldn't execute statement: " .  $proxynode->{_dbh_proxy}->errstr;
        
        print Utils->print_log(2," DELETE node:" .$key
              ." SQL:" .$proxy_sql_command
              ."\n")  ;			    
    }




    #move a node to a maintenance HG ((9000 + HG id))
    sub move_node_down_hg_change{
        my ($proxynode, $key,$node) = @_;
        
        my ($host,  $port, $hg,$action) = split /s*;\s*/, $key;
        if($hg > 9000) {return 1;}
        
        my $node_sql_command = "SET GLOBAL READ_ONLY=1;";
        my $proxy_sql_command =" UPDATE mysql_servers SET hostgroup_id=".(9000 + $hg)." WHERE hostgroup_id=$hg AND hostname='$host' AND port='$port'";
        $proxynode->{_dbh_proxy}->do($proxy_sql_command) or die "Couldn't execute statement: " .  $proxynode->{_dbh_proxy}->errstr;
        $proxynode->{_dbh_proxy}->do("LOAD MYSQL SERVERS TO RUNTIME") or die "Couldn't execute statement: " .  $proxynode->{_dbh_proxy}->errstr;
        print Utils->print_log(2," Move node:" .$key
            ." SQL:" .$proxy_sql_command
            ."\n" );			    
    }

    #Bring back a node that is just offline
    sub move_node_up_from_offline{
        my ($proxynode, $key,$node) = @_;
        my ($host,  $port, $hg,$action) = split /s*;\s*/, $key;
        my $proxy_sql_command= " UPDATE mysql_servers SET status='ONLINE' WHERE hostgroup_id=$hg AND hostname='$host' AND port='$port'";
        $proxynode->{_dbh_proxy}->do($proxy_sql_command) or die "Couldn't execute statement: " .  $proxynode->{_dbh_proxy}->errstr;
        my $error_code = $proxynode->{_dbh_proxy}->err();
        $proxynode->{_dbh_proxy}->do("LOAD MYSQL SERVERS TO RUNTIME") or die "Couldn't execute statement: " .  $proxynode->{_dbh_proxy}->errstr;
        print Utils->print_log(2," Move node:" .$key
            ." SQL:" .$proxy_sql_command
            ."\n" );			    
    }

    #move a node back to his original HG ((HG id - 9000))
    sub move_node_up_from_hg_change{
        my ($proxynode, $key,$node) = @_;
        
        my ($host,  $port, $hg,$action) = split /s*;\s*/, $key;
        #my $node_sql_command = "SET GLOBAL READ_ONLY=1;";
        my $proxy_sql_command =" UPDATE mysql_servers SET hostgroup_id=".($hg - 9000)." WHERE hostgroup_id=$hg AND hostname='$host' AND port='$port'";
        $proxynode->{_dbh_proxy}->do($proxy_sql_command) or warn "Couldn't execute statement: " .  $proxynode->{_dbh_proxy}->errstr;
        my $error_code = $proxynode->{_dbh_proxy}->err();
        $proxynode->{_dbh_proxy}->do("LOAD MYSQL SERVERS TO RUNTIME") or die "Couldn't execute statement: " .  $proxynode->{_dbh_proxy}->errstr;
        print Utils->print_log(2," Move node:" .$key
            ." SQL:" .$proxy_sql_command
            ."\n" ) ;			    
    }
    
    #move a node back to his original HG ((HG id - 9000))
    sub add_node_to_readers{
        my ($proxynode, $key,$node) = @_;
        
        my ($host,  $port, $hg,$action) = split /s*;\s*/, $key;
        my $node_sql_command = "SET GLOBAL READ_ONLY=1;";
        my $proxy_sql_command =" UPDATE mysql_servers SET hostgroup_id=".($hg - 9000)." WHERE hostgroup_id=$hg AND hostname='$host' AND port='$port'";
        $proxynode->{_dbh_proxy}->do($proxy_sql_command) or die "Couldn't execute statement: " .  $proxynode->{_dbh_proxy}->errstr;
        my $error_code = $proxynode->{_dbh_proxy}->err();
        $proxynode->{_dbh_proxy}->do("LOAD MYSQL SERVERS TO RUNTIME") or die "Couldn't execute statement: " .  $proxynode->{_dbh_proxy}->errstr;
        print Utils->print_log(2," Move node:" .$key
            ." SQL:" .$proxy_sql_command
            ."\n" ) ;			    
    }

   sub insert_reader{
         my ($proxynode, $key,$node) = @_;
         my ($host,  $port, $hg,$action) = split /s*;\s*/, $key;
         my $proxy_sql_command ="INSERT INTO mysql_servers (hostgroup_id, hostname,port,gtid_port,status,weight,compression,max_connections,max_replication_lag,use_ssl,max_latency_ms,comment) ".
            " VALUES($proxynode->{_hg_reader_id}" .
            ",'$node->{_ip}'" .
            ",$node->{_port} " .
            ",$node->{_gtid_port} " .
            ",'$node->{_proxy_status}' " .
            ",$node->{_weight}" .
            ",$node->{_compression}" .
            ",$node->{_connections}" .
            ",$node->{_max_replication_lag}" .
            ",$node->{_use_ssl}" .
            ",$node->{_max_latency}" .
            ",'$node->{_comments}')" ;
            
         #my $proxy_sql_command =" UPDATE mysql_servers SET hostgroup_id=".($hg - 9000)." WHERE hostgroup_id=$hg AND hostname='$host' AND port='$port'";
         $proxynode->{_dbh_proxy}->do($proxy_sql_command) or warn "Couldn't execute statement: $proxy_sql_command" .  $proxynode->{_dbh_proxy}->errstr;
         my $error_code = $proxynode->{_dbh_proxy}->err();
         $proxynode->{_dbh_proxy}->do("LOAD MYSQL SERVERS TO RUNTIME") or warn "Couldn't execute statement: " .  $proxynode->{_dbh_proxy}->errstr;
         print Utils->print_log(2," Move node:" .$key
             ." SQL:" .$proxy_sql_command
             ."\n" ) ;			    
    }
   
     sub insert_writer{
         my ($proxynode, $key,$node) = @_;
         my ($host,  $port, $hg,$action) = split /s*;\s*/, $key;
         my $proxy_sql_command ="INSERT INTO mysql_servers (hostgroup_id, hostname,port,gtid_port,status,weight,compression,max_connections,max_replication_lag,use_ssl,max_latency_ms,comment) ".
            " VALUES($proxynode->{_hg_writer_id}" .
            ",'$node->{_ip}'" .
            ",$node->{_port} " .
            ",$node->{_gtid_port} " .
            ",'$node->{_proxy_status}' " .
            ",$node->{_weight}" .
            ",$node->{_compression}" .
            ",$node->{_connections}" .
            ",$node->{_max_replication_lag}" .
            ",$node->{_use_ssl}" .
            ",$node->{_max_latency}" .
            ",'$node->{_comments}')" ;
            
         #my $proxy_sql_command =" UPDATE mysql_servers SET hostgroup_id=".($hg - 9000)." WHERE hostgroup_id=$hg AND hostname='$host' AND port='$port'";
         $proxynode->{_dbh_proxy}->do($proxy_sql_command) or warn "Couldn't execute statement: $proxy_sql_command" .  $proxynode->{_dbh_proxy}->errstr;
         my $error_code = $proxynode->{_dbh_proxy}->err();
         $proxynode->{_dbh_proxy}->do("LOAD MYSQL SERVERS TO RUNTIME") or warn "Couldn't execute statement: " .  $proxynode->{_dbh_proxy}->errstr;
         print Utils->print_log(2," Move node:" .$key
             ." SQL:" .$proxy_sql_command
             ."\n" ) ;			    
    }
    sub initiate_failover{
        my ($proxynode,$Galera_cluster)  = @_ ;
        my ( $nodes ) = $Galera_cluster->{_nodes};
        my ( $nodes_maint ) = $Galera_cluster->{_nodes_maint};
        my $failover_node;
        my $candidate_failover_node;
        my $min_index = 100;
        my $max_weight=0;
        my $cand_min_index = 100;
        my $cand_max_weight=0;

        my $local_node;
        my $hg_writer_id=0;
        my $exclude_delete="";
        
        #Valid values are:
        #    0 [default] do not make failover
        #    1 make failover only if HG 8000 is specified in ProxySQL mysl_servers
        #    2 use PXC_CLUSTER_VIEW to identify a server in the same segment
        #    3 do whatever to keep service up also failover to another segment (use PXC_CLUSTER_VIEW) 
        #           
        foreach my $key (sort keys %{$nodes}){
          if(defined $nodes->{$key} ){
         
             #only if node has HG that is not maintenance it can be evaluated to be put down in some way
             #Look for the node with the lowest weight in the same segment
             if($nodes->{$key}->{_hostgroups} < 9000
                && $nodes->{$key}->{_proxy_status} eq "ONLINE"
                && $nodes->{$key}->{_process_status} > 0
                && $nodes->{$key}->{_wsrep_status} == 4
                && $nodes->{$key}->{_wsrep_rejectqueries} eq "NONE"
                && $nodes->{$key}->{_wsrep_donorrejectqueries} eq "OFF"
                && $nodes->{$key}->{_pxc_maint_mode} eq "DISABLED"
                && $nodes->{$key}->{_read_only} eq "OFF" 
                ){
              
              #IN case failover option is 1 we need to have:
              #The failover group defined in Proxysql (8xxx + id of the HG)
              #Node must be of HG 8XXXX id
              #And must be in the same segment of the writer 
                 if(
                    $proxynode->{_require_failover} == 1
                   # && $nodes->{$key}->{_wsrep_segment} == $Galera_cluster->{_main_segment}
                    && $Galera_cluster->{_has_failover_node} >0
                    && $nodes->{$key}->{_hostgroups} == (8000 + $Galera_cluster->{_hg_writer_id})
                    ){

                       if($nodes->{$key}->{_weight} > $max_weight
                          && $nodes->{$key}->{_wsrep_segment} == $Galera_cluster->{_main_segment}
                          ){
                          $max_weight= $nodes->{$key}->{_weight};
                          #$min_index =  $nodes->{$key}->{_wsrep_local_index};
                          $failover_node = $nodes->{$key};
                       }
                       elsif($nodes->{$key}->{_wsrep_segment} != $Galera_cluster->{_main_segment}
                          && !defined $failover_node
                          && $nodes->{$key}->{_weight} > $cand_max_weight){
                            $cand_max_weight= $nodes->{$key}->{_weight};
                           # $cand_min_index =  $nodes->{$key}->{_wsrep_local_index};
                            $candidate_failover_node = $nodes->{$key};
                       }

                       #if($nodes->{$key}->{_weight} > $max_weight){
                       #     $max_weight= $nodes->{$key}->{_weight};
                       #     $failover_node = $nodes->{$key};
                       #}
                 }
              #IN case failover option is 2 we need to have:
              # must be in the same segment of the writer
              #and be in the PXC_CLUSTER_VIEW

                 elsif(
                    $proxynode->{_require_failover} == 2
                    && $nodes->{$key}->{_wsrep_segment} == $Galera_cluster->{_main_segment}                  
                 ){
                      if($nodes->{$key}->{_wsrep_local_index} < $min_index
                         ){
                           $min_index =  $nodes->{$key}->{_wsrep_local_index};
                           $failover_node = $nodes->{$key};
                      }
                 }
                 elsif($proxynode->{_require_failover} == 3){
                       if($nodes->{$key}->{_wsrep_segment} == $Galera_cluster->{_main_segment}
                          && $nodes->{$key}->{_wsrep_local_index} < $min_index){
                          $min_index =  $nodes->{$key}->{_wsrep_local_index};
                          $failover_node = $nodes->{$key};
                       }
                       elsif($nodes->{$key}->{_wsrep_segment} != $Galera_cluster->{_main_segment}
                          && !defined $failover_node
                          && $nodes->{$key}->{_wsrep_local_index} < $cand_min_index){
                            $cand_min_index =  $nodes->{$key}->{_wsrep_local_index};
                            $candidate_failover_node = $nodes->{$key};
                       }
                 }
             }
          }
        }
        if(defined $nodes_maint ){
           my $exclude_id = "";
           my $exclude_port = "";
           foreach my $key (sort keys %{$nodes_maint}){
             if(defined $nodes_maint->{$key}){ 
                if(length($exclude_id) > 1){
                   $exclude_id = $exclude_id . ",";
                   $exclude_port = $exclude_port . ",";
                }
                   
                $exclude_id = $exclude_id ."'". $nodes_maint->{$key}->{_ip} ."'";
                $exclude_port = $exclude_port.$nodes_maint->{$key}->{_port} ;
             }
           }
           if(length($exclude_id) > 1){
              $exclude_delete = $exclude_delete . " AND (hostname not in (".$exclude_id.") AND port not in (".$exclude_port."))" ;
           }
        }
        
        #if a node was found, try to do the failover removing the READ_ONLY
        if(defined $candidate_failover_node && $failover_node){
            return $failover_node->promote_writer($proxynode,$Galera_cluster,$exclude_delete);
        }
        elsif(defined $candidate_failover_node && !defined $failover_node){
            return $candidate_failover_node->promote_writer($proxynode,$Galera_cluster,$exclude_delete);
        }
        else{
            if(!defined $failover_node){
                SWITCH: {
                  if ($proxynode->{_require_failover} == 1) { print Utils->print_log(1,"!!!! No node for failover found , try to use active_failover=2 OR add a valid node to the 8000 HG pool \n" ) ; last SWITCH; }
                  if ($proxynode->{_require_failover} == 2) { print Utils->print_log(1,"!!!! No node for failover found , try to use active_failover=3 But that may move production to the other segment.\n" ); last SWITCH; }
                  if ($proxynode->{_require_failover} == 3) { print Utils->print_log(1,"!!!! No node for failover found also in the other segments, I cannot continue you need to act manually \n" ); last SWITCH; }
                }
            }
         
            if(defined $failover_node){
               return $failover_node->promote_writer($proxynode,$Galera_cluster,$exclude_delete);
            }
        }
       
        
        return 0;
    }

}

{
    package ProxySqlHG;
    sub new {
        my $class = shift;
        
        my $self = {
            _id  => undef, # 
            _type  => undef, # available types: w writer; r reader ; mw maintance writer; mr maintenance reader
            _size => 0,
        };
        bless $self, $class;
        return $self;
    }
    
    sub id {
        my ( $self, $id ) = @_;
        $self->{_id} = $id if defined($id);
        return $self->{_id};
    }

    sub type {
        my ( $self, $type ) = @_;
        $self->{_type} = $type if defined($type);
        return $self->{_type};
    }
    sub size {
        my ( $self, $size ) = @_;
        $self->{_size} = $size if defined($size);
        return $self->{_size};
    }

}

{
    package Utils;
    use Time::HiRes qw(gettimeofday);
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
      my $dbh = DBI->connect($dsn, $user, $pass ,  {
        PrintError => 0,
        PrintWarn  => 0,
        RaiseError => 0});
      
      if (!defined($dbh)) {
        #die
        print Utils->print_log(1, "Cannot connect to $dsn as $user\n");
        # Should not die and instead return undef so we can handle this shit 
        #die();
        return undef;
      }
      
      return $dbh;
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
      $sth->execute() or warn "Couldn't execute statement: $cmd" .  $dbh->errstr ." \n";
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
      my $cmd = "select * from performance_schema.global_variables";
      $dbh->{LongReadLen} = 0;
      $dbh->{LongTruncOk} = 0;
      
      my $sth = $dbh->prepare($cmd);
      $sth->execute() or warn "Couldn't execute statement: $cmd" .  $dbh->errstr ." \n";
      while (my $ref = $sth->fetchrow_hashref()) {
        my $n = $ref->{'VARIABLE_NAME'};
        $v{"\L$n\E"} = $ref->{'VARIABLE_VALUE'};
        # print STDERR "$n  :  ".$v{$n}. " ZZZZZZZZZZZZZZZZZZ ". $ref->{'Value'} ."\n";
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
        $sth->execute() or warn "Couldn't execute statement: $cmd" .  $dbh->errstr ." \n";
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
    sub get_pxc_clusterview($$) {
        my $dbh = shift;
        my $variableName = shift;
        #my $debug = shift;
       
        my %v;
        my $cmd = "select * from performance_schema.pxc_cluster_view where UUID = '$variableName'";
      
        my $sth = $dbh->prepare($cmd);
        $sth->execute() or warn "Couldn't execute statement: $cmd" .  $dbh->errstr ." \n";
      my $ref;  
      while ( $ref = $sth->fetchrow_hashref()) {
          foreach my $name ('HOST_NAME', 'UUID','STATUS','LOCAL_INDEX','SEGMENT'){  
               my $n = lc $name;
              $v{$n} = $ref->{$name};
          }
        }        
        return \%v;
    }    
    #Print time from invocation with milliseconds
    sub get_current_time{
        use POSIX qw(strftime);
        my $t = gettimeofday();
        my $date = strftime "%Y/%m/%d %H:%M:%S", localtime $t;
        $date .= sprintf ".%03d", ($t-int($t))*1000; # without rounding
        
        return $date;
    }

    #prit all environmnt variables    
    sub debugEnv{
        my $key = keys %ENV;
        foreach $key (sort(keys %ENV)) {
           print $key, '=', $ENV{$key}, "\n";
        }
    
    }
    
    
    #Print a log entry
    sub print_log($$){
        my $log_level = $_[1];
        my $text = $_[2];
        my $log_text = "[ - ] ";
	
        SWITCH: {
              if ($log_level == 1) { $log_text= "[ERROR] "; last SWITCH; }
              if ($log_level == 2) { $log_text= "[WARN] "; last SWITCH; }
              if ($log_level == 3) { $log_text= "[INFO] "; last SWITCH; }
              if ($log_level == 4) { $log_text= "[DEBUG] "; last SWITCH; }
       }
       return Utils::get_current_time.":".$log_text.$text;
	
    }
    
    
    #trim a string
    sub  trim {
        my $s = shift;
        $s =~ s/^\s+|\s+$//g;
        return $s
    };


}


# ############################################################################
# Documentation
# #################
=pod

=head1 NAME
galera_check.pl

=head1 OPTIONS

=over

galera_check.pl -u=admin -p=admin -h=192.168.1.50 -H=500:W,501:R -P=3310 --main_segment=1 --debug=0  --log <full_path_to_file> --help
sample [options] [file ...]
 Options:
   -u|user            user to connect to the proxy
   -p|password        Password for the proxy
   -h|host            Proxy host
   -H                 Hostgroups with role definition. List comma separated.
		      Definition R = reader; W = writer [500:W,501:R]
   --main_segment     If segments are in use which one is the leading at the moment
   --retry_up         The number of loop/test the check has to do before moving a node up (default 0)
   --retry_down       The number of loop/test the check has to do before moving a node Down (default 0)
   --log	      Full path to the log file ie (/var/log/proxysql/galera_check_) the check will add
		      the identifier for the specific HG.
   --active_failover  A value from 0 to 3, indicating what level/kind of fail-over the script must perform.
                       active_failover
                       Valid values are:
                          0 [default] do not make failover
                          1 make failover only if HG 8000 is specified in ProxySQL mysl_servers
                          2 use PXC_CLUSTER_VIEW to identify a server in the same segment
                          3 do whatever to keep service up also failover to another segment (use PXC_CLUSTER_VIEW)
   --single_writer    Active by default [single_writer = 1 ] if disable will allow to have multiple writers       
   
   
   Performance parameters 
   --check_timeout    This parameter set in ms then time the script can alow a thread connecting to a MySQL node to wait, before forcing a returnn.
                      In short if a node will take longer then check_timeout its entry will be not filled and it will eventually ignored in the evaluation.
                      Setting the debug option  =1 and look for [WARN] Check timeout Node ip : Information will tell you how much your nodes are exceeding the allowed limit.
                      You can use the difference to correctly set the check_timeout 
                      Default is 800 ms
   
   --help              help message
   --debug             When active the log will have a lot of information about the execution. Parse it for ERRORS if you have problems
   --print_execution   Active by default, it will print the execution time the check is taking in the log. This can be used to tune properly the scheduler time, and also the --check_timeout
   
   --development      When set to 1 you can run the script in a loop from bash directly and test what is going to happen
   --development_time Time in seconds that the loop wait to execute when in development mode (default 2 seconds)

=back    
   
=head1 DESCRIPTION

Galera check is a script to manage integration between ProxySQL and Galera (from Codership).
Galera and its implementations like Percona Cluster (PCX), use the data-centric concept, as such the status of a node is relvant in relation to a cluster.

In ProxySQL is possible to represent a cluster and its segments using HostGroups.
Galera check is design to manage a X number of nodes that belong to a given Hostgroup (HG). 
In Galera_check it is also important to qualify the HG in case of use of Replication HG.

galera_check works by HG and as such it will perform isolated actions/checks by HG. 
It is not possible to have more than one check running on the same HG. The check will create a lock file {proxysql_galera_check_${hg}.pid} that will be used by the check to prevent duplicates.

Galera_check will connect to the ProxySQL node and retrieve all the information regarding the Nodes/proxysql configuration. 
It will then check in parallel each node and will retrieve the status and configuration.

At the moment galera_check analyze and manage the following:

Node states: 
  read_only 
  wsrep_status 
  wsrep_rejectqueries 
  wsrep_donorrejectqueries 
  wsrep_connected 
  wsrep_desinccount 
  wsrep_ready 
  wsrep_provider 
  wsrep_segment 
  Number of nodes in by segment
  Retry loop
  
- Number of nodes in by segment
If a node is the only one in a segment, the check will behave accordingly. 
IE if a node is the only one in the MAIN segment, it will not put the node in OFFLINE_SOFT when the node become donor to prevent the cluster to become unavailable for the applications. 
As mention is possible to declare a segment as MAIN, quite useful when managing prod and DR site.

-The check can be configure to perform retry in a X interval. 
Where X is the time define in the ProxySQL scheduler. 
As such if the check is set to have 2 retry for UP and 4 for down, it will loop that number before doing anything. Given that Galera does some action behind the hood.
This feature is very useful in some not well known cases where Galera bhave weird.
IE whenever a node is set to READ_ONLY=1, galera desync and resync the node. 
A check not taking this into account will cause a node to be set OFFLINE and back for no reason.

Another important differentiation for this check is that it use special HGs for maintenance, all in range of 9000. 
So if a node belong to HG 10 and the check needs to put it in maintenance mode, the node will be moved to HG 9010. 
Once all is normal again, the Node will be put back on his original HG.

This check does NOT modify any state of the Nodes. 
Meaning It will NOT modify any variables or settings in the original node. It will ONLY change states in ProxySQL. 
    
The check is still a prototype and is not suppose to go to production (yet).


=over

=item 1

Note that galera_check is also Segment aware, as such the checks on the presence of Writer /reader is done by segment, respecting the MainSegment as primary.

=back

=head1 Configure in ProxySQL


INSERT  INTO scheduler (id,active,interval_ms,filename,arg1) values (10,0,2000,"/var/lib/proxysql/galera_check.pl","-u=remoteUser -p=remotePW -h=192.168.1.50 -H=500:W,501:R -P=6032 --retry_down=2 --retry_up=1 --main_segment=1 --debug=0 --active_failover=1 --single_writer=1 --log=/var/lib/proxysql/galeraLog");
LOAD SCHEDULER TO RUNTIME;SAVE SCHEDULER TO DISK;

To activate it
update scheduler set active=1 where id=10;
LOAD SCHEDULER TO RUNTIME;SAVE SCHEDULER TO DISK;

To update the parameters you must pass all of them not only the ones you want to change(IE enabling debug)
update scheduler set arg1="-u=remoteUser -p=remotePW -h=192.168.1.50 -H=500:W,501:R -P=6032 --retry_down=2 --retry_up=1 --main_segment=1 --debug=1 --active_failover=1 --single_writer=1 --log=/var/lib/proxysql/galeraLog" where id =10;  
LOAD SCHEDULER TO RUNTIME;SAVE SCHEDULER TO DISK;


delete from scheduler where id=10;
LOAD SCHEDULER TO RUNTIME;SAVE SCHEDULER TO DISK;



=head1 Rules:

=over

=item 1

Set to offline_soft :
    
    any non 4 or 2 state, read only =ON
    donor node reject queries - 0 size of cluster > 2 of nodes in the same segments more then one writer, node is NOT read_only.
    
    Changes to pxc_maint_mode to anything else DISABLED

=item 2

change HG t maintenance HG:
    
    Node/cluster in non primary
    wsrep_reject_queries different from NONE
    Donor, node reject queries =1 size of cluster 

=item 3

Node comes back from offline_soft when (all of them):

     1) Node state is 4
     3) wsrep_reject_queries = none
     4) Primary state


=item 4

 Node comes back from maintenance HG when (all of them):

     1) node state is 4
     3) wsrep_reject_queries = none
     4) Primary state


=item 5

 active_failover
      Valid values are:
          0 [default] do not make failover
          1 make failover only if HG 8000 is specified in ProxySQL mysl_servers
          2 use PXC_CLUSTER_VIEW to identify a server in the same segment
          3 do whatever to keep service up also failover to another segment (use PXC_CLUSTER_VIEW) 

=item 6
 PXC_MAIN_MODE is fully supported.
 Any node in a state different from pxc_maint_mode=disabled will be set in OFFLINE_SOFT for all the HostGroup.
 
=item 7
 internally shunning node.
 While I am trying to rely as much as possible on ProxySQL, given few inefficiencies there are cases when I have to set a node to SHUNNED because ProxySQL doesn't recognize it correctly.  
          
=back
=cut	


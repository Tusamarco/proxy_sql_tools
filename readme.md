Galera check is a script to manage integration between ProxySQL and Galera (from Codership).
Galera and its implementations like Percona Cluster (PCX), use the data-centric concept, as such the status of a node is relvant in relation to a cluster.

In ProxySQL is possible to represent a cluster and its segments using HostGroups.
Galera check is design to manage a X number of nodes that belong to a given Hostgroup (HG).
In Galera_ceck it is also important to qualify the HG in case of use of Replication HG.

galera_check works by HG and as such it will perform isolated actions/checks by HG.
It is not possible ot have more than one check running on the same HG.
The check will create a lock file {proxysql_galera_check_${hg}.pid} that will be used by the check to prevent duplicates.

Galera_check will connect to the ProxySQL node and retrieve all the information regarding the Nodes/proxysql configuration.
It will then check in parallel each node and will retrieve the status and configuration.

At the moment galera_check analyze and manage the following:
 - Node states:
    read_only
    wsrep_status
    wsrep_rejectqueries
    wsrep_donorrejectqueries
    wsrep_connected
    wsrep_desinccount
    wsrep_ready
    wsrep_provider
    wsrep_segment
    wsrep_pc_weight

- Number of nodes in by segment
  If a node is the only one in a segment, the check will behave accordingly. 
  IE if a node is the only one in the MAIN segment, it will not put the node in OFFLINE_SOFT when the node become donor to prevent the cluster to become unavailable for the applications.
  As mention is possible to declare a segment as MAIN, quite useful when managing prod and DR site.
  
- The check can be configure to perform retry in a X interval. Where X is the time define in the ProxySQL scheduler.
  As such if the check is set to have 2 retry for UP and 4 for down, it will loop that number before doing anything.
  Given that Galera does some action behind the hood, this feature is very useful.
  (IE whenever a node is set to READ_ONLY=1, galera desync and resync the node. A check not taking this into account will cause a node to be set OFFLINE and back for no reason.)
  
Another important differentiation for this check is that it use special HGs for maintenance, all in range of 9000.
So if a node belong to HG 10 and the check needs to put it in maintenance mode, the node will be moved to HG 9010. 
Once all is normal again, the Node will be put back on his original HG.

This check does NOT modify any state of the Nodes. Meaning It will NOT modify any variables or settings in the original node.
It will ONLY change states in ProxySQL.  
    
The check is still a prototype and is not suppose to go to production (yet).

More details

How to use it
galera_check.pl -u=admin -p=admin -h=192.168.1.50 -H=500:W,501:R -P=3310 --main_segment=1 --debug=0  --log <full_path_to_file> --help
sample [options] [file ...]
 Options:
   -u|user         user to connect to the proxy
   -p|password     Password for the proxy
   -h|host         Proxy host
   -H              Hostgroups with role definition. List comma separated.
		    Definition R = reader; W = writer [500:W,501:R]
   --main_segment  If segments are in use which one is the leading at the moment
   --retry_up      The number of loop/test the check has to do before moving a node up (default 0)
   --retry_down    The number of loop/test the check has to do before moving a node Down (default 0)
   --debug
   --log	  Full path to the log file ie (/var/log/proxysql/galera_check_) the check will add
		    the identifier for the specific HG.
   -help          help message
   

Note that galera_check is also Segment aware, as such the checks on the presence of Writer /reader is done by segment, respecting the MainSegment as primary.


Configure in ProxySQL


INSERT  INTO scheduler (id,interval_ms,filename,arg1) values (10,2000,"/var/lib/proxysql/galera_check.pl","-u=admin -p=admin -h=192.168.1.50 -H=500:W,501:R -P=3310 --retry_down=2 --retry_up=1 --main_segment=1 --debug=0  --log=/var/lib/proxysql/galeraLog");
LOAD SCHEDULER TO RUNTIME;SAVE SCHEDULER TO DISK;
  
update scheduler set arg1="-u=admin -p=admin -h=192.168.1.50 -H=500:W,501:R -P=3310 --main_segment=1 --debug=1  --log=/var/lib/proxysql/galeraLog" where id =10;  
LOAD SCHEDULER TO RUNTIME;SAVE SCHEDULER TO DISK;


delete from scheduler where id=10;
LOAD SCHEDULER TO RUNTIME;SAVE SCHEDULER TO DISK;

Logic Rules use in the check:

Set to offline_soft :
    
    any non 4 or 2 state, read only =ON
    donor node reject queries - 0 size of cluster > 2 of nodes in the same segments more then one writer, node is NOT read_only


change HG for maintenance HG:
    
    Node/cluster in non primary
    wsrep_reject_queries different from NONE
    Donor, node reject queries =1 size of cluster 


Node comes back from offline_soft when (all of them):

     1) Node state is 4
     3) wsrep_reject_queries = none
     4) Primary state


Node comes back from maintenance HG when (all of them):

     1) node state is 4
     3) wsrep_reject_queries = none
     4) Primary state
     
     
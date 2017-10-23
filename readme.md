Galera check is a script to manage integration between ProxySQL and Galera (from Codership), including its different implementations like PXC.
Galera and its implementations like Percona Cluster (PCX), use the data-centric concept, as such the status of a node is relvant in relation to a cluster.

In ProxySQL is possible to represent a cluster and its segments using HostGroups.
Galera check is design to manage a X number of nodes that belong to a given Hostgroup (HG).
In Galera_ceck it is also important to qualify the HG. This is true in case of multi-node like PXC or in case of use of Replication HG.

Galera_check can now also manage single writer in PXC and fail-over when in the need to.
This is implemented using two new features:
 * Backup Node definition (using hostgroup)
 * Use PXC_CLUSTER_VIEW table (in PXC only)

Galera_check works by HG and as such it will perform isolated actions/checks by HG.
It is not possible to have more than one check running on the same HG.

To prevent to have multiple test running , the check create a lock file {proxysql_galera_check_${hg}.pid} that will be used by the check to prevent duplicates.
Galera_check will connect to the ProxySQL node and retrieve all the information regarding the Nodes/proxysql configuration. 
It will then check in *parallel* each node and will retrieve the status and configuration.

At the moment galera_check analyze and manage the following:

Node states: 
 * read_only 
 * wsrep_status 
 * wsrep_rejectqueries 
 * wsrep_donorrejectqueries 
 * wsrep_connected 
 * wsrep_desinccount 
 * wsrep_ready 
 * wsrep_provider 
 * wsrep_segment 
 * Number of nodes in by segment
 * Retry loop 

PXC cluster state:
 * PXC_CLUSTER_VIEW
 
Fail-over options:
 * Presence of active node in the special backup Hostgroup (8000 + original HG id).

If a node is the only one in a segment, the check will behave accordingly. 
IE if a node is the only one in the MAIN segment, it will not put the node in OFFLINE_SOFT when the node become donor to prevent the cluster to become unavailable for the applications. 
As mention is possible to declare a segment as MAIN, quite useful when managing prod and DR site.

The check can be configure to perform retry in a X interval. 
Where X is the time define in the ProxySQL scheduler. 
As such if the check is set to have 2 retry for UP and 4 for down, it will loop that number before doing anything. Given that Galera does some action behind the hood.

This feature is very useful in some not well known cases where Galera behave weird.
IE whenever a node is set to READ_ONLY=1, galera desync and resync the node. 
A check not taking this into account will cause a node to be set OFFLINE and back for no reason.

Another important differentiation for this check is that it use special HGs for maintenance, all in range of 9000. 
So if a node belong to HG 10 and the check needs to put it in maintenance mode, the node will be moved to HG 9010. 
Once all is normal again, the Node will be put back on his original HG.

This check does NOT modify any state of the Nodes. 
Meaning It will NOT modify any variables or settings in the original node. It will ONLY change states in ProxySQL. 

Multi PXC node and Single writer.
ProxySQL can easily move traffic read or write from a node to another in case of a node failure. Normally playing with the weight will allow us to have a (stable enough) scenario.
But this will not guarantee the FULL 100% isolation in case of the need to have single writer.
When  there is that need, using only the weight will not be enough given ProxySQL will direct some writes also to the other nodes, few indeed, but still some of them, as such no 100% isolated.

To manage that and also to provide a good way to set/define what and how to fail-over in case of need, I had implement a new feature:
*active_failover*
    Valid values are:
          0 [default] do not make fail-over
          1 make fail-over only if HG 8000 is specified in ProxySQL mysl_servers
          2 use PXC_CLUSTER_VIEW to identify a server in the same segment
          3 do whatever to keep service up also fail-over to another segment (use PXC_CLUSTER_VIEW) 

Active fail-over works using two main features, the Backup Host Group and the information present in the new table performance_schema.pxc_cluster_view (PXC 5.7.19 and later).
For example:
```SQL
INSERT INTO mysql_servers (hostname,hostgroup_id,port,weight,max_connections) VALUES ('192.168.1.205',50,3306,1000000,2000);

INSERT INTO mysql_servers (hostname,hostgroup_id,port,weight,max_connections) VALUES ('192.168.1.205',8050,3306,1000000,2000);
INSERT INTO mysql_servers (hostname,hostgroup_id,port,weight,max_connections) VALUES ('192.168.1.231',8050,3306,100000,2000);
INSERT INTO mysql_servers (hostname,hostgroup_id,port,weight,max_connections) VALUES ('192.168.1.22',8050,3306,100000,2000);


INSERT INTO mysql_servers (hostname,hostgroup_id,port,weight,max_connections) VALUES ('192.168.1.205',52,3306,1,2000);
INSERT INTO mysql_servers (hostname,hostgroup_id,port,weight,max_connections) VALUES ('192.168.1.21',52,3306,1000000,2000);
INSERT INTO mysql_servers (hostname,hostgroup_id,port,weight,max_connections) VALUES ('192.168.1.231',52,3306,1,2000);

INSERT INTO mysql_servers (hostname,hostgroup_id,port,weight,max_connections) VALUES ('192.168.1.22',50,3306,1,2000);
INSERT INTO mysql_servers (hostname,hostgroup_id,port,weight,max_connections) VALUES ('192.168.1.23',50,3306,1,2000);
INSERT INTO mysql_servers (hostname,hostgroup_id,port,weight,max_connections) VALUES ('192.168.1.233',50,3306,1,2000);

INSERT INTO mysql_servers (hostname,hostgroup_id,port,weight,max_connections) VALUES ('192.168.1.22',52,3306,1,2000);
INSERT INTO mysql_servers (hostname,hostgroup_id,port,weight,max_connections) VALUES ('192.168.1.23',52,3306,1,2000);
INSERT INTO mysql_servers (hostname,hostgroup_id,port,weight,max_connections) VALUES ('192.168.1.233',52,3306,10,2000);

```
Will create entries in ProxySQL for 2 main HG (50 for write and 52 for read)
But it will also create 3 entries for the SPECIAL group 8050. This group will be used by the script to manage the fail-over of HG 50.

In the above example, what will happen is that in case of you have set `*active_failover*=1`, the script will check the nodes, if node `192.168.1.205',50` is not up,
the script will try to identify another node within the same segment that has the higest weight IN THE 8050 HG. In this case it will elect as new writer the node`'192.168.1.231',8050`.

If instead the `*active_failover*`=2, the script will use the pxc_cluster_view:
```SQL
pxc_test@192.168.1.205) [performance_schema]>select * from pxc_cluster_view order by SEGMENT,LOCAL_INDEX;
+-----------+--------------------------------------+--------+-------------+---------+
| HOST_NAME | UUID                                 | STATUS | LOCAL_INDEX | SEGMENT |
+-----------+--------------------------------------+--------+-------------+---------+
| node2     | 63870cc3-af5d-11e7-a0db-463be8426737 | SYNCED |           0 |       1 |
| node3     | 666ad5a0-af5d-11e7-9b39-2726e5de8eb1 | SYNCED |           1 |       1 |
| node1     | f3e45392-af5b-11e7-854e-9b29cd1909da | SYNCED |           5 |       1 |
| node6     | 7540bdca-b267-11e7-bae9-464c3d263470 | SYNCED |           2 |       2 |
| node5     | ab551483-b267-11e7-a1a1-9be1826f877f | SYNCED |           3 |       2 |
| node4     | e24ebd01-af5d-11e7-86f0-42c8ceb6886c | SYNCED |           4 |       2 |
+-----------+--------------------------------------+--------+-------------+---------+

```
This is an objective reference to the current active view define by galera. The local index is the `wsrep_local_index`, and will be used in selecting the new writer.
In this case, assuming `node2` was the current writer, the next one will be `node3`, given is the one with the lower index. This election will happen ONLY if the node is in the same segment.

Finally if `*active_failover*`=3, the script will use the pxc_cluster_view but will not limit its selection to the main segment, but in this case if NO node will be found in the main segment,
it will check and eventually elect as writer a node in the remote segment. This is a very extream situation, and if you decide to go for it, you need to be sure your production will work correctly.

```SQL
(pxc_test@192.168.1.205) [performance_schema]>select * from pxc_cluster_view order by SEGMENT,LOCAL_INDEX;
+-----------+--------------------------------------+--------+-------------+---------+
| HOST_NAME | UUID                                 | STATUS | LOCAL_INDEX | SEGMENT |
+-----------+--------------------------------------+--------+-------------+---------+
| node2     | 63870cc3-af5d-11e7-a0db-463be8426737 | DONOR  |           0 |       1 |
| node3     | 666ad5a0-af5d-11e7-9b39-2726e5de8eb1 | DONOR  |           1 |       1 |
| node1     | f3e45392-af5b-11e7-854e-9b29cd1909da | DONOR  |           5 |       1 |
| node6     | 7540bdca-b267-11e7-bae9-464c3d263470 | SYNCED |           2 |       2 |
| node5     | ab551483-b267-11e7-a1a1-9be1826f877f | SYNCED |           3 |       2 |
| node4     | e24ebd01-af5d-11e7-86f0-42c8ceb6886c | SYNCED |           4 |       2 |
+-----------+--------------------------------------+--------+-------------+---------+
```
In this case `node6` will become the new WRITER.


More details

How to use it
```
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
   --active_failover  A value from 0 to 3, indicating what level/kind of fail-over the script must perform.
                       active_failover
                       Valid values are:
                          0 [default] do not make failover
                          1 make failover only if HG 8000 is specified in ProxySQL mysl_servers
                          2 use PXC_CLUSTER_VIEW to identify a server in the same segment
                          3 do whatever to keep service up also failover to another segment (use PXC_CLUSTER_VIEW) 

   --debug
   --log	  Full path to the log file ie (/var/log/proxysql/galera_check_) the check will add
		    the identifier for the specific HG.
   -help          help message
```   

Note that galera_check is also Segment aware, as such the checks on the presence of Writer /reader is done by segment, respecting the MainSegment as primary.


Configure in ProxySQL

```
INSERT  INTO scheduler (id,active,interval_ms,filename,arg1) values (10,0,2000,"/var/lib/proxysql/galera_check.pl","-u=admin -p=admin -h=192.168.1.50 -H=500:W,501:R -P=3310 --retry_down=2 --retry_up=1 --main_segment=1 --debug=0  --log=/var/lib/proxysql/galeraLog");
LOAD SCHEDULER TO RUNTIME;SAVE SCHEDULER TO DISK;

update scheduler set active=1 where id=10;
LOAD SCHEDULER TO RUNTIME;

update scheduler set arg1="-u=admin -p=admin -h=192.168.1.50 -H=500:W,501:R -P=3310 --main_segment=1 --debug=1  --log=/var/lib/proxysql/galeraLog" where id =10;  
LOAD SCHEDULER TO RUNTIME;SAVE SCHEDULER TO DISK;


delete from scheduler where id=10;
LOAD SCHEDULER TO RUNTIME;SAVE SCHEDULER TO DISK;
```
Logic Rules use in the check:

* Set to offline_soft :
    
    any non 4 or 2 state, read only =ON
    donor node reject queries - 0 size of cluster > 2 of nodes in the same segments more then one writer, node is NOT read_only


* change HG for maintenance HG:
    
    Node/cluster in non primary
    wsrep_reject_queries different from NONE
    Donor, node reject queries =1 size of cluster 


* Node comes back from offline_soft when (all of them):

     1. Node state is 4
     2. wsrep_reject_queries = none
     3. Primary state


* Node comes back from maintenance HG when (all of them):

     1. node state is 4
     2. wsrep_reject_queries = none
     3. Primary state
     
     

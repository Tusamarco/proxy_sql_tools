     
Galera Check tool
====================

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
 * pxc_main_mode
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

Special HostGoup 8000 is now used also for READERS, to define which should be checked and eventually add to the pool if missed

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

The special group of 8000 is instead used for __configuration__, this is it you will need to insert the 8XXXX referring to your WRITER HG and READER HG as the configuration the script needs to refer to.
To be clear 8XXX  where X are the digit of your Hostgroup id ie 20 -> 8020, 1 -> 8001 etc .

This check does NOT modify any state of the Nodes. 
Meaning It will NOT modify any variables or settings in the original node. It will ONLY change states in ProxySQL. 

Multi PXC node and Single writer.
ProxySQL can easily move traffic read or write from a node to another in case of a node failure. Normally playing with the weight will allow us to have a (stable enough) scenario.
But this will not guarantee the FULL 100% isolation in case of the need to have single writer.
When  there is that need, using only the weight will not be enough given ProxySQL will direct some writes also to the other nodes, few indeed, but still some of them, as such no 100% isolated.
Unless you use single_writer option (ON by default), in that case your PXC setup will rely on one Writer a time.

To manage that and also to provide a good way to set/define what and how to fail-over in case of need, I had implement a new feature:
*active_failover*
    Valid values are:
          0 [default] do not make fail-over
          1 make fail-over only if HG 8000 is specified in ProxySQL mysl_servers 
          2 use PXC_CLUSTER_VIEW to identify a server in the same segment
          3 do whatever to keep service up also fail-over to another segment (use PXC_CLUSTER_VIEW) 

Active fail-over works using three main features, the Backup Host Group and the information present  in wsrep_provider_options and in the table performance_schema.pxc_cluster_view (PXC 5.7.19 and later).
Because this you need to have the monitor ProxySQL user able to select from performance_schema table if you want to use pxc_cluster_view. 
For example:
```SQL
INSERT INTO mysql_servers (hostname,hostgroup_id,port,weight,max_connections) VALUES ('192.168.1.205',50,3306,1000000,2000);

INSERT INTO mysql_servers (hostname,hostgroup_id,port,weight,max_connections) VALUES ('192.168.1.205',8050,3306,1000,2000);
INSERT INTO mysql_servers (hostname,hostgroup_id,port,weight,max_connections) VALUES ('192.168.1.231',8050,3306,999,2000);
INSERT INTO mysql_servers (hostname,hostgroup_id,port,weight,max_connections) VALUES ('192.168.1.22',8050,3306,998,2000);


INSERT INTO mysql_servers (hostname,hostgroup_id,port,weight,max_connections) VALUES ('192.168.1.205',8052,3306,10000,2000);
INSERT INTO mysql_servers (hostname,hostgroup_id,port,weight,max_connections) VALUES ('192.168.1.231',8052,3306,10000,2000);
INSERT INTO mysql_servers (hostname,hostgroup_id,port,weight,max_connections) VALUES ('192.168.1.22',8052,3306,10000,2000);



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
It will also create 3 entries for the SPECIAL group 8050. This group will be used by the script to manage the fail-over of HG 50.
It will also create 3 entries for the SPECIAL group 8051. This group will be used by the script to manage the read nodes in HG 51.

In the above example, what will happen is that in case of you have set `*active_failover*=1`, the script will check the nodes, if node `192.168.1.205',50` is not up,
the script will try to identify another node within the same segment that has the **higest weight** IN THE 8050 HG. In this case it will elect as new writer the node`'192.168.1.231',8050`.
So in this case you must set the nodes with different weight for HG 8050.

**Please note** that active_failover=1, is the only deterministic method to failover, based on what **YOU** define.
If set correctly across a ProxySQL cluster, all nodes will act the same. Yes a possible delay given the check interval may exists, but that cannot be avoided. 

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


## More details

### How to use it
```
galera_check.pl -u=admin -p=admin -h=127.0.0.1 -H=500:W,501:R -P=6032 --main_segment=1 --debug=0  --log <full_path_to_file> --help
galera_check.pl -u=cluster1 -p=clusterpass -h=192.168.4.191 -H=200:W,201:R -P=6032 --main_segment=1 --debug=1 --log /tmp/test --active_failover=1 --retry_down=2 --retry_up=1 --single_writer=0 --writer_is_also_reader=1"
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
   --writer_is_also_reader Active by default [writer_is_also_reader =1]. If disable the writer will be removed by the Reader Host group and will serve only reads inside the same transaction of the writes. 
   
   
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

```   

Note that galera_check is also Segment aware, as such the checks on the presence of Writer /reader is done by segment, respecting the MainSegment as primary.


### Examples of configurations in ProxySQL

Simple check without retry no failover mode
```
INSERT  INTO scheduler (id,active,interval_ms,filename,arg1) values (10,0,2000,"/var/lib/proxysql/galera_check.pl","-u=admin -p=admin -h=192.168.1.50 -H=500:W,501:R -P=3310 --main_segment=1 --debug=0  --log=/var/lib/proxysql/galeraLog");
```

Simple check with retry options no failover mode
```
INSERT  INTO scheduler (id,active,interval_ms,filename,arg1) values (10,0,2000,"/var/lib/proxysql/galera_check.pl","-u=admin -p=admin -h=192.168.1.50 -H=500:W,501:R -P=3310 --retry_down=2 --retry_up=1 --main_segment=1 --debug=0  --log=/var/lib/proxysql/galeraLog");
LOAD SCHEDULER TO RUNTIME;SAVE SCHEDULER TO DISK;
```

Script with supporting SINGLE writer HG and Backup nodes 
```
INSERT  INTO scheduler (id,active,interval_ms,filename,arg1) values (10,0,2000,"/var/lib/proxysql/galera_check.pl","-u=admin -p=admin -h=192.168.1.50 -H=500:W,501:R -P=3310 --main_segment=1 --debug=0 --active_failover=1 --log=/var/lib/proxysql/galeraLog");
```
Full mode with active_failover single writer and retry
```
INSERT  INTO scheduler (id,active,interval_ms,filename,arg1) values (10,0,2000,"/var/lib/proxysql/galera_check.pl","-u=remoteUser -p=remotePW -h=192.168.1.50 -H=500:W,501:R -P=6032 --retry_down=2 --retry_up=1 --main_segment=1 --debug=0 --active_failover=1 --single_writer=1 --log=/var/lib/proxysql/galeraLog");
LOAD SCHEDULER TO RUNTIME;SAVE SCHEDULER TO DISK;
```

To activate it
```update scheduler set active=1 where id=10;
LOAD SCHEDULER TO RUNTIME;SAVE SCHEDULER TO DISK;
```

To update the parameters you must pass all of them not only the ones you want to change(IE enabling debug)
```
update scheduler set arg1="-u=remoteUser -p=remotePW -h=192.168.1.50 -H=500:W,501:R -P=6032 --retry_down=2 --retry_up=1 --main_segment=1 --debug=1 --active_failover=1 --single_writer=1 --log=/var/lib/proxysql/galeraLog" where id =10;  

LOAD SCHEDULER TO RUNTIME;SAVE SCHEDULER TO DISK;
```

delete from scheduler where id=10;
```
LOAD SCHEDULER TO RUNTIME;SAVE SCHEDULER TO DISK;
```


For all to update the scheduler and make the script active:
```
update scheduler set active=1 where id=10;
LOAD SCHEDULER TO RUNTIME;
```

Remove a rule from scheduler:
```
delete from scheduler where id=10;
LOAD SCHEDULER TO RUNTIME;SAVE SCHEDULER TO DISK;
```
## Logic Rules used in the check:

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
     
* PXC (pxc_maint_mode).

 PXC_MAIN_MODE is fully supported.
 Any node in a state different from pxc_maint_mode=disabled will be set in OFFLINE_SOFT for all the HostGroup.
 
* internally shunning node.

While I am trying to rely as much as possible on ProxySQL, given few inefficiencies there are cases when I have to set a node to SHUNNED because ProxySQL doesn't recognize it correctly.
Mainly what the script does, it will identify the nodes not up (but still not SHUNNED) and will internally set them as SHUNNED. NO CHANGE TO ProxySQL is done, so you may not see it there, but an ERROR entry will be push to the log.

* Single Writer.

You can define IF you want to have multiple writers. Default is 1 writer only (**I strongly recommend you to do not use multiple writers unless you know very well what are you doing**), but you can now have multiple writers at the same time.



WHY I add addition_to_sys_v2.sql
=============================
Adding addition_to_sys_v2.sql

This file is the updated and correct version of the file create by LeFred https://gist.github.com/lefred/77ddbde301c72535381ae7af9f968322 which is not working correctly.
Also I have tested this solution and compared it with https://gist.github.com/lefred/6f79fd02d333851b8d18f52716f04d91#file-addition_to_sys_gr-sql
 and the output cost MORE in the file-addition_to_sys_gr-sql
 version than this one.

All the credit goes to @lefred who did the first version 

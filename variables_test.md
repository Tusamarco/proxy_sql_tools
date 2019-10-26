# Global Variables

The behaviour of ProxySQL can be tweaked using global variables. These can be configured in 2 ways:
* at runtime, using the admin interface (preferred)
* at startup, using the dedicated section in the configuration file

ProxySQL supports maximal uptime by allowing most variables to change at runtime and take effect immediately, without having to restart the daemon. There are only 3x variables that cannot be changed at runtime - `mysql-interfaces`, `mysql-threads` and `mysql-stacksize`.

Also, there are 2 types of global variables, depending on which part of ProxySQL they control:
* admin variables, which control the behaviour of the admin interface. Their names begin with the token "admin-"
* mysql variables, which control the MySQL functionality of the proxy. Their names begin with the token "mysql-"

These global variables are stored in a per-thread fashion inside of the proxy in order to speed up access to them, as they are used extremely frequently. They control the behaviour of the proxy in terms of memory footprint or the number of connections accepted, and other essential aspects. Whenever a `LOAD MYSQL VARIABLES TO RUNTIME` or `LOAD ADMIN VARIABLES TO RUNTIME` command is issued, all the threads using the mysql or admin variables are notified that they have to update their values.

To change the value of a global variable either use an `UPDATE` statement:
```
UPDATE global_variables SET variable_value=1900 WHERE variable_name='admin-refresh_interval';
```
or the shorter `SET` statement, similar to MySQL's:
```
SET admin-refresh_interval = 1700;
SET admin-version = '1.1.1beta8';
```

Next, we're going to explain each type of variable in detail.

Variable name|Default Value|From Version
-------------|-------------|------------
[admin-admin_credentials](#admin-admin_credentials)          | admin:admin          
[admin-checksum_mysql_query_rules](#admin-checksum_mysql_query_rules)| true                 
[admin-checksum_mysql_servers](#admin-checksum_mysql_servers)| true                 
[admin-checksum_mysql_users](#admin-checksum_mysql_users)| true                 
[admin-cluster_check_interval_ms](#admin-cluster_check_interval_ms)| 1000                 
[admin-cluster_check_status_frequency](#admin-cluster_check_status_frequency)| 10                   
[admin-cluster_mysql_query_rules_diffs_before_sync](#admin-cluster_mysql_query_rules_diffs_before_sync)| 3                    
[admin-cluster_mysql_query_rules_save_to_disk](#admin-cluster_mysql_query_rules_save_to_disk)| true                 
[admin-cluster_mysql_servers_diffs_before_sync](#admin-cluster_mysql_servers_diffs_before_sync)| 3                    
[admin-cluster_mysql_servers_save_to_disk](#admin-cluster_mysql_servers_save_to_disk)| true                 
[admin-cluster_mysql_users_diffs_before_sync](#admin-cluster_mysql_users_diffs_before_sync)| 3                    
[admin-cluster_mysql_users_save_to_disk](#admin-cluster_mysql_users_save_to_disk)| true                 
[admin-cluster_password](#admin-cluster_password)|                      
[admin-cluster_proxysql_servers_diffs_before_sync](#admin-cluster_proxysql_servers_diffs_before_sync)| 3                    
[admin-cluster_proxysql_servers_save_to_disk](#admin-cluster_proxysql_servers_save_to_disk)| true                 
[admin-cluster_username](#admin-cluster_username)|                      
[admin-hash_passwords](#admin-hash_passwords)| true                 
[admin-mysql_ifaces](#admin-mysql_ifaces)| 0.0.0.0:6032         
[admin-read_only](#admin-read_only)| false                
[admin-refresh_interval](#admin-refresh_interval)| 2000                 
[admin-stats_credentials](#admin-stats_credentials)| stats:stats          
[admin-stats_mysql_connection_pool](#admin-stats_mysql_connection_pool)| 60                   
[admin-stats_mysql_connections](#admin-stats_mysql_connections)| 60                   
[admin-stats_mysql_query_cache](#admin-stats_mysql_query_cache)| 60                   
[admin-stats_system_cpu](#admin-stats_system_cpu)| 60                   
[admin-stats_system_memory](#admin-stats_system_memory)| 60                   
[admin-telnet_admin_ifaces](#admin-telnet_admin_ifaces)| (null)               
[admin-telnet_stats_ifaces](#admin-telnet_stats_ifaces)| (null)               
[admin-vacuum_stats](#admin-vacuum_stats)|true|2.0.6
[admin-version](#admin-version)| 2.0.7-80-g4dd4ef5f   
[admin-web_enabled](#admin-web_enabled)| false                
[admin-web_port](#admin-web_port)| 6080                 
[mysql-add_ldap_user_comment](#mysql-add_ldap_user_comment)|                      
[mysql-auditlog_filename](#mysql-auditlog_filename)|                      
[mysql-auditlog_filesize](#mysql-auditlog_filename)| 100MB            
[mysql-auto_increment_delay_multiplex](#mysql-auto_increment_delay_multiplex)| 5                    
[mysql-autocommit_false_is_transaction](#mysql-autocommit_false_is_transaction)| false                
[mysql-autocommit_false_not_reusable](#mysql-autocommit_false_not_reusable)| false                
[mysql-binlog_reader_connect_retry_msec](#mysql-binlog_reader_connect_retry_msec)| 3000                 
[mysql-client_found_rows](#mysql-client_found_rows)                                      | true                 
[mysql-client_multi_statements](#mysql-client_multi_statements)| true                 
[mysql-client_session_track_gtid](#mysql-client_session_track_gtid)| true                 
[mysql-commands_stats](#mysql-commands_stats)| true                 
[mysql-connect_retries_delay](#mysql-connect_retries_delay)| 1                    
[mysql-connect_retries_on_failure](#mysql-connect_retries_on_failure)| 10                   
[mysql-connect_timeout_server](#mysql-connect_timeout_server)| 3000                 
[mysql-connect_timeout_server_max](#mysql-connect_timeout_server_max)| 10000                
[mysql-connection_delay_multiplex_ms](#mysql-connection_delay_multiplex_ms)| 0                    
[mysql-connection_max_age_ms](#mysql-connection_max_age_ms)| 0                    
[mysql-connpoll_reset_queue_length](#mysql-connpoll_reset_queue_length)| 50                   
[mysql-default_character_set_results](#mysql-default_character_set_results)| NULL                 
[mysql-default_charset](#mysql-default_charset)| utf8                 
[mysql-default_collation_connection](#mysql-default_collation_connection)|                      
[mysql-default_isolation_level](#mysql-default_isolation_level)| READ COMMITTED       
[mysql-default_max_join_size](#mysql-default_max_join_size)| 18446744073709551615 
[mysql-default_max_latency_ms](#mysql-default_max_latency_ms)| 1000                 
[mysql-default_net_write_timeout](#mysql-default_net_write_timeout)| 60                   
[mysql-default_query_delay](#mysql-default_query_delay)| 0                    
[mysql-default_query_timeout](#mysql-default_query_timeout)| 36000000             
[mysql-default_reconnect](#mysql-default_reconnect)| true                 
[mysql-default_schema](#mysql-default_schema)| information_schema   
[mysql-default_session_track_gtids](#mysql-default_session_track_gtids)| OFF                  
[mysql-default_sql_auto_is_null](#mysql-default_sql_auto_is_null)| OFF                  
[mysql-default_sql_mode](#mysql-default_sql_mode)|                      
[mysql-default_sql_safe_updates](#mysql-default_sql_safe_updates)| OFF                  
[mysql-default_sql_select_limit](#mysql-default_sql_select_limit)| DEFAULT              
[mysql-default_time_zone](#mysql-default_time_zone)| SYSTEM               
[mysql-default_transaction_read](#mysql-default_transaction_read)| WRITE                
[mysql-default_tx_isolation](#mysql-default_tx_isolation)| READ-COMMITTED       
[mysql-enforce_autocommit_on_reads](#mysql-enforce_autocommit_on_reads)| false                
[mysql-eventslog_default_log](#mysql-eventslog_default_log)| 0                    
[mysql-eventslog_filename](#mysql-eventslog_filename)|                      
[mysql-eventslog_filesize](#mysql-eventslog_filesize)| 104857600            
[mysql-eventslog_format](#mysql-eventslog_format)| 1                    
[mysql-forward_autocommit](#mysql-forward_autocommit)| false                
[mysql-free_connections_pct](#mysql-free_connections_pct)| 10                   
[mysql-have_compress](#mysql-have_compress)| true                 
[mysql-have_ssl](#mysql-have_ssl)| false                
[mysql-hostgroup_manager_verbose](#mysql-hostgroup_manager_verbose)| 1                    
[mysql-init_connect](#mysql-init_connect)|                      
[mysql-interfaces](#mysql-interfaces)| 0.0.0.0:6033         
[mysql-keep_multiplexing_variables](#mysql-keep_multiplexing_variables)| tx_isolation,version 
[mysql-kill_backend_connection_when_disconnect](#mysql-kill_backend_connection_when_disconnect)| true                 
[mysql-ldap_user_variable](#mysql-ldap_user_variable)|                      
[mysql-long_query_time](#mysql-long_query_time)| 1000                 
[mysql-max_allowed_packet](#mysql-max_allowed_packet)| 4194304              
[mysql-max_connections](#mysql-max_connections)| 2048                 
[mysql-max_stmts_cache](#mysql-max_stmts_cache)| 10000                
[mysql-max_stmts_per_connection](#mysql-max_stmts_per_connection)| 20                   
[mysql-max_transaction_time](#mysql-max_transaction_time)| 14400000             
[mysql-min_num_servers_lantency_awareness](#mysql-min_num_servers_lantency_awareness)| 1000                 
[mysql-mirror_max_concurrency](#mysql-mirror_max_concurrency)| 16                   
[mysql-mirror_max_queue_length](#mysql-mirror_max_queue_length)| 32000                
[mysql-monitor_connect_interval](#mysql-monitor_connect_interval)| 60000                
[mysql-monitor_connect_timeout](#mysql-monitor_connect_timeout)| 600                  
[mysql-monitor_enabled](#mysql-monitor_enabled)| true                 
[mysql-monitor_galera_healthcheck_interval](#mysql-monitor_galera_healthcheck_interval)| 5000                 
[mysql-monitor_galera_healthcheck_max_timeout_count](#mysql-monitor_galera_healthcheck_max_timeout_count)| 3                    
[mysql-monitor_galera_healthcheck_timeout](#mysql-monitor_galera_healthcheck_timeout)| 800                  
[mysql-monitor_groupreplication_healthcheck_interval](#mysql-monitor_groupreplication_healthcheck_interval)| 5000                 
[mysql-monitor_groupreplication_healthcheck_max_timeout_count](#mysql-monitor_groupreplication_healthcheck_max_timeout_count)| 3                    
[mysql-monitor_groupreplication_healthcheck_timeout](#mysql-monitor_groupreplication_healthcheck_timeout)| 800                  
[mysql-monitor_history](#mysql-monitor_history)| 600000               
[mysql-monitor_password](#mysql-monitor_password)| monitor              
[mysql-monitor_ping_interval](#mysql-monitor_ping_interval)| 10000                
[mysql-monitor_ping_max_failures](#mysql-monitor_ping_max_failures)| 3                    
[mysql-monitor_ping_timeout](#mysql-monitor_ping_timeout)| 1000                 
[mysql-monitor_query_interval](#mysql-monitor_query_interval)| 60000                
[mysql-monitor_query_timeout](#mysql-monitor_query_timeout)| 100                  
[mysql-monitor_read_only_interval](#mysql-monitor_read_only_interval)| 1500                 
[mysql-monitor_read_only_max_timeout_count](#mysql-monitor_read_only_max_timeout_count)| 3                    
[mysql-monitor_read_only_timeout](#mysql-monitor_read_only_timeout)| 500                  
[mysql-monitor_replication_lag_interval](#mysql-monitor_replication_lag_interval)| 10000                
[mysql-monitor_replication_lag_timeout](#mysql-monitor_replication_lag_timeout)| 1000                 
[mysql-monitor_replication_lag_use_percona_heartbeat](#mysql-monitor_replication_lag_use_percona_heartbeat)|                      
[mysql-monitor_slave_lag_when_null](#mysql-monitor_slave_lag_when_null)| 60                   
[mysql-monitor_threads_max](#mysql-monitor_threads_max)| 128                  
[mysql-monitor_threads_min](#mysql-monitor_threads_min)| 8                    
[mysql-monitor_threads_queue_maxsize](#mysql-monitor_threads_queue_maxsize)| 128                  
[mysql-monitor_username](#mysql-monitor_username)| monitor              
[mysql-monitor_wait_timeout](#mysql-monitor_wait_timeout)| true                 
[mysql-monitor_writer_is_also_reader](#mysql-monitor_writer_is_also_reader)| true                 
[mysql-multiplexing](#mysql-multiplexing)| true                 
[mysql-ping_interval_server_msec](#mysql-ping_interval_server_msec)| 120000               
[mysql-ping_timeout_server](#mysql-ping_timeout_server)| 500                  
[mysql-poll_timeout](#mysql-poll_timeout)| 2000                 
[mysql-poll_timeout_on_failure](#mysql-poll_timeout_on_failure)| 100                  
[mysql-query_cache_size_MB](#mysql-query_cache_size_MB)| 256                  
[mysql-query_cache_stores_empty_result](#mysql-query_cache_stores_empty_result)| true                 
[mysql-query_digests](#mysql-query_digests)| true                 
[mysql-query_digests_lowercase](#mysql-query_digests_lowercase)| false                
[mysql-query_digests_max_digest_length](#mysql-query_digests_max_digest_length)| 2048                 
[mysql-query_digests_max_query_length](#mysql-query_digests_max_query_length)| 65000                
[mysql-query_digests_no_digits](#mysql-query_digests_no_digits)| false                
[mysql-query_digests_normalize_digest_text](#mysql-query_digests_normalize_digest_text)| false                
[mysql-query_digests_replace_null](#mysql-query_digests_replace_null)| false                
[mysql-query_digests_track_hostname](#mysql-query_digests_track_hostname)| false                
[mysql-query_processor_iterations](#mysql-query_processor_iterations)| 0                    
[mysql-query_processor_regex](#mysql-query_processor_regex)| 1                    
[mysql-query_retries_on_failure](#mysql-query_retries_on_failure)| 1                    
[mysql-reset_connection_algorithm](#mysql-reset_connection_algorithm)| 2                    
[mysql-server_capabilities](#mysql-server_capabilities)| 569867               
[mysql-server_version](#mysql-server_version)| 5.5.30               
[mysql-servers_stats](#mysql-servers_stats)| true                 
[mysql-session_idle_ms](#mysql-session_idle_ms)| 1000                 
[mysql-session_idle_show_processlist](#mysql-session_idle_show_processlist)| true                 
[mysql-sessions_sort](#mysql-sessions_sort)| true                 
[mysql-set_query_lock_on_hostgroup](#mysql-set_query_lock_on_hostgroup)| 1                    
[mysql-show_processlist_extended](#mysql-show_processlist_extended)| 0                    
[mysql-shun_on_failures](#mysql-shun_on_failures)| 5                    
[mysql-shun_recovery_time_sec](#mysql-shun_recovery_time_sec)| 10                   
[mysql-ssl_p2s_ca](#mysql-ssl_p2s_ca)|                      
[mysql-ssl_p2s_cert](#mysql-ssl_p2s_cert)|                      
[mysql-ssl_p2s_cipher](#mysql-ssl_p2s_cipher)|                      
[mysql-ssl_p2s_key](#mysql-ssl_p2s_key)|                      
[mysql-stacksize](#mysql-stacksize)| 1048576              
[mysql-stats_time_backend_query](#mysql-stats_time_backend_query)| false                
[mysql-stats_time_query_processor](#mysql-stats_time_query_processor)| false                
[mysql-tcp_keepalive_time](#mysql-tcp_keepalive_time)| 0                    
[mysql-threads](#mysql-threads)| 4                    
[mysql-threshold_query_length](#mysql-threshold_query_length)| 524288               
[mysql-threshold_resultset_size](#mysql-threshold_resultset_size)| 4194304              
[mysql-throttle_connections_per_sec_to_hostgroup](#mysql-throttle_connections_per_sec_to_hostgroup)| 1000000              
[mysql-throttle_max_bytes_per_second_to_client](#mysql-throttle_max_bytes_per_second_to_client)| 0                    
[mysql-throttle_ratio_server_to_client](#mysql-throttle_ratio_server_to_client)| 0                    
[mysql-use_tcp_keepalive](#mysql-use_tcp_keepalive)| 0                    
[mysql-verbose_query_error](#mysql-verbose_query_error)| false                
[mysql-wait_timeout](#mysql-wait_timeout)| 28800000             



## Admin Variables

### <a name="admin-admin_credentials">`admin-admin_credentials`</a> 

This is a list of semi-colon separated `user:password` pairs, that can be used to authenticate to the admin interface with read-write rights. For read-only credentials that can be used to connect to the admin, see the variable `admin-stats_credentials`. Note that the admin interface listens on a separate port from the main ProxySQL thread. This port is controlled through the variable `admin-mysql_ifaces`. 

It is important to note that:
- the default `admin` user can only connect locally, in order to connect remotely a secondary user needs to be created by defining this in the `admin-admin_credentials` variable E.G. `admin-admin_credentials="admin:admin;radminuser:radminpass"`.
- users in `admin-admin_credentials` cannot be used also in `mysql_users` table.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>admin-admin_credentials</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="3"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>admin:admin</td>
    </tr>
</table>​

### <a name="admin-checksum_mysql_query_rules">`admin-checksum_mysql_query_rules`</a>

See [ProxySQL Cluster](https://github.com/sysown/proxysql/wiki/ProxySQL-Cluster)

### <a name="admin-checksum_mysql_servers">`admin-checksum_mysql_servers`</a>

See [ProxySQL Cluster](https://github.com/sysown/proxysql/wiki/ProxySQL-Cluster)

### <a name="admin-checksum_mysql_users">`admin-checksum_mysql_users`</a>

See [ProxySQL Cluster](https://github.com/sysown/proxysql/wiki/ProxySQL-Cluster)

### <a name="admin-cluster_check_interval_ms">`admin-cluster_check_interval_ms`</a>

See [ProxySQL Cluster](https://github.com/sysown/proxysql/wiki/ProxySQL-Cluster)

### <a name="admin-cluster_check_status_frequency">`admin-cluster_check_status_frequency`</a>

See [ProxySQL Cluster](https://github.com/sysown/proxysql/wiki/ProxySQL-Cluster)

### <a name="admin-cluster_mysql_query_rules_diffs_before_sync">`admin-cluster_mysql_query_rules_diffs_before_sync`</a>

See [ProxySQL Cluster](https://github.com/sysown/proxysql/wiki/ProxySQL-Cluster)

### <a name="admin-cluster_mysql_query_rules_save_to_disk">`admin-cluster_mysql_query_rules_save_to_disk`</a>

See [ProxySQL Cluster](https://github.com/sysown/proxysql/wiki/ProxySQL-Cluster)

### <a name="admin-cluster_mysql_servers_diffs_before_sync">`admin-cluster_mysql_servers_diffs_before_sync`</a>

See [ProxySQL Cluster](https://github.com/sysown/proxysql/wiki/ProxySQL-Cluster)

### <a name="admin-cluster_mysql_servers_save_to_disk">`admin-cluster_mysql_servers_save_to_disk`</a>

See [ProxySQL Cluster](https://github.com/sysown/proxysql/wiki/ProxySQL-Cluster)

### <a name="admin-cluster_mysql_users_diffs_before_sync">`admin-cluster_mysql_users_diffs_before_sync`</a>

See [ProxySQL Cluster](https://github.com/sysown/proxysql/wiki/ProxySQL-Cluster)

### <a name="admin-cluster_mysql_users_save_to_disk">`admin-cluster_mysql_users_save_to_disk`</a>

See [ProxySQL Cluster](https://github.com/sysown/proxysql/wiki/ProxySQL-Cluster)

### <a name="admin-cluster_password">`admin-cluster_password`</a>

See [ProxySQL Cluster](https://github.com/sysown/proxysql/wiki/ProxySQL-Cluster)

### <a name="admin-cluster_proxysql_servers_diffs_before_sync">`admin-cluster_proxysql_servers_diffs_before_sync`</a>

See [ProxySQL Cluster](https://github.com/sysown/proxysql/wiki/ProxySQL-Cluster)

### <a name="admin-cluster_proxysql_servers_save_to_disk">`admin-cluster_proxysql_servers_save_to_disk`/<a>

See [ProxySQL Cluster](https://github.com/sysown/proxysql/wiki/ProxySQL-Cluster)

### <a name="admin-cluster_username">`admin-cluster_username`</a>

See [ProxySQL Cluster](https://github.com/sysown/proxysql/wiki/ProxySQL-Cluster)

### <a name="admin-hash_passwords">`admin-hash_passwords`</a>

ProxySQL v1.2.3 introduced a new global boolean variable, `admin-hash_passwords`, enabled by default.
When `admin-hash_passwords=true`, password are automatically hashed at RUNTIME when running `LOAD MYSQL USERS TO RUNTIME`. Passwords in mysql_users tables are not automatically hashed and require you to run `SAVE MYSQL USERS FROM RUNTIME`.

See [Password Management](https://github.com/sysown/proxysql/wiki/Password-management#variable-admin-hash_passwords) for further details.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>admin-hash_passwords</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="3"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>true</td>
    </tr>
</table>​

### <a name="admin-mysql_ifaces">`admin-mysql_ifaces`</a>

Semicolon-separated list of hostname:port entries for interfaces on which the admin interface should listen on. Note that this also supports UNIX domain sockets for the cases where the connection is done from an application on the same machine E.G.: `SET admin-mysql_ifaces='127.0.0.1:6032;/tmp/proxysql_admin.sock'`. Please note that the default `admin` user can only connect locally, in order to connect remotely a secondary user needs to be created by defining this in the `admin-admin_credentials` variable E.G. `admin-admin_credentials="admin:admin;radminuser:radminpass"`. 

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>admin-mysql_ifaces</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="3"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default (up to 1.4.0)</b></td>
        <td>127.0.0.1:6032</td>
    </tr>
    <tr>
        <td><b>Default (from 1.4.1 onwards)</b></td>
        <td>0.0.0.0:6032</td>
    </tr>
</table>​

### <a name="admin-read_only">`admin-read_only`</a>

When this variable is set to true and loaded at runtime, the Admin module does not accept write anymore. This is useful to ensure that ProxySQL is not reconfigured.
When `admin-read_only=true`, the only way to revert it to false at runtime (and make the Admin module writable again) is to run the command `PROXYSQL READWRITE`.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>admin-read_only</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="3"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>false</td>
    </tr>
</table>​

### <a name="admin-refresh_interval">`admin-refresh_interval`</a>

The refresh interval (in microseconds) for updates to the query rules statistics and commands counters statistics. Be careful about tweaking this to a value that is:
* too low, because it might affect the overall performance of the proxy
* too high, because it might affect the correctness of the results


<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>admin-refresh_interval</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (microseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>2000</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>100</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>100000</td>
    </tr>
</table>​

### <a name="admin-stats_credentials">`admin-stats_credentials`</a>

This is a list of semi-colon separated `user:password` pairs that defines the read-only credentials for connecting to the admin interface. These are not allowed updates to internal data structures such as the list of MySQL backend servers (or hostgroups), query rules, etc. They only allow readings from the statistics and monitoring tables (the other tables are not only even visible).
Note: users in `admin-stats_credentials` cannot be used also in `mysql_users` table.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>admin-stats_credentials</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>stats:stats</td>
    </tr>
</table>​

### <a name="admin-telnet_admin_ifaces">`admin-telnet_admin_ifaces`</a>

Not currently used (planned usage in a future version).

### <a name="admin-telnet_stats_ifaces">`admin-telnet_stats_ifaces`</a>

Not currently used (planned usage in a future version).

### <a name="admin-version">`admin-version`</a>

This variable displays ProxySQL version. This variable is read only.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>admin-version</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>No</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Read Only</b></td>
        <td>true</td>
    </tr>
</table>​

## Admin historical statistics

Since ProxySQL 1.4.4 Admin stores historical metrics in new database named `proxysql_stats.db` in the datadir.  
Tables structures is subject to future changes.  

### <a name="admin-stats_mysql_connection_pool">`admin-stats_mysql_connection_pool`</a>

The refresh interval (in seconds) to update the historical statistics of the connection pool.  

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>admin-stats_mysql_connection_pool</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (seconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>60</td>
    </tr>
    <tr>
        <td><b>Valid values</b></td>
        <td>5, 10, 30, 60, 120, 300</td>
    </tr>
</table>​


### <a name="admin-stats_mysql_connections">`admin-stats_mysql_connections`</a>

The refresh interval (in seconds) to update the historical statistics of MySQL connections, both frontends and backends.  

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>admin-stats_mysql_connections</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (seconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>60</td>
    </tr>
    <tr>
        <td><b>Valid values</b></td>
        <td>5, 10, 30, 60, 120, 300</td>
    </tr>
</table>​


### <a name="admin-stats_mysql_query_cache">`admin-stats_mysql_query_cache`</a>

The refresh interval (in seconds) to update the historical statistics of MySQL Query Cache.  

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>admin-stats_mysql_query_cache</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (seconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>60</td>
    </tr>
    <tr>
        <td><b>Valid values</b></td>
        <td>5, 10, 30, 60, 120, 300</td>
    </tr>
</table>​

### <a name="admin-stats_system_cpu">`admin-stats_system_cpu`</a>

The refresh interval (in seconds) to update the historical statistics of CPU usage.  

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>admin-stats_system_cpu</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (seconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>60</td>
    </tr>
    <tr>
        <td><b>Valid values</b></td>
        <td>5, 10, 30, 60, 120, 300</td>
    </tr>
</table>​


### <a name="admin-stats_system_memory">`admin-stats_system_memory`</a>

The refresh interval (in seconds) to update the historical statistics of memory usage.  
*Note*: These statistics are not available if ProxySQL is not compiled with jemalloc.  Note that all official packages are compiled with jemalloc.  

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>admin-stats_mysql_system_memory</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (seconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>60</td>
    </tr>
    <tr>
        <td><b>Valid values</b></td>
        <td>5, 10, 30, 60, 120, 300</td>
    </tr>
</table>

## <a name="admin-vacuum_stats">admin-vacuum_stats</a>
 This parameter enable|disable the vacuum operation on the SQLite database storing the statistics. 
    VACUUM command cleans the main database by copying its contents to a temporary database file and reloading the original database file from the copy. This eliminates free pages, aligns table data to be contiguous, and otherwise cleans up the database file structure.
    <table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>admin-vacuum_stats</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean (seconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>true</td>
    </tr>
    <tr>
        <td><b>Valid values</b></td>
        <td>true, false</td>
    </tr>
</table>
    
## Admin web interface

ProxySQL 1.4.4 embeds an HTTP web server from where is possible to gather certain metrics.  
Credentials to access the web interfaces are the same defined in `admin-stats_credentials`.  

### <a name="admin-web_enabled">`admin-web_enabled`</a>

If `admin-web_enabled` is set to `true`, the web server is automatically enabled.  

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>admin-web_enabled</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="3"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>false</td>
    </tr>
</table>​


### <a name="admin-web_port">`admin-web_port`</a>

This variable defines on which port the web server is listening.  

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>admin-web_port</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>6080</td>
    </tr>
</table>​


## MySQL Variables

### <a name="mysql-add_ldap_user_comment">`mysql-add_ldap_user_comment`</a>
If mysql-add_ldap_user_comment is set, a comment like the following will be added on the query::
``` SQL
valueof_mysql-add_ldap_user_comment=frontend_username 
```
<table>
    <tr>
        <td valign="top" rowspan="2"><b>MySQL Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-add_ldap_user_comment</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>NULL</td>
    </tr>
    <tr>
        <td><b>Valid values</b></td>
        <td></td>
    </tr>
</table>

### <a name="mysql-ldap_user_variable">`mysql-ldap_user_variable`</a>
  When set, sessions will have a variable set with the user_name value, ie: `SET @mysql-ldap_user_variable:='username'` 
  The use of this variable can be for auditing purposed backend side. For example, if a trigger on a table will use that session variable.
<table>
    <tr>
        <td valign="top" rowspan="2"><b>MySQL Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-ldap_user_variable</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>NULL</td>
    </tr>
    <tr>
        <td><b>Valid values</b></td>
        <td></td>
    </tr>
</table>  

### <a name="mysql-auditlog_filename">`mysql-auditlog_filename`</a>
  This variable defines the base name of the audit log where audit events are logged. The filename of the log file will be the base name followed by an 8 digits progressive number.
<table>
    <tr>
        <td valign="top" rowspan="2"><b>MySQL Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-auditlog_filename</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>NULL</td>
    </tr>
    <tr>
        <td><b>Valid values</b></td>
        <td></td>
    </tr>
</table>

### <a name="mysql-auditlog_filesize">`mysql-auditlog_filesize`</a>
  This variable defines the maximum file size of the audit log when the current file will be closed and a new file will be created.
  The default value is 104857600 (100MB)
<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-auditlog_filesize</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (count)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>104857600</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>1MB</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>1GB</td>
    </tr>
</table>

### <a name="mysql-auto_increment_delay_multiplex">`mysql-auto_increment_delay_multiplex`</a>

Several applications rely, explicitly or implicitly, to the value returned by `LAST_INSERT_ID()`. If multiplexing is not configured correctly, or if the queries pattern is really unpredictable (for example if new queries are often deployed), it is possible that the query using `LAST_INSERT_ID()` uses a connection different than the connection where an auto-increment was used.  
If `mysql-auto_increment_delay_multiplex` is set, after an OK packet with `last_insert_id` is received, multiplexing is temporary disabled for the same number of queries as specified in `mysql-auto_increment_delay_multiplex`.  
Note that disabling multiplexing doesn't disable routing, so it is important to configure read/write split correctly.  

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-auto_increment_delay_multiplex</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (count)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>5</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>0</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>1000000</td>
    </tr>
</table>


### <a name="mysql-autocommit_false_is_transaction">`mysql-autocommit_false_is_transaction`</a>

If `mysql-autocommit_false_is_transaction=true` (false by default), a connection with `autocommit=0` is treated as a transaction. If `forward_autocommit=true` (false by default), the same behavior applies.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-autocommit_false_is_transaction</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>false</td>
    </tr>
</table>​

### <a name="mysql-autocommit_false_not_reusable">`mysql-autocommit_false_not_reusable`</a>

When set to `true`, a connection with `autocommit=0` is not re-used and is destroyed when the connection is returned to the connection pool.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-autocommit_false_not_reusable</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>false</td>
    </tr>
</table>​

### <a name="mysql-binlog_reader_connect_retry_msec">`mysql-binlog_reader_connect_retry_msec`</a>

Controls the connect retry timeout for the binlog reader (introduced in ProxySQL 2.0).

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-binlog_reader_connect_retry_msec</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>3000</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>200</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>120000</td>
    </tr>
</table>​

### <a name="mysql-client_found_rows">`mysql-client_found_rows`</a>

When set to `true`, client flag `CLIENT_FOUND_ROWS` is set when connecting to MySQL backends.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-client_found_rows</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>true</td>
    </tr>
</table>​

### <a name="mysql-client_multi_statements">`mysql-client_multi_statements`</a>

When set to `true`, client flag `CLIENT_MULTI_STATEMENTS` is set when connecting to MySQL backends. 

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-client_multi_statements</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>true</td>
    </tr>
</table>​
### <a name="mysql-client_session_track_gtid">`mysql-client_session_track_gtid`</a>
 When activate ProxySQL will keep track of the GTID status on the backend serves in the stats_mysql_gtid_executed table
 
<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-client_session_track_gtid</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>true</td>
    </tr>
</table> 

### <a name="mysql-commands_stats">`mysql-commands_stats`</a>

Enable per-command MySQL query statistics. A command is a type of SQL query that is being executed. Some examples are: SELECT, INSERT or ALTER TABLE.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-commands_stats</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>true</td>
    </tr>
</table>​

### <a name="mysql-connect_retries_delay">`mysql-connect_retries_delay`</a>

The delay (in milliseconds) before trying to reconnect after a failed attempt to a backend MySQL server. Failed attempts can take place due to numerous reasons: too busy, timed out for the current attempt, etc. This will be retried for `mysql-connect_retries_on_failure` times.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-connect_retries_delay</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>1</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>0</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>10000</td>
    </tr>
</table>​

### <a name="mysql-connect_retries_on_failure">`mysql-connect_retries_on_failure`</a>

The number of times for which a reconnect should be attempted in case of an error, timeout, or any other event that led to an unsuccessful connection to a backend MySQL server. After the number of attempts is depleted, if a connection still couldn't be established, an error is returned. The error returned is either the last connection attempt error or a generic error ("Max connect failure while reaching hostgroup" with error code 28000).

Be careful about tweaking this parameter - a value that is too high can significantly increase the latency which with an unresponsive hostgroup is reported to the MySQL client.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-connect_retries_on_failure</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>10</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>0</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>1000</td>
    </tr>
</table>​

### <a name="mysql-connect_timeout_server">`mysql-connect_timeout_server`</a>

The timeout for a single attempt at connecting to a backend server from the proxy. If this fails, according to the other parameters, the attempt will be retried until too many errors per second are generated (and the server is automatically shunned) or until the final cut-off is reached and an error is returned to the client (see `mysql-connect_timeout_server_max`).

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-connect_timeout_server</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>1000</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>10</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>120000</td>
    </tr>
</table>​

### <a name="mysql-connect_timeout_server_max">`mysql-connect_timeout_server_max`</a>

The timeout for connecting to a backend server from the proxy. When this timeout is reached, an error is returned to the client with code 9001 and the message "Max connect timeout reached while reaching hostgroup...". 

See also [mysql-shun_recovery_time_sec](#mysql-shun_recovery_time_sec)

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-connect_timeout_server_max</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>10000</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>10</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>3600000</td>
    </tr>
</table>​
Due a bug fixed in version 2.0.7, for all previous releases it is recommended to not set this value higher than 10 minutes.
 
### <a name="mysql-connection_delay_multiplex_ms">`mysql-connection_delay_multiplex_ms`</a>

Disable multiplexing for a short period of time on a connection, this will allow a frontend connection to re-use the same backend connection for successive queries (e.g. when batching queries). The delay is measured for the time there is no activity on the connection.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-connection_delay_multiplex_ms</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>0</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>0</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>300000</td>
    </tr>
</table>​

### <a name="mysql-connection_max_age_ms">`mysql-connection_max_age_ms`</a>

When `mysql-connection_max_age_ms` is set to a value greater than 0, inactive connections in the connection pool (therefore not currently used by any session) are closed if they were created more than `mysql-connection_max_age_ms` milliseconds ago. By default, connections aren't closed based on their age.  
When `mysql-connection_max_age_ms` is reached, connections are simply disconnected, without sending `COM_QUIT` command to the server, so this might result in 'Aborted connection' warnings showing up in your MySQL server logs (this behaviour is intended, see #1861).

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-connection_max_age_ms</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>0</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>0</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>86400000</td>
    </tr>
</table>​

### <a name="mysql-connpoll_reset_queue_length">`mysql-connpoll_reset_queue_length`</a>

PoxySQL 1.4.0 introduced a background thread (HGCU_thread_run()) responsible for resetting connections instead of dropping them when MySQL_HostGroups_Manager::destroy_MyConn_from_pool() is called. There could be cases in which this behavior is not beneficial. In ProxySQL 1.4.4 `mysql-connpoll_reset_queue_length` allows this behavior to be configurable by destroying the connection when the defined threshold is reached.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-connpoll_reset_queue_length</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>50</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>0</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>1000</td>
    </tr>
</table>​

### <a name="mysql-default_charset">`mysql-default_charset`</a>

The default server charset to be used in the communication with the MySQL clients. Note that this is the defult for client connections, not for backend connections.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-default_charset</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>utf8</td>
    </tr>
    <tr>
        <td><b>Valid Values</b></td>
        <td>Run "select * from mysql_collations;" in the Admin interface to view the full list</td>
    </tr>
</table>​

### <a name="mysql-default_character_set_results">`mysql-default_character_set_results`</a>
The character set used for returning query results to the client. This includes result data such as column values, result metadata such as column names, and error messages.
<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-default_character_set_results</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>NULL</td>
    </tr>
    <tr>
        <td><b>Valid Values</b></td>
        <td></td>
    </tr>
</table>
 
### <a name="mysql-default_collation_connection">mysql-default_collation_connection</a>
The collation of the connection character set.
<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-default_collation_connection</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>NULL</td>
    </tr>
    <tr>
        <td><b>Valid Values</b></td>
        <td></td>
    </tr>
</table>    
  
### <a name="mysql-default_isolation_level">`mysql-default_isolation_level`</a>
The default transaction isolation level. 
**Very important:** SESSION is mandatory, SET TRANSACTION ISOLATION LEVEL value is not supported and will disable multiplexing
<table>
    <tr>
        <td valign="top" rowspan="2"><b>mysql-default_isolation_level</b></td>
        <td><b>Name</b></td>
        <td>mysql-default_collation_connection</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>READ COMMITTED</td>
    </tr>
    <tr>
        <td><b>Valid Values</b></td>
        <td>ONLY at SESSION level: REPEATBALE READ, READ COMMITTED, SERIALIZED  </td>
    </tr>
</table>   

    
### <a name="mysql-default_max_join_size">`mysql-default_max_join_size`</a>
Do not permit statements that probably need to examine more than max_join_size rows (for single-table statements) or row combinations (for multiple-table statements) or that are likely to do more than max_join_size disk seeks. By setting this value, you can catch statements where keys are not used properly and that would probably take a long time. 
Set it if your users tend to perform joins that lack a WHERE clause, that take a long time, or that return millions of rows.
    Default: 18446744073709551615
 <table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-default_max_join_size</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>18446744073709551615</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>0</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>18446744073709551615</td>
    </tr>
</table>   


### <a name="mysql-default_max_latency_ms">`mysql-default_max_latency_ms`</a>

ProxySQL uses a mechanism to automatically ignore hosts if their latency is excessive. Note that hosts are not disabled, but only ignored: in other words, ProxySQL will prefer hosts with a smaller latency. It is possible to configure the maximum latency for each backend from `mysql_servers` table, column `max_latency_ms`. If `mysql_servers`.`max_latency_ms` is 0, the default value `mysql-default_max_latency_ms` applies.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-default_max_latency_ms</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>1000</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>0</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>1728000000</td>
    </tr>
</table>​

Note: due to a limitation in SSL implementation, it is recommended to increase `mysql-default_max_latency_ms` if using SSL.

### <a name="mysql-default_net_write_timeout">`mysql-default_net_write_timeout`</a>
The number of seconds to wait for a block to be written to a connection before aborting the write
<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-default_net_write_timeout</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (seconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>60</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>0</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td></td>
    </tr>
</table>


### <a name="mysql-default_query_delay">`mysql-default_query_delay`</a>

Simple throttling mechanism for queries to the backends. Setting this variable to a non-zero value (in miliseconds) will delay the execution of all queries, globally. There is a more fine-grained throttling mechanism in the admin table `mysql_query_rules`, where for each rule there can be one delay that is applied to all queries matching the rule. That extra delay is added on top of the default, global one.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-default_query_delay</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>0</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>0</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>3600000</td>
    </tr>
</table>​

### <a name="mysql-default_query_timeout">`mysql-default_query_timeout`</a>

Mechanism for specifying the maximal duration of queries to the backend MySQL servers until ProxySQL should return an error to the MySQL client. Whenever ProxySQL detects that a query has timed out, it will spawn a separate thread that runs a KILL query against the specific MySQL backend in order to stop the query from running in the backend. Because the query is killed, an error will be returned to the MySQL client.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-default_query_timeout</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>86400000</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>1000</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>1728000000</td>
    </tr>
</table>​

### <a name="mysql-default_reconnect">`mysql-default_reconnect`</a>

Not used for now.

### <a name="mysql-default_schema">`mysql-default_schema`</a>

The default schema to be used for incoming MySQL client connections which do not specify a schema name. This is required because ProxySQL doesn't allow connection without a schema.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-default_schema</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>information_schema</td>
    </tr>
    <tr>
        <td><b>Valid Values</b></td>
        <td>Any existing schema</td>
    </tr>
</table>​

### <a name="mysql-default_session_track_gtids">mysql-default_session_track_gtids</a>
Controls whether the server tracks GTIDs within the current session and returns them to the client. Depending on the variable value, at the end of executing each transaction, the server GTIDs are captured by the tracker and returned to the client. 
<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-default_session_track_gtids</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>OFF</td>
    </tr>
    <tr>
        <td><b>Valid Values</b></td>
        <td>
            valid only at SESSION scope
            OFF: The tracker collects no GTIDs. This is the default.
            OWN_GTID: The tracker collects GTIDs generated by successfully committed read/write transactions.
            ALL_GTIDS: Not supported in ProxySQL
        </td>
    </tr>
</table>​

### <a name="mysql-default_sql_auto_is_null">`mysql-default_sql_auto_is_null`</a>
If this variable is enabled, then after a statement that successfully inserts an automatically generated AUTO_INCREMENT value, you can find that value by issuing a statement of the following form:
`SELECT * FROM tbl_name WHERE auto_col IS NULL`
If the statement returns a row, the value returned is the same as if you invoked the LAST_INSERT_ID() function. For details, including the return value after a multiple-row insert, see Section 12.15, “Information Functions”. If no AUTO_INCREMENT value was successfully inserted, the SELECT statement returns no row.
<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-default_sql_auto_is_null</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>OFF</td>
    </tr>
    <tr>
        <td><b>Valid Values</b></td>
        <td>ON|OFF</td>
    </tr>
</table>


### <a name="mysql-default_sql_mode">`mysql-default_sql_mode`</a>
When a client requires a different `sql_mode`, ProxySQL needs to track the change to ensure that the needed `sql_mode` is the same on every backend connection used by that specific client.
When ProxySQL establishes a new connection to a backend it doesn't know the current `sql_mode`. Although it is possible to query the backend to retrieve `sql_mode` and other variables, querying the backend has a latency cost. For this reason ProxySQL doesn't query the backend to know the value of `sql_mode`, and instead it assumes that all the backend connections have by default the `sql_mode` defined in `mysql-default_sql_mode`.

If a client changes `sql_mode` to a value different than `mysql-default_sql_mode`, ProxySQL will ensure to change `sql_mode` on every connection used by that client.  
On the other hand, if a client set `sql_mode` to the same value specified in `mysql-default_sql_mode`, ProxySQL won't change the `sql_mode` on the backend connection because it assumes that the `sql_mode` is already correct.  

A misconfigured `mysql-default_sql_mode` can lead to unexpected results. For example, if `mysql-default_sql_mode=''` (the default in ProxySQL, and also the default for MySQL <= 5.6.5) while the backend has `sql_mode` different than `''`, if a client executes `set session sql_mode=''` ProxySQL won't change the `sql_mode` on backend.  

This variable needs to configured as the default `sql_mode` across all backends. If backends have different `sql_mode` or if you want ProxySQL to always enforce the `sql_mode` specified by the client, `mysql-default_sql_mode` can be configured using an invalid `sql_mode`. This will force ProxySQL to always change the `sql_mode` on backend to whatever value specific by the client.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-default_sql_mode</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>''</td>
    </tr>
    <tr>
        <td><b>Valid Values</b></td>
        <td>Any valid or invalid sql_mode</td>
    </tr>
</table>​

### <a name="mysql-default_sql_safe_updates">`mysql-default_sql_safe_updates`</a>
If this variable is enabled, UPDATE and DELETE statements that do not use a key in the WHERE clause or a LIMIT clause produce an error. This makes it possible to catch UPDATE and DELETE statements where keys are not used properly and that would probably change or delete a large number of rows.
<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-default_sql_safe_updates</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>OFF</td>
    </tr>
    <tr>
        <td><b>Valid Values</b></td>
        <td>ON|OFF</td>
    </tr>
</table>

### <a name="mysql-default_sql_select_limit">`mysql-default_sql_select_limit`</a>
The maximum number of rows to return from SELECT statements.
The default value for a new connection is the maximum number of rows that the server permits per table. Typical default values are (232)−1 or (264)−1. If you have changed the limit, the default value can be restored by assigning a value of DEFAULT.
If a SELECT has a LIMIT clause, the LIMIT takes precedence over the value of sql_select_limit.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-default_sql_select_limit</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>DEFAULT</td>
    </tr>
    <tr>
        <td><b>Valid Values</b></td>
        <td>
            The default value for a new connection is the maximum number of rows that the server permits per table. Typical default values are (232)−1 or (264)−1. If you have changed the limit, the default value can be restored by assigning a value of DEFAULT.
        </td>
    </tr>
</table>


### <a name="mysql-default_time_zone">`mysql-default_time_zone`</a>

If a client doesn't specify any time_zone, the time zone assigned to the client is whatever time zone currently assigned to `mysql-default_time_zone`. When a client requires a different `time_zone`, ProxySQL needs to track the change to ensure that the needed `time_zone` is the same on every backend connection used by that specific client. When ProxySQL establishes a new connection to a backend it doesn't know the current `time_zone`. Although it is possible to query the backend to retrieve `time_zone` and other variables, querying the backend has a latency cost. For this reason ProxySQL doesn't query the backend to know the value of `time_zone`, and instead it assumes that all the backend connections have by default the `time_zone` defined in `mysql-default_time_zone`.

If a client changes `time_zone` to a value different than `mysql-default_time_zone`, ProxySQL will ensure to change `time_zone` on every connection used by that client.  
On the other hand, if a client set `time_zone` to the same value specified in `mysql-default_time_zone`, ProxySQL won't change the `time_zone` on the backend connection because it assumes that the `time_zone` is already correct.  

A misconfigured `mysql-default_time_zone` can lead to unexpected results so this variable needs to configured as the default `time_zone` across all backends. If backends have different `time_zone` or if you want ProxySQL to always enforce the `time_zone` specified by the client, `mysql-default_time_zone` can be configured using an invalid `time_zone`. This will force ProxySQL to always change the `time_zone` on backend to whatever value specific by the client.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-default_time_zone</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>SYSTEM</td>
    </tr>
    <tr>
        <td><b>Valid Values</b></td>
        <td>Any valid or invalid MySQL time_zone</td>
    </tr>
</table>​

### <a name="mysql-default_transaction_read">`mysql-default_transaction_read`</a>
ProxySQL tracks the transaction access modes, READ WRITE or READ ONLY clause. 
If manually set what is mandatory for ProxySQL is the SESSION scope definition:
    - SET SESSION TRANSACTION READ WRITE
    - SET SESSION TRANSACTION READ ONLY
SET TRANSACTION READ (WRITE|ONLY) is not supported, and it will automatically disable multiplexing.

In MySQL by default, a transaction takes place in read/write mode, with both reads and writes permitted to tables used in the transaction. This mode may be specified explicitly using `SET **SESSION** TRANSACTION` with an access mode of READ WRITE.
<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-default_transaction_read</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>WRITE</td>
    </tr>
    <tr>
        <td><b>Valid Values</b></td>
        <td>READ|WRITE</td>
    </tr>
</table>

### <a name="mysql-default_tx_isolation">`mysql-default_tx_isolation`</a>
ProxySQL support the change of the Transaction Isolation level ONLY at **SESSION** level.
Any attempts to run command like `SET TRANSACTION ISOLATION LEVEL value` are not supported, and it will automatically disable multiplexing.
Correct syntax is: `SET SESSION TRANSACTION ISOLATION LEVEL value`
<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-default_tx_isolation</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>READ-COMMITTED</td>
    </tr>
    <tr>
        <td><b>Valid Values</b></td>
        <td>READ COMMITTED, REPEATABLE READ, and SERIALIZABLE</td>
    </tr>
</table>






### <a name="mysql-multiplexing">`mysql-multiplexing`</a>

Enable multiplexing by default. We recommend to leave multiplexing on (the default).
Please note that multiplexing can still be disabled for [other reasons](Multiplexing), enabling this parameters makes sure it never enabled.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-multiplexing</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>true</td>
    </tr>
</table>​


### <a name="mysql-enforce_autocommit_on_reads">`mysql-enforce_autocommit_on_reads`</a>

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-enforce_autocommit_on_reads</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>false</td>
    </tr>
</table>​

### <a name="mysql-eventslog_filename">`mysql-eventslog_filename`</a>

If this variable is set, ProxySQL will log all traffic to the specified filename. Note that the log file is not a text file, but a binary log with encoded traffic. The value of this variable can be set to an absolute pathname (e.g. "/data/events_log/events_log" or else a filename (e.g. "events_log") will be written to the defined data directory. A sequential number will always be suffixed in the file's extension (e.g. "events_log.00000001").

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-eventslog_filename</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>empty string, not set</td>
    </tr>
    <tr>
        <td><b>Valid Values</b></td>
        <td>A filename or absolute path</td>
    </tr>
</table>​

### <a name="mysql-eventslog_filesize">`mysql-eventslog_filesize`</a>

This variable specifies the maximum size of files created by ProxySQL logger as specified in `mysql-eventslog_filename`. When the maximum size is reached, the file is rotated.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-eventslog_filesize</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (bytes)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>104857600 (100MB)</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>1048576</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>1073741824</td>
    </tr>
</table>​

### <a name="mysql-eventslog_default_log">`mysql-eventslog_default_log`</a>
ProxySQL is able to log queries that pass through.
If there is no definition for `Log` in a matching rule in mysql_query_rules, mysql-eventslog_default_log applies.
See also https://github.com/sysown/proxysql/wiki/Query-Logging

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-eventslog_default_log</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>false</td>
    </tr>
</table>

### <a name="mysql-eventslog_format">mysql-eventslog_format</a>
  From version 2.0.6 ProxySQL can handle two different log formats:
    1 : this is the default: queries are logged in binary format (like before 2.0.6)
    2 : the queries are logged in JSON format.
  Default: 1
  See also https://github.com/sysown/proxysql/wiki/Query-Logging
<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-eventslog_format</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>1</td>
    </tr>
    <tr>
        <td><b>Valid Values</b></td>
        <td>
            1 : this is the default: queries are logged in binary format (like before 2.0.6)<br>
            2 : the queries are logged in JSON format.
        </td>
    </tr>
</table>

### <a name="mysql-forward_autocommit">`mysql-forward_autocommit`</a>

When `mysql-forward_autocommit=false` (the default), ProxySQL will track (and remember) the autocommit value that the client wants and change `autocommit` on a backend connection as needed. For example, if a client sends `set autcommit=0`, ProxySQL will just reply OK. When the client sends a DDL, proxysql will get a connection to target hostgroup, and change `autocommit` before running the DDL.

If mysql-forward_autocommit=true, `SET autocommit=0` is forwarded to the backend. `SET autocommit=0` doesn't start any transaction, the connection is set in the connection pool, and queries may execute on a different connection. If you set `mysql-forward_autocommit=true`, you should also set `mysql-autocommit_false_not_reusable=true` to prevent the connection to be returned to the connection pool. In other words, setting `mysql-forward_autocommit=false` will prevent this behaviour since the autocommit state is tracked.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-forward_autocommit</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>false</td>
    </tr>
</table>​

### <a name="mysql-free_connections_pct">`mysql-free_connections_pct`</a>

ProxySQL uses a connection pool to connect to backend servers.  
Connections to backend are never pre-allocated if there is no need, so at start up there will 0 connections to the backend.  
When application starts sending traffic to proxysql, this identifies to which backend if needs to send traffic. If there is a connection in the connection pool for that backend, that connection is used, otherwise a new connection is created.
When the connection completes serving the client's request, it is sent back to the the Hostgroup Manager. If the Hostgroup Manager determines that the connection is safe to share and the connection pool isn't full, it will place it in the connection pool. Although, not all the unused connections are kept in the connection pool.  
This variable controls the percentage of open idle connections from the total maximum number of connections for a specific server in a hostgroup.  
For each hostgroup/backend pair, the Hostgroup Manager will keep in the connection pool up to `mysql-free_connections_pct * mysql_servers.max_connections / 100` connections . Connections are kept open with periodic pings.

A connection is idle if it hasn't used since the last round of pings. The time interval between two such rounds of pings for idle connections is controlled by the variable `mysql-ping_interval_server_msec`.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-free_connections_pct</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (percentage)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>10</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>0</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>100</td>
    </tr>
</table>​

### <a name=""mysql-have_compress>`mysql-have_compress`</a>

Currently unused.

### <a name="mysql-have_ssl">`mysql-have_ssl`</a>

Introduced in ProxySQL v2.0, enables frontend SSL support (see [SSL Support](https://github.com/sysown/proxysql/wiki/SSL-Support) for more information).

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-have_ssl</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>false</td>
    </tr>
</table>​

### <a name="mysql-hostgroup_manager_verbose">`mysql-hostgroup_manager_verbose`</a>

Enable verbose logging of hostgroup manager details in ProxySQL logs (e.g. when running `LOAD MYSQL SERVERS TO RUNTIME`).

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-hostgroup_manager_verbose</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>1</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>0</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>2</td>
    </tr>
</table>​

### <a name="mysql-init_connect">`mysql-init_connect`</a>

String containing one or more SQL statements, separated by semicolons, that will be executed by the ProxySQL for each backend connection when created or initialised e.g. `SET WAIT_TIMEOUT=28800` (works similarly to MySQL's `init_connect` variable).

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-init_connect</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>empty string, not set</td>
    </tr>
    <tr>
        <td><b>Valid Values</b></td>
        <td>String containing one or more SQL statements, separated by semicolons</td>
    </tr>
</table>​

### <a name="mysql-interfaces">`mysql-interfaces`</a>

Semicolon-separated list of hostname:port entries for interfaces for incoming MySQL traffic. Note that this also supports UNIX domain sockets for the cases where the connection is done from an application on the same machine.  
Note that changing this value has no effect at runtime, if you need to change it you have to restart the proxy.  
After changing `mysql-interfaces`, you should not run `LOAD MYSQL VARIABLES TO RUNTIME` because this variable cannot be loaded at runtime. Attempt to load them at runtime will cause their reset.  
In other words, after changing `mysql-interfaces`, you need to run `SAVE MYSQL VARIABLES TO DISK` and then restart proxysql (for example using `PROXYSQL RESTART`).  


<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-interfaces</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>No</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>0.0.0.0:6033;/tmp/proxysql.sock</td>
    </tr>
    <tr>
        <td><b>Valid Values</b></td>
        <td>IP / hostname with ':' seperated port and ';' separated socket filename</td>
    </tr>
</table>​

### <a name="mysql-keep_multiplexing_variables">`mysql-keep_multiplexing_variables`</a>
Defines a list of variables that do not causes multiplexing to be disabled if queries.
For example "SELECT @@version", by default proxysql would disable multiplexing.
But because "version" is in mysql-keep_multiplexing_variables, multiplexing is not disabled.
The list is define in ProxySQL and is not dynamic. 
Default: trx_isolation,version

### <a name="mysql-max_stmts_cache">`mysql-max_stmts_cache`</a>
Set the total maximum number of statemnts that can be cached when using Prepare Statement
<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-max_stmts_cache/td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>10000</td>
    </tr>
</table>
     
 

### <a name="mysql-kill_backend_connection_when_disconnect">`mysql-kill_backend_connection_when_disconnect`</a>

When enabled the backend connection for a client connection is killed when the client disconnects (introduced in ProxySQL v2.0).

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-kill_backend_connection_when_disconnect</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>true</td>
    </tr>
</table>​

### <a name="mysql-long_query_time">`mysql-long_query_time`</a>

Threshold for counting queries passing through the proxy as 'slow'. The total number of slow queries can be found in the `stats_mysql_global` table, in the variable named `Slow_queries` (each row in that table represents one variable).

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-long_query_time</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>1000</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>0</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>1728000000</td>
    </tr>
</table>​

### <a name="mysql-max_allowed_packet">`mysql-max_allowed_packet`</a>

`mysql-max_allowed_packet` defines the maximum size of a single packet/command received by the client. It mimics the behavior of mysqld's [max_allowed_packet](http://dev.mysql.com/doc/refman/5.7/en/server-system-variables.html#sysvar_max_allowed_packet)  

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-max_allowed_packet</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (bytes)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>4194304 (4MB)</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>8192 (8KB)</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>1073741824 (1GB)</td>
    </tr>
</table>​

### <a name="mysql-max_connections">`mysql-max_connections`</a>

The maximum number of client connections that the proxy can handle. After this number is reached, new connections will be rejected with the `#HY000` error, and the error message `Too many connections`.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-max_connections</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>2048</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>1</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>1000000</td>
    </tr>
</table>​

### <a name="mysql-max_stmts_per_connection">`mysql-max_stmts_per_connection`</a>

The threshold for the number of statements that can be prepared on a backend connection before that connection is closed (prior to version 1.4.3) or reset (starting version 1.4.4). This is evaluated when a connection is returned to the connection pool.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-max_stmts_per_connection</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>20</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>1</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>1024</td>
    </tr>
</table>​


### <a name="mysql-max_transaction_time">`mysql-max_transaction_time`</a>

Sessions with active transactions running more than this timeout are killed.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-max_transaction_time</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>14400000 (4 hours)</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>1000</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>1728000000</td>
    </tr>
</table>​


### <a name="mysql-min_num_servers_lantency_awareness">`mysql-min_num_servers_lantency_awareness`</a>
Latency awareness is an algorithm uses to send traffic only to closest backends.
IE: In case of slaves in multiple AZs, ProxySQL will sends traffic only to the slaves on the same AZ.
But to trigger this algorithm, a minimum number of servers is required.
In case of 3 slaves in 3 AZs, and application/ProxySQL is in one AZ, you MAY not want to send almost all the traffic to only one slave.
<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-min_num_servers_lantency_awarenes</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>1000</td>
    </tr>
</table>


### <a name="mysql-mirror_max_concurrency">`mysql-mirror_max_concurrency`</a>

ToDo

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-mirror_max_concurrency</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>16</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>1</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>8192</td>
    </tr>
</table>​

### <a name="mysql-mirror_max_queue_length">`mysql-mirror_max_queue_length`</a>

ToDo

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-mirror_max_queue_length</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>32000</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>0</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>1048576</td>
    </tr>
</table>​

### <a name="mysql-monitor_connect_interval">`mysql-monitor_connect_interval`</a>

The interval at which the Monitor module of the proxy will try to connect to all the MySQL servers in order to check whether they are available or not.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_connect_interval</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>120000 (2 mins)</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>100</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>604800000</td>
    </tr>
</table>​

### <a name="mysql-monitor_connect_timeout">`mysql-monitor_connect_timeout`</a>

Connection timeout in milliseconds. The current implementation rounds this value to an integer number of seconds less or equal to the original interval, with 1 second as minimum. This lazy rounding is done because SSL connections are blocking calls.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_connect_timeout</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>200</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>100</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>600000</td>
    </tr>
</table>​

### <a name="mysql-monitor_enabled">`mysql-monitor_enabled`</a>

It enables or disables MySQL Monitor.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_enabled</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>true</td>
    </tr>
</table>​

### <a name="mysql-monitor_galera_healthcheck_interval">`mysql-monitor_galera_healthcheck_interval`</a>

The interval at which the proxy should connect to the backend servers in order to monitor the Galera staus of a node. Nodes can be temporarily shunned if their status is not available which is controlled by the `mysql_galera_hostgroups`.`max_transactions_behind` column in the admin interface, at a per-hostgroup level (introduced in ProxySQL v2.0).

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_galera_healthcheck_timeout</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>5000</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>50</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>604800000</td>
    </tr>
</table>​

### <a name="mysql-monitor_galera_healthcheck_max_timeout_count">`mysql-monitor_galera_healthcheck_max_timeout_count`</a>
Set the max number of times ProxySQL has timeout checking on a Galera Node before declaring it OFFLINE.
<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_galera_healthcheck_max_timeout_count</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>3</td>
    </tr>
</table>

### <a name="mysql-monitor_galera_healthcheck_timeout">`mysql-monitor_galera_healthcheck_timeout`</a>

How long the Monitor module will wait for a Galera status check reply (introduced in ProxySQL v2.0).

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_galera_healthcheck_timeout</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>800</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>50</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>600000</td>
    </tr>
</table>​

### <a name="mysql-monitor_groupreplication_healthcheck_interval">`mysql-monitor_groupreplication_healthcheck_interval`</a>

The interval at which the proxy should connect to the backend servers in order to monitor the Group Replication staus of a node. Nodes can be temporarily shunned if their status is not available which is controlled by the `mysql_group_replication_hostgroups`.`max_transactions_behind` column in the admin interface, at a per-hostgroup level.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_groupreplication_healthcheck_interval</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>5000</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>50</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>604800000</td>
    </tr>
</table>​


### <a name="mysql-monitor_groupreplication_healthcheck_timeout">`mysql-monitor_groupreplication_healthcheck_timeout`</a>

How long the Monitor module will wait for a Group Replication status check reply.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_groupreplication_healthcheck_timeout</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>800</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>50</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>600000</td>
    </tr>
</table>​

### <a name="mysql-monitor_history">`mysql-monitor_history`</a>

The duration for which the events for the checks made by the Monitor module are kept. Such events include connecting to backend servers (to check for connectivity issues), querying them with a simple query (in order to check that they are running correctly) or checking their replication lag. These logs are kept in the following admin tables:
* `mysql_server_connect_log`
* `mysql_server_ping_log`
* `mysql_server_replication_lag_log`

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_history</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>600000 (60 seconds)</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>1000</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>604800000</td>
    </tr>
</table>​

### <a name="mysql-monitor_password">`mysql-monitor_password`</a>

Specifies the password that the Monitor module will use to connect to the backends.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_password</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>monitor</td>
    </tr>
</table>​

### <a name="mysql-monitor_ping_interval">`mysql-monitor_ping_interval`</a>

The interval at which the Monitor module should ping the backend servers by using the [mysql_ping](https://dev.mysql.com/doc/refman/5.0/en/mysql-ping.html) API.

Before version 1.4.14, the default was 60000 (1 minute).  

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_ping_interval</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>8000</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>100</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>604800000</td>
    </tr>
</table>​

### <a name="mysql-monitor_ping_max_failures">`mysql-monitor_ping_max_failures`</a>

The maximum number of ping failures the Monitor module should tolerate before sending a signal to MySQL_Hostgroups_Manager to kill all connections to the backend server.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_ping_max_failures</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>3</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>1</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>1000000</td>
    </tr>
</table>​

### <a name="mysql-monitor_ping_timeout">`mysql-monitor_ping_timeout`</a>

How long the Monitor module will wait for a ping reply.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_ping_timeout</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>1000</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>100</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>600000</td>
    </tr>
</table>​

### <a name="mysql-monitor_query_interval">`mysql-monitor_query_interval`</a>

Currently unused. Will be used by the Monitor module in order to collect data about the global status of the backend servers.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_query_interval</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>60000 (1 min)</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>100</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>604800000</td>
    </tr>
</table>​

### <a name="mysql-monitor_query_timeout">`mysql-monitor_query_timeout`</a>

Currently unused. Will be used by the Monitor module in order to collect data about the global status of the backend servers.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_query_timeout</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>100</td>
    </tr>
</table>​

### <a name="mysql-monitor_read_only_interval">`mysql-monitor_read_only_interval`</a>

Defines the frequency to check the Read Only status of a backend server (in milliseconds).

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_read_only_interval</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>1000 (1 sec)</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>100</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>604800000</td>
    </tr>
</table>​

### <a name="mysql-monitor_read_only_max_timeout_count">`mysql-monitor_read_only_max_timeout_count`</a>

When the monitor thread performs a read_only check, AND the check exceeds `mysql-monitor_read_only_timeout`, repeat the read_only check up to `mysql-monitor_read_only_max_timeout_count` times before setting the slave to OFFLINE HARD.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_read_only_max_timeout_count</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>3</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>1</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>999999</td>
    </tr>
</table>​

### <a name="mysql-monitor_read_only_timeout">`mysql-monitor_read_only_timeout`</a>

The timeout for a single attempt at checking the Read Only status on a backend server from the proxy. 

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_read_only_timeout</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>800</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>100</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>600000</td>
    </tr>
</table>​

### <a name="mysql-monitor_replication_lag_interval">`mysql-monitor_replication_lag_interval`</a>

The interval at which the proxy should connect to the backend servers in order to monitor the replication lag between those that are slaves and their masters. Slaves can be temporarily shunned if the replication lag is too large. This setting is controlled by the `mysql_servers`.`max_replication_lag` column in the admin interface, at a per-hostgroup level.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_replication_lag_interval</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>10000</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>100</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>604800000</td>
    </tr>
</table>​

### <a name="mysql-monitor_replication_lag_timeout">`mysql-monitor_replication_lag_timeout`</a>

How long the Monitor module will wait for the output of `SHOW SLAVE STATUS` to be returned from the database.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_replication_lag_timeout</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>1000</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>100</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>600000</td>
    </tr>
</table>​

### <a name="mysql-monitor_replication_lag_use_percona_heartbeat">`mysql-monitor_replication_lag_use_percona_heartbeat`</a>

This variable defines the `<schema>`.`<table>` where `pt-heartbeat` information is written, when this variable is defined replication lag checks are determined based on the values in this table rather than `SHOW SLAVE STATUS`. This is empty by default, when using `pt-heartbeat` the value is typically defined as `percona.heartbeat`.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_replication_lag_use_percona_heartbeat</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td></td>
    </tr>
</table>​

### <a name="mysql-monitor_slave_lag_when_null">`mysql-monitor_slave_lag_when_null`</a>

When replication check returns that `Seconds_Behind_Master=NULL` , the value of `mysql-monitor_slave_lag_when_null` (in seconds) is assumed to be the current replication lag. This allow to either shun or keep online a server where replication is broken/stopped.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_slave_lag_when_null</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="5"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (seconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>60</td>
    </tr>
    <tr>
        <td><b>Minimum (up to 1.3.1)</b></td>
        <td>100</td>
    </tr>
    <tr>
        <td><b>Minimum (from 1.3.2 onwards)</b></td>
        <td>0</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>604800 (1 week)</td>
    </tr>
</table>​

### <a name="mysql-monitor_threads_max">`mysql-monitor_threads_max`</a>

Controls the maximum number of threads within the Monitor Module thread pool. Introduced in ProxySQL v2.0. From 1.3.2 and before 2.0 the minimum value was hardcoded.
<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_threads_max</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="5"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>128</td>
    </tr>
    <tr>
        <td><b>Minimum (from 1.3.2 onwards)</b></td>
        <td>4</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>256</td>
    </tr>
</table>​

### <a name="mysql-monitor_threads_min">`mysql-monitor_threads_min`</a>

Controls the minimum number of threads within the Monitor Module thread pool. Introduced in ProxySQL v2.0. From 1.3.2 and before 2.0 the minimum value was hardcoded.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_threads_min</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="5"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>8</td>
    </tr>
    <tr>
        <td><b>Minimum (from 1.3.2 onwards)</b></td>
        <td>2</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>16</td>
    </tr>
</table>​

### <a name="mysql-monitor_threads_queue_maxsize">`mysql-monitor_threads_queue_maxsize`</a>

The variable controls how many checks are queued before starting new monitor threads.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_threads_queue_maxsize</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="5"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>128</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>16</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>1024</td>
    </tr>
</table>​

(introduced in ProxySQL v2.0)

### `mysql-monitor_timer_cached`

`DEPRECATED`

This variable controls whether ProxySQL should use a cached (and less accurate) value of wall clock time, or not. The actual API used for this is described [here](http://stuff.onse.fi/man?program=event_base_gettimeofday_cached&section=3).

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_timer_cached</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>true</td>
    </tr>
</table>​

### <a name="mysql-monitor_username">`mysql-monitor_username`</a>

Specifies the username that the Monitor module will use to connect to the backends. The user needs only `USAGE` privileges to connect, ping and check read_only. The user needs also `REPLICATION CLIENT` if it needs to monitor replication lag.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_username</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>monitor</td>
    </tr>
</table>​

### <a name="mysql-monitor_wait_timeout">`mysql-monitor_wait_timeout`</a>

In order to avoid being disconnected the Monitor Module tunes wait_timeout on its connections to backend. This is generally a good thing, however it could become a problem if ProxySQL is acting as a "forwarder", when `mysql-monitor_wait_timeout` is set to `false` the feature is disabled.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_wait_timeout</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>true</td>
    </tr>
</table>​


### <a name="mysql-monitor_writer_is_also_reader">`mysql-monitor_writer_is_also_reader`</a>

When a node change its read_only value from 1 to 0, this variable determines if the node should be present in both hostgroups or not:

- `false` : the node will be moved in writer_hostgroup and removed from reader_hostgroup
- `true` : the node will be copied in writer_hostgroup and stay also in reader_hostgroup

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-monitor_writer_is_also_reader</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>true</td>
    </tr>
</table>​


### <a name="mysql-ping_interval_server_msec">`mysql-ping_interval_server_msec`</a>

The interval at which the proxy should ping backend connections in order to maintain them alive, even though there is no outgoing traffic. The purpose here is to keep some connections alive in order to reduce the latency of new queries towards a less frequently used destination backend server.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-ping_interval_server_msec</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>10000</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>1000</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>604800000</td>
    </tr>
</table>​

### <a name="mysql-ping_timeout_server">`mysql-ping_timeout_server`</a>

The proxy internally pings the connections it has opened in order to keep them alive. This eliminates the cost of opening a new connection towards a hostgroup when a query needs to be routed, at the cost of additional memory footprint inside the proxy and some extra traffic. This is the timeout allowed for those pings to succeed.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-ping_timeout_server</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>200</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>10</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>600000</td>
    </tr>
</table>​

### <a name="mysql-poll_timeout">`mysql-poll_timeout`</a>

The minimal timeout used by the proxy in order to detect incoming/outgoing traffic via the `poll()` system call. If the proxy determines that it should stick to a higher timeout because of its internal computations, it will use that one, but it will never use a value less than this one.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-poll_timeout</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>2000</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>10</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>20000</td>
    </tr>
</table>​

### <a name="mysql-poll_timeout_on_failure">`mysql-poll_timeout_on_failure`</a>

The timeout used in order to detect incoming/outgoing traffic after a connection error has occured. The proxy automatically tweaks its timeout to a lower value in such an event in order to be able to quickly respond with a valid connection.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-poll_timeout_on_failure</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>100</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>10</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>20000</td>
    </tr>
</table>​

### <a name="mysql-query_cache_size_MB">`mysql-query_cache_size_MB`</a>

The total amount of memory used by the Query Cache, note: the current implementation of mysql-query_cache_size_MB doesn't impose a hard limit . Instead, it is used as an argument by the purging thread.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-query_cache_size_MB</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (MB)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>256</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>0</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>10485760</td>
    </tr>
</table>​


### <a name="mysql-query_cache_stores_empty_result">`mysql-query_cache_stores_empty_result`</a>

The variable controls if resultset without rows will be cached or not (introduced in ProxySQL v2.0).

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-query_cache_stores_empty_result</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>true</td>
    </tr>
</table>​

### <a name="mysql-query_digests">`mysql-query_digests`</a>

When this variable is set to true, the proxy analyzes the queries passing through it and divides them into classes of queries having different values for the same parameters. It computes a couple of metrics for these classes of queries, all found in the `stats_mysql_query_digest` table. For more details, please refer to the [admin tables documentation](https://github.com/sysown/proxysql/wiki/Main-(runtime)#mysql_query_rules).  
It is also very important to note that query digest is required to determine when multiplexing needs to be disabled, for example in case of `TEMPORARY` tables, `SQL_CALC_FOUND_ROWS` , `GET_LOCK`, etc.  
Do not disable `mysql-query_digests` unless you are really sure it won't break your application.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-query_digests</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>true</td>
    </tr>
</table>​

### <a name="mysql-query_digests_lowercase">`mysql-query_digests_lowercase`</a>

When this variable is set to true, query digest is automatically converted to lowercase otherwise when false, query digests are case sensitive.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-query_digests_lowercase</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>false</td>
    </tr>
</table>​

### <a name="mysql-query_digests_max_digest_length">`mysql-query_digests_max_digest_length`</a>

Defines the maximum length of `digest_text` as then reported in `stats_mysql_query_digest`

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-query_digests_max_digest_length</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="5"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>2048</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>16</td>
    </tr>
    <tr>
        <td><b>Maximum (up to 1.3.1)</b></td>
        <td>65000</td>
    </tr>
    <tr>
        <td><b>Maximum (from 1.3.2 onwards)</b></td>
        <td>1048576</td>
    </tr>
</table>​

### <a name="mysql-query_digests_max_query_length">`mysql-query_digests_max_query_length`</a>

Defines the maximum query length processed when computing query's `digest` and `digest_text`

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-query_digests_max_query_length</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="5"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>65000</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>16</td>
    </tr>
    <tr>
        <td><b>Maximum (up to 1.3.1)</b></td>
        <td>65000</td>
    </tr>
    <tr>
        <td><b>Maximum (from 1.3.2 onwards)</b></td>
        <td>16777216</td>
    </tr>
</table>​

### <a name="mysql-query_digests_no_digits">`mysql-query_digests_no_digits`</a>
When active ProxySQL will replace all numbers in the query to '?' signs for generating digest. This functionality can be controlled by 
Testing was done with queries like this: CALL `76_char_14`.gen_v67_chr_camp_item_upsert_5();
<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-query_digests_no_digits</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="5"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>false</td>
    </tr>
</table>

### <a name="mysql-query_digests_normalize_digest_text">`mysql-query_digests_normalize_digest_text`</a>
When set to FALSE (default), ProxySQL will cache the SQL digest and related information in the table stats.stats_mysql_query_digest by schema.
When this variable is TRUE, queries statistics store digest_text on a different internal hash table. In this way ProxySQL will be able to normalize data, digest_text is internally stored elsewhere, and it deduplicate data.
When you query stats_mysql_query_digest, the data is merged together. 
This drastically reduces memory usage on setups with many schemas but similar queries patterns
<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-query_digests_normalize_digest_text</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="5"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>false</td>
    </tr>
</table>    
    
### <a name="mysql-query_digests_replace_null">`mysql-query_digests_replace_null`</a>
When TRUE, ProxySQL will replace NULLs when creating the Query digest with '?'.
This approach will normalize statements like the following:
```SQL
    SQL                                       Digest
    INSERT INTO tablename(id) VALUES (1);     INSERT INTO tablename(id) VALUES (?);
    INSERT INTO tablename(id) VALUES (NULL);  INSERT INTO tablename(id) VALUES (?);
    CALL spa(NULL, null, NULL, null);         CALL spa(?, ?, ?, ?);
    CALL spa(1, null, NULL, 4);               CALL spa(?, ?, ?, ?);
    CALL spa(1, 2, 3, 4);                     CALL spa(?, ?, ?, ?);
```              
<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-query_digests_replace_null</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="5"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>false</td>
    </tr>
</table>

### <a name="mysql-query_digests_track_hostname">`mysql-query_digests_track_hostname`</a> 
If active it reports the original client address in the table stats_mysql_query_digest
See also https://github.com/sysown/proxysql/wiki/STATS-(statistics)
<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-query_digests_track_hostname</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="5"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>false</td>
    </tr>
</table> 



### <a name="mysql-query_processor_iterations">`mysql-query_processor_iterations`</a>

If `mysql_query_rules`.`flagOUT` is set and `mysql-query_processor_iterations` is greater than 0, a matching rule will set `flagIN` and starts processing rules from the beginning up to `mysql-query_processor_iterations` iterations.  
Therefore, mysql-query_processor_iterations allows to jump back to previous `mysql_query_rules`.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-query_processor_iterations</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="5"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>0</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>0</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>1000000</td>
    </tr>
</table>​

### <a name="mysql-query_processor_regex">`mysql-query_processor_regex`</a>
This variable defines which regex engine to use:
* 1 : [PCRE](http://www.pcre.org/)
* 2 : [RE2](https://github.com/google/re2) 

Before version v1.4.0, only RE2 was available, *CASELESS* was always enabled, and *GLOBAL* was always disabled.  
Starting from v1.4.0, both PCRE and RE2 are available. Now both PCRE and RE2 support *CASELESS* and *GLOBAL* using [re_modifiers](MySQL-Query-Rules).  
Although, RE2 doesn't support both *CASELESS* and *GLOBAL* at the same time if they are both configured in [re_modifiers](MySQL-Query-Rules). For this reason, the default regex engine was changed to PCRE.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td colspan="2">mysql-query_processor_regex</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td colspan="2">Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="5"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td colspan="2">Integer</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td><b>PCRE</b></td>
        <td colspan="2">1</td>
    </tr>
    <tr>
        <td valign="top" rowspan="2"><b>Valid Values</b></td>
        <td><b>PCRE</b></td>
        <td>1</td>
    </tr>
    <tr>
        <td><b>RE2</b></td>
        <td>2</td>
    </tr>
</table>​

### <a name="mysql-query_retries_on_failure">`mysql-query_retries_on_failure`</a>

In case of failures while running a query, the same can be retried `mysql-query_retries_on_failure` times.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-query_retries_on_failure</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>1</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>0</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>1000</td>
    </tr>
</table>​

### <a name="mysql-reset_connection_algorithm">`mysql-reset_connection_algorithm`</a>

When `reset_connection_algorithm = 2`, MySQL_Thread itself tries to reset connections instead of relying on connections purger HGCU_thread_run() (introduced in ProxySQL v2.0), `reset_connection_algorithm` can be set to:

- `1` = legacy algorithm used in ProxySQL v1.x
- `2` = algorithm new since ProxySQL v2.0 (new default)


<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-reset_connection_algorithm</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>2</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>1</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>2</td>
    </tr>
</table>​

### <a name="mysql-server_capabilities">`mysql-server_capabilities`</a>

The bitmask of MySQL capabilities (encoded as bits) with which the proxy will respond to clients connecting to it.  
This is useful in order to prevent certain features from being used, although it is planned to be deprecated in the future.  
The default capabilities are:

```c++
server_capabilities = CLIENT_FOUND_ROWS | CLIENT_PROTOCOL_41 | CLIENT_IGNORE_SIGPIPE | CLIENT_TRANSACTIONS | CLIENT_SECURE_CONNECTION | CLIENT_CONNECT_WITH_DB | CLIENT_SSL;
```

More details about server capabilities in the [official documentation](https://dev.mysql.com/doc/internals/en/capability-flags.html#packet-Protocol::CapabilityFlags).

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-server_capabilities</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>47626</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>10</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>65535</td>
    </tr>
</table>​

### <a name="mysql-server_version">`mysql-server_version`</a>

The server version with which the proxy will respond to the clients. Note that regardless of the versions of the backend servers, the proxy will respond with this.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-server_version</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>5.5.30</td>
    </tr>
</table>​

### <a name="mysql-servers_stats">`mysql-servers_stats`</a>

Currently unused. Will be removed in a future version.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-servers_stats</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>true</td>
    </tr>
</table>​

### `mysql-session_debug`

`DEPRECATED`

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-session_debug</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>true</td>
    </tr>
</table>​

### <a name="mysql-session_idle_ms">`mysql-session_idle_ms`</a>

Starting from v1.3.0 , each MySQL_Thread has an auxiliary thread that is responsible to handle idle sessions (client connections). `mysql-session_idle_ms` defines when a session is idle and passed from the main thread to the auxiliary thread.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-session_idle_ms</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>1000</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>100</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>3600000</td>
    </tr>
</table>​

### <a name="mysql-session_idle_show_processlist">`mysql-session_idle_show_processlist`</a>

`mysql-session_idle_show_processlist` defines if in idle session (as defined by `mysql-session_idle_ms`) should be listed in `SHOW PROCESSLIST` (or in general, in `stats_mysql_processlist` table). For performance reason, idle sessions are not listed by default.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-session_idle_show_processlist</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>false</td>
    </tr>
</table>​

### <a name="mysql-sessions_sort">`mysql-sessions_sort`</a>

Sessions are conversations between a MySQL client and a backend server in the proxy. Sessions are generally processed in a stable order but in certain scenarios (like using a transaction workload, which makes sessions bind to certain MySQL connections from the pool), processing them in the same order leads to starvation.

This variable controls whether sessions should be processed in the order of waiting time, in order to have a more balanced distribution of traffic among sessions.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-sessions_sort</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>true</td>
    </tr>
</table>​

### <a name="mysql-set_query_lock_on_hostgroup">`mysql-set_query_lock_on_hostgroup`</a>
When active (default from 2.0.6), if SET statement is used in multi-statements commands or if parsing of SET statement it is not successful, both multiplexing and query routing is disabled. The client will remain bind to a single backend connections. Any SET statement that ProxySQL doesn't understands will disables multiplexing and routing.
<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-set_query_lock_on_hostgroup</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>true</td>
    </tr>
</table>

### <a name="mysql-show_processlist_extended">`mysql-show_processlist_extended`</a>
When active ProxySQL will show extended information in JSON format about the processes running.
Information will be available in stats_mysql_processlist.extended_info 
<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-show_processlist_extended/td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>false</td>
    </tr>
</table>
### <a name="mysql-shun_on_failures">`mysql-shun_on_failures`</a>

The number of connection errors tolerated to the same server within an interval of 1 second until it is automatically shunned temporarily. For now, this can not be disabled by setting it to a special value, so if you want to do that, you can increase it to a very large value.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-shun_on_failures</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>5</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>0</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>10000000</td>
    </tr>
</table>​

### <a name="mysql-shun_recovery_time_sec">`mysql-shun_recovery_time_sec`</a>

A backend server that has been automatically shunned will be recovered after at least this amount of time.  
Note that if ProxySQL isn't handling client traffic, there is no actual hard guarantee of the exact timing, but in practice it shouldn't exceed this value by more than a couple of seconds.  

Self tuning:
* `mysql-shun_recovery_time_sec` should always be less than `mysql-connect_timeout_server_max/1000` , in order to prevent that a server is taken out for so long that an error is returned to the client. If `mysql-shun_recovery_time_sec` > `mysql-connect_timeout_server_max/1000` , the smaller of the two is used. (see #530)  
* if only one server is present in a hostgroup and `mysql-shun_recovery_time_sec > 1` , the server is automatically brought back online after 1 second

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-shun_recovery_time_sec</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (seconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>10</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>0</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>31536000</td>
    </tr>
</table>​

### <a name="mysql-ssl_p2s_ca">`mysql-ssl_p2s_ca`</a>

SSL CA to be used for backend connections.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-ssl_p2s_ca</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="3"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td></td>
    </tr>
</table>​

### <a name="mysql-ssl_p2s_cert">`mysql-ssl_p2s_cert`</a>

SSL Certificate to be used for backend connections.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-ssl_p2s_cert</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="3"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td></td>
    </tr>
</table>​

### <a name="mysql-ssl_p2s_cipher">`mysql-ssl_p2s_cipher`</a>

SSL Cipher to be used for backend connections (MySQL CIPHER list can be found [here](https://dev.mysql.com/doc/refman/8.0/en/encrypted-connection-protocols-ciphers.html)).

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-ssl_p2s_cipher</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="3"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td></td>
    </tr>
</table>​

### <a name="mysql-ssl_p2s_key">`mysql-ssl_p2s_key`</a>

SSL Key to be used for backend connections.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-ssl_p2s_key</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="3"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>String</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td></td>
    </tr>
</table>​

### <a name="mysql-stacksize">`mysql-stacksize`</a>

The stack size to be used with the background threads that the proxy uses to handle MySQL traffic and connect to the backends. Note that changing this value has no effect at runtime, if you need to change it you have to restart the proxy.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-stacksize</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (bytes)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>1048576</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>262144</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>4194304</td>
    </tr>
</table>​

### <a name="mysql-stats_time_backend_query">`mysql-stats_time_backend_query`</a>

Enables / disables collection of backend query CPU time statistics.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-stats_time_backend_query </td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default (up to 1.4.3)</b></td>
        <td>true</td>
    </tr>
    <tr>
        <td><b>Default (from 1.4.4 onwards)</b></td>
        <td>false</td>
    </tr>
</table>​

### <a name="mysql-stats_time_query_processor">`mysql-stats_time_query_processor`</a>

Enables / disables collection of query processor CPU time statistics.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-stats_time_query_processor </td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default (up to 1.4.3)</b></td>
        <td>true</td>
    </tr>
    <tr>
        <td><b>Default (from 1.4.4 onwards)</b></td>
        <td>false</td>
    </tr>
</table>​

### <a name="mysql-tcp_keepalive_time">`mysql-tcp_keepalive_time`</a>
When mysql-use_tcp_keepalive is active, ProxySQL will send a KeepAlive to the destination every tcp_keepalive_time in seconds
<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-tcp_keepalive_time</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (seconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>0</td>
    </tr>
</table>

### <a name="mysql-use_tcp_keepalive">`mysql-use_tcp_keepalive`</a>
When active ProxySQL will send KeepAlive signal during the client open session.
<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-tcp_keepalive_time</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>false</td>
    </tr>
</table>


### <a name="mysql-threads">`mysql-threads`</a>

The number of background threads that ProxySQL uses in order to process MySQL traffic. Note that there are other "administrative" threads on top of these, such as:
* the admin interface thread
* the monitoring module threads that interact with the backend servers (one for monitoring connectivity, one for pinging the servers and one for monitoring the replication lag)
* occasional temporary threads created in order to kill long running queries that have become unresponsive
* background threads used by the libmariadbclient library in order to make certain interactions with MySQL servers async

Note that changing this value has no effect at runtime, if you need to change it you have to restart the proxy.  
After changing `mysql-threads`, you should not run `LOAD MYSQL VARIABLES TO RUNTIME` because this variable cannot be loaded at runtime. Attempt to load them at runtime will cause their reset.  
In other words, after changing `mysql-threads`, you need to run `SAVE MYSQL VARIABLES TO DISK` and then restart proxysql (for example using `PROXYSQL RESTART`).  

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-threads</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>No</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>4</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>1</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>255</td>
    </tr>
</table>​

### <a name="mysql-threshold_query_length">`mysql-threshold_query_length`</a>

The maximal size of an incoming SQL query to the proxy that will mark the background MySQL connection as non-reusable. This will force the proxy to open a new connection to the backend server, in order to make sure that the memory footprint of the server stays within reasonable limits.

More details about it here: https://dev.mysql.com/doc/refman/5.6/en/memory-use.html

Relevant quote from the mysqld documentation: "The connection buffer and result buffer each begin with a size equal to net_buffer_length bytes, but are dynamically enlarged up to max_allowed_packet bytes as needed. The result buffer shrinks to net_buffer_length bytes after each SQL statement."

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-threshold_query_length</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (bytes)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>524288</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>1024</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>1073741824</td>
    </tr>
</table>​

### <a name="mysql-threshold_resultset_size">`mysql-threshold_resultset_size`</a>

If a resultset returned by a backend server is bigger than this, proxysql will start sending the result to the MySQL client that was requesting the result in order to limit its memory footprint.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-threshold_resultset_size</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (bytes)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>4194304 (4MB)</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>1024</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>1073741824</td>
    </tr>
</table>​

Default value: `4194304` (bytes, the equivalent of 4 MB)

### <a name="mysql-throttle_connections_per_sec_to_hostgroup">`mysql-throttle_connections_per_sec_to_hostgroup`</a>

ToDo

### <a name="mysql-throttle_max_bytes_per_second_to_client">`mysql-throttle_max_bytes_per_second_to_client`</a>

ToDo

### <a name="mysql-throttle_ratio_server_to_client">`mysql-throttle_ratio_server_to_client`</a>

ToDo

### <a name="mysql-verbose_query_error">`mysql-verbose_query_error`</a>
When active ProxySQL will print additional information in case of error like: user, schema,digest_text, address, port.
<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-verbose_query_error</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Boolean</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>false</td>
    </tr>
</table>

### <a name="mysql-wait_timeout">`mysql-wait_timeout`</a>

If a proxy session (which is a conversation between a MySQL client and a ProxySQL) has been idle for more than this threshold, the proxy will kill the session.

<table>
    <tr>
        <td valign="top" rowspan="2"><b>System Variable</b></td>
        <td><b>Name</b></td>
        <td>mysql-wait_timeout</td>
    </tr>
    <tr>
        <td><b>Dynamic</b></td>
        <td>Yes</td>
    </tr>
    <tr>
        <td valign="top" rowspan="4"><b>Permitted Values</b></td>
        <td><b>Type</b></td>
        <td>Integer (milliseconds)</td>
    </tr>
    <tr>
        <td><b>Default</b></td>
        <td>28800000 (8 hours)</td>
    </tr>
    <tr>
        <td><b>Minimum</b></td>
        <td>0</td>
    </tr>
    <tr>
        <td><b>Maximum</b></td>
        <td>1728000000</td>
    </tr>
</table>



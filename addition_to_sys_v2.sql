USE sys;


DROP VIEW IF EXISTS gr_member_routing_candidate_status;

DROP FUNCTION IF EXISTS IFZERO;
DROP FUNCTION IF EXISTS LOCATE2;
DROP FUNCTION IF EXISTS GTID_NORMALIZE;
DROP FUNCTION IF EXISTS GTID_COUNT;
DROP FUNCTION IF EXISTS gr_applier_queue_length;
DROP FUNCTION IF EXISTS gr_member_in_primary_partition;
DROP FUNCTION IF EXISTS gr_transactions_to_cert;

DELIMITER $$

CREATE FUNCTION IFZERO(a INT, b INT)
RETURNS INT
DETERMINISTIC
RETURN IF(a = 0, b, a)$$

CREATE FUNCTION LOCATE2(needle TEXT(10000), haystack TEXT(10000), offset INT)
RETURNS INT
DETERMINISTIC
RETURN IFZERO(LOCATE(needle, haystack, offset), LENGTH(haystack) + 1)$$

CREATE FUNCTION GTID_NORMALIZE(g TEXT(10000))
RETURNS TEXT(10000)
DETERMINISTIC
RETURN GTID_SUBTRACT(g, '')$$

CREATE FUNCTION GTID_COUNT(gtid_set TEXT(10000))
RETURNS INT
DETERMINISTIC
BEGIN
  DECLARE result BIGINT DEFAULT 0;
  DECLARE colon_pos INT;
  DECLARE next_dash_pos INT;
  DECLARE next_colon_pos INT;
  DECLARE next_comma_pos INT;
  SET gtid_set = GTID_NORMALIZE(gtid_set);
  SET colon_pos = LOCATE2(':', gtid_set, 1);
  WHILE colon_pos != LENGTH(gtid_set) + 1 DO
     SET next_dash_pos = LOCATE2('-', gtid_set, colon_pos + 1);
     SET next_colon_pos = LOCATE2(':', gtid_set, colon_pos + 1);
     SET next_comma_pos = LOCATE2(',', gtid_set, colon_pos + 1);
     IF next_dash_pos < next_colon_pos AND next_dash_pos < next_comma_pos THEN
       SET result = result +
         SUBSTR(gtid_set, next_dash_pos + 1,
                LEAST(next_colon_pos, next_comma_pos) - (next_dash_pos + 1)) -
         SUBSTR(gtid_set, colon_pos + 1, next_dash_pos - (colon_pos + 1)) + 1;
     ELSE
       SET result = result + 1;
     END IF;
     SET colon_pos = next_colon_pos;
  END WHILE;
  RETURN result;
END$$

CREATE FUNCTION gr_applier_queue_length()
RETURNS INT
DETERMINISTIC
BEGIN
  RETURN (SELECT sys.gtid_count( GTID_SUBTRACT( (SELECT
Received_transaction_set FROM performance_schema.replication_connection_status
WHERE Channel_name = 'group_replication_applier' ), (SELECT
@@global.GTID_EXECUTED) )));
END$$

CREATE FUNCTION gr_member_in_primary_partition()
 RETURNS varchar(20) CHARSET utf8mb4
    READS SQL DATA
    DETERMINISTIC
BEGIN
    DECLARE myReturn VARCHAR(20);
		DECLARE myError INT DEFAULT 0;
		
    DECLARE CONTINUE HANDLER FOR 1242 SET myError = 1242;
 
		  (SELECT IF( MEMBER_STATE='ONLINE' AND ((SELECT COUNT(*) FROM
performance_schema.replication_group_members WHERE MEMBER_STATE != 'ONLINE') >=
((SELECT COUNT(*) FROM performance_schema.replication_group_members)/2) = 0),
'YES', 'NO' ) into myReturn FROM performance_schema.replication_group_members JOIN
performance_schema.replication_group_member_stats rgms USING(member_id) WHERE rgms.MEMBER_ID=@@SERVER_UUID )  ;

    IF myError > 0 THEN
        GET DIAGNOSTICS CONDITION 1
        @p1 = RETURNED_SQLSTATE, @p2 = MESSAGE_TEXT;
        select @p2 into myReturn;
        RETURN myReturn;
    END IF;
    IF myReturn IS NULL Then 
	   RETURN 'NO';
    END IF;		
    RETURN myReturn;

END$$

CREATE FUNCTION `gr_transactions_to_cert`() RETURNS int
    DETERMINISTIC
BEGIN
DECLARE transactions_to_cert INT DEFAULT 0;
select  performance_schema.replication_group_member_stats.COUNT_TRANSACTIONS_IN_QUEUE into transactions_to_cert

    FROM
        performance_schema.replication_group_member_stats where MEMBER_ID=@@SERVER_UUID; 

    IF transactions_to_cert IS NULL THEN 
	   RETURN 0;
    END IF;

RETURN transactions_to_cert;


END$$

CREATE VIEW gr_member_routing_candidate_status AS

SELECT 
        sys.gr_member_in_primary_partition() AS viable_candidate,
        IF((SELECT 
                    ((SELECT 
                                GROUP_CONCAT(performance_schema.global_variables.VARIABLE_VALUE
                                        SEPARATOR ',')
                            FROM
                                performance_schema.global_variables
                            WHERE
                                (performance_schema.global_variables.VARIABLE_NAME IN ('read_only' , 'super_read_only'))) <> 'OFF,OFF')
                           
                ),
            'YES',
            'NO') AS read_only,
        sys.gr_applier_queue_length() AS transactions_behind,
        sys.gr_transactions_to_cert() AS transactions_to_cert;$$

DELIMITER ;


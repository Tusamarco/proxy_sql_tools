#!/usr/bin/perl

use Time::HiRes qw(gettimeofday nanosleep);
use POSIX qw(tzset strftime);
use strict;
use DBI;

    #Print time from invocation with milliseconds
    sub get_time($){
      my $timeType = shift;
        $ENV{TZ} = 'UTC';
        tzset;
        my $t = gettimeofday();
        my $date = strftime "%Y/%m/%d %H:%M:%S", localtime $t;

        if($timeType == 1){return ($date= sprintf "%06d", ($t-int($t))*1000000); }
        elsif ($timeType == 2){return $date;}
        elsif ($timeType == 3){return ($t);}
        elsif ($timeType == 4){
          return $t;}
        else {return ($date .= sprintf ".%03d", ($t-int($t))*1000);}
      
    }
  
    
sub get_connection($$$$) {
      
      my $dsn  = shift;
      my $user = shift;
      my $pass = shift;
      my $SPACER = shift;
      my $dbh = DBI->connect($dsn
                    , $user,$pass
                    , { RaiseError => 0
                      , PrintError => 0
                      , AutoCommit => 0
                      }
                    );
      
      if (!defined($dbh)) {
      print("Cannot connect to $dsn as $user\n");
        die();
        return undef;
      }
      
      return $dbh;
    }
my $user = 'app_ndb';
my $schema = 'test';
my $ip = '192.168.4.11';
my $port = 6033;
my $engine='innodb';
my $dbh = get_connection('DBI:mysql:'.$schema.':'.$ip.':'.$port,$user,'test',' ');
      if(!defined $dbh){
          return undef;
      }
      
my $dbh2 = get_connection('DBI:mysql:'.$schema.':'.$ip.':'.$port,$user,'test',' ');
      if(!defined $dbh){
          return undef;
      }      
my $maxReachedLag=0;
my $numberOfcallWithLag=0;

#Setup */
print get_time(2);
$dbh->do('DROP TABLE IF EXISTS '.$schema.'.joinit');
$dbh->do('CREATE TABLE IF NOT EXISTS `'.$schema.'`.`joinit` (
  `i` bigint(11) NOT NULL AUTO_INCREMENT,
  `s` char(255) DEFAULT NULL,
  `t` datetime NOT NULL,
  `g` bigint(11) NOT NULL,
  KEY(`i`, `t`),
  PRIMARY KEY(`i`)
) ENGINE=$engine  DEFAULT CHARSET=utf8;');
my $date1=get_time(2) ;
my $starTest=get_time(3);

# Populate the test Table
$dbh->do("INSERT INTO $schema.joinit VALUES (NULL, uuid(), time('$date1'),  (FLOOR( 1 + RAND( ) *60 )));");
$dbh->do("INSERT INTO $schema.joinit SELECT NULL, uuid(), time('$date1'),  (FLOOR( 1 + RAND( ) *60 )) FROM $schema.joinit;");
$dbh->do("INSERT INTO $schema.joinit SELECT NULL, uuid(), time('$date1'),  (FLOOR( 1 + RAND( ) *60 )) FROM $schema.joinit;");
$dbh->do("INSERT INTO $schema.joinit SELECT NULL, uuid(), time('$date1'),  (FLOOR( 1 + RAND( ) *60 )) FROM $schema.joinit;");
$dbh->do("INSERT INTO $schema.joinit SELECT NULL, uuid(), time('$date1'),  (FLOOR( 1 + RAND( ) *60 )) FROM $schema.joinit;");
$dbh->do("INSERT INTO $schema.joinit SELECT NULL, uuid(), time('$date1'),  (FLOOR( 1 + RAND( ) *60 )) FROM $schema.joinit;");
$dbh->do("INSERT INTO $schema.joinit SELECT NULL, uuid(), time('$date1'),  (FLOOR( 1 + RAND( ) *60 )) FROM $schema.joinit;");
$dbh->do("INSERT INTO $schema.joinit SELECT NULL, uuid(), time('$date1'),  (FLOOR( 1 + RAND( ) *60 )) FROM $schema.joinit;");
$dbh->do("INSERT INTO $schema.joinit SELECT NULL, uuid(), time('$date1'),  (FLOOR( 1 + RAND( ) *60 )) FROM $schema.joinit;");
$dbh->do("INSERT INTO $schema.joinit SELECT NULL, uuid(), time('$date1'),  (FLOOR( 1 + RAND( ) *60 )) FROM $schema.joinit;");
$dbh->do("INSERT INTO $schema.joinit SELECT NULL, uuid(), time('$date1'),  (FLOOR( 1 + RAND( ) *60 )) FROM $schema.joinit;");
$dbh->do("INSERT INTO $schema.joinit SELECT NULL, uuid(), time('$date1'),  (FLOOR( 1 + RAND( ) *60 )) FROM $schema.joinit;");
$dbh->do("INSERT INTO $schema.joinit SELECT NULL, uuid(), time('$date1'),  (FLOOR( 1 + RAND( ) *60 )) FROM $schema.joinit;");
$dbh->do("INSERT INTO $schema.joinit SELECT NULL, uuid(), time('$date1'),  (FLOOR( 1 + RAND( ) *60 )) FROM $schema.joinit;");
$dbh->do("INSERT INTO $schema.joinit SELECT NULL, uuid(), time('$date1'),  (FLOOR( 1 + RAND( ) *60 )) FROM $schema.joinit;");
$dbh->commit();
#$dbh->prepare("set SESSION wsrep_sync_wait=0")->execute();
sleep(3);


my $sth = $dbh->prepare("SELECT COUNT(i) FROM $schema.joinit");
$sth->execute();
my $rows;
while (my $ref = $sth->fetchrow_hashref()) {
         $rows = $ref->{'COUNT(i)'};
}

print get_time(2) . "\n Starting to RUN the test with $rows number of rows\n";


my $date2=get_time(2);

my $sth2 = $dbh->prepare("SELECT i FROM joinit order by i");
$sth2->execute();

#Cycle for all EXSISTING IDs
my $iCountOk = 0 ;
my $loops = 0 ;
my $totlagtime = 0;
while (my $ref = $sth2->fetchrow_hashref()) {
  my $currrentID = $ref->{'i'};
  my $result; 
  $iCountOk++ ;
  $loops++;
  #Update dates to make the record different
  
  $sth = $dbh->prepare("UPDATE $schema.joinit SET t = '$date2' WHERE i = $currrentID")->execute();
  #Forcing a commit (for galera or GR this will become a writeset)
  
  
  #starting to calculate the lag/latency after the commit this will include the query time 
  $dbh->commit();
  my $firstReadTime= get_time(4);
  my $secondReadTime=0;
  
  #nanosleep(15613000);
  
  #Read the updated record, when using ProxySQL this call SHOULD go to another server
  $result = $dbh->prepare("SELECT i FROM $schema.joinit WHERE t = '$date2' AND i = $currrentID")->execute();
   
  #If we get no row, this means that the write has not be committed yet on the serving node
  if($result == 0)
  {
      $result = 0;
      $numberOfcallWithLag++;
      
      print get_time(2) . " Dirty Read Detected on i $currrentID . . .";
  
      while($result != 1){
        #crazy looping until we get the record.
        # !!! NOTE this do not guarantee we run the selct against the same server, but that we get the record back
        #print("SELECT i FROM $schema.joinit WHERE t = '$date2' AND i = $currrentID \n");
        $result = $dbh->prepare("SELECT i FROM $schema.joinit WHERE t = '$date2' AND i = $currrentID")->execute();
        $secondReadTime=get_time(4);
      }
      print " After ".int(($secondReadTime-$firstReadTime)*1000000)." microseconds, Loop $loops rows found $result \n";
  } else {
    $secondReadTime=get_time(4);
    #print get_current_time(). " i $currrentID is ok in ".($secondReadTime - $firstReadTime)." microseconds  rows= $result\n";
  }
  if(int(($secondReadTime-$firstReadTime)*1000000) > $maxReachedLag){
        $maxReachedLag = int(($secondReadTime-$firstReadTime)*1000000);
  }


  #convert difference in microseconds
  my $diff = int(($secondReadTime-$firstReadTime)*1000000);
  $totlagtime = $diff + $totlagtime;
  if($iCountOk == 200){
      print "Status report at id ${currrentID} current lag average ".int($totlagtime/$loops)." total lag $totlagtime \n";
      $iCountOk =0;
  }
}
$dbh->disconnect if (defined $dbh);
my $endTime =  get_time(3);
print "Test run for #loops: $rows \nLag exceptions: $numberOfcallWithLag \nMax Lag time reached: $maxReachedLag  microseconds (us)\n";
print "Average lag ".int($totlagtime/$loops) ." microseconds\n";
print "Total test time ". ($endTime - $starTest) ." seconds"; 


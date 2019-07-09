# # !/bin/sh -x


DB_USER="root"
DB_PASS="vagrant"
REPLICATION_USER="replication"
REPLICATION_PASS="replication"
MASTER_NODE="master"

################################################################ FUNCTION START


provision_server() {
        SERVER_NAME=$1
	echo "I'm $SERVER_NAME"
                          echo -e  "\e[40;38;5;82mChecking pre-requisites  \e[0m\n \e[40;38;5;82m==> Percona  MySQL repository \e[0m"

                                                                 if  [ `rpm -qa percona-release|wc -l` -eq 0 ]; then
                                                                     echo -e  "\e[40;38;5;99m     * Percona repo not installed  - Started installation . \e[0m"
                                                                     sudo rm -f /etc/my.cnf
                                                                     yum install https://repo.percona.com/yum/percona-release-latest.noarch.rpm -y -q
                                                                  else
                                                                     echo -e  "\e[40;38;5;99m     * Percona repo already installed\e[0m"
                                                                  fi

                         echo -e "\e[40;38;5;82m ==> Checking MySQL server  \e[0m"
 



                         if  [ `rpm -qa Percona-Server-server-57|wc -l` -ne 0 ]; then
                                                                 echo -e  "\e[40;38;5;99m     * Observed that Percona MySQL already installed. \e[0m"
                                                                 if  [ `pidof mysqld|wc -l` -eq 0 ]; then
                                                                        echo -e  "\e[40;38;5;99m     * MySQL not running - Starting MySQL . \e[0m"
                                                                        service mysqld start
                                                                        echo -e  "  MySQL is running on PID \e[40;38;5;32m`pidof mysqld`  \e[0m"
								else
                                                                        echo -e  "  MySQL is running on PID \e[40;38;5;32m`pidof mysqld`  \e[0m"
								 fi                                         					 			 
							 
		        else
                                                                 echo -e  "\e[40;38;5;99m     * MySQL not installed \e[0m\n \e[40;38;5;99m    * Installing Mysql 5.7 from repo \e[0m "
                                                                 echo -e  "\e[40;38;5;99m     * Cleaning existing datadirectory if exists \e[0m"
                                                                 sudo rm -rf /var/lib/mysql
                                                                 yum install Percona-Server-server-57 -q -y

								 SERVER_ID=`case $SERVER_NAME in
                                                                                      	master)
                                                                                         		echo 100
                                                                                        		;;
                                                                                       	slave)
		                                                                                        echo 101
		                                                                                        ;;  								     		 	
											     *)
													echo 1
													;;
  									     esac`

                                                                 echo -e  "\e[40;38;5;82m ==> Set required MySQL variables \e[0m\n    \e[40;38;5;99m- server_id=$SERVER_ID \e[0m\n    \e[40;38;5;99m- validate_password=OFF \e[0m\n    \e[40;38;5;99m- log-bin = mysql-bin \e[0m\n    \e[40;38;5;99m- binlog_format = ROW \e[0m\n    \e[40;38;5;99m- gtid_mode = on \e[0m\n    \e[40;38;5;99m- enforce_gtid_consistency \e[0m\n    \e[40;38;5;99m- log_slave_updates  \e[0m\n"
                                                                 echo -e  "\n \e[40;38;5;99m   * MySQL not running - Starting MySQL . \e[0m"
                                                                 service mysqld start
                                                                 sed  -i "/^\!includedir \/etc\/my.cnf.d\//i [mysqld]\nserver_id=$SERVER_ID\nvalidate_password=OFF\nlog-bin = mysql-bin\nbinlog_format = ROW\ngtid_mode = on\nenforce_gtid_consistency\nlog_slave_updates\ndatadir=/var/lib/mysql \nsocket=/var/lib/mysql/mysql.sock" /etc/my.cnf
                                                                 service mysqld restart
								 echo -e  " MySQL is running on PID \e[40;38;5;32m`pidof mysqld`  \e[0m"
								 sleep 5
                                                                 echo -e "\e[40;38;5;82m ==> Resetting initial MySQL root password \e[0m"
                                                                 pass=`sudo grep ' A temporary password is generated for' /var/log/mysqld.log |awk '{print $11}'|tail -1|sed "s/^[ \t]*//" `
                                                                 mysql -u$DB_USER -p"$pass" --connect-expired-password -e "SET PASSWORD = PASSWORD('vagrant');FLUSH PRIVILEGES;"
				 				 echo -e "\e[40;38;5;82m ==> Creating replication user \e[0m"
								 mysql -u$DB_USER -p"$DB_PASS" --connect-expired-password -e "GRANT REPLICATION SLAVE ON *.* TO  '$REPLICATION_USER'@'%' identified by '$REPLICATION_PASS';FLUSH PRIVILEGES;"								 
								 
								 
        		 fi


}


prepare_gtid()

{
        GTID=`mysql -ss -h$MASTER_NODE -ureplication -preplication -e"SHOW GLOBAL VARIABLES LIKE 'gtid_executed'"|awk '{print $2}'`
	echo -e "\e[40;38;5;82m ==> SET GTID and start replication for $1 \e[0m"
        mysql -uroot -pvagrant -e"STOP SLAVE;SET GLOBAL read_only=1;RESET MASTER;SET @@GLOBAL.GTID_PURGED='$GTID';CHANGE MASTER TO   MASTER_HOST='$MASTER_NODE', MASTER_PORT=3306,  MASTER_USER='replication', MASTER_PASSWORD='replication', MASTER_AUTO_POSITION=1;START SLAVE"

}
########################################################
###################### code starts here

 case $1 in
	master)
		provision_server $1                 
		;;
	slave)
		provision_server $1
	        prepare_gtid $1	
		;;			
	*)
		echo "Sorry, Something gone wrong in Vagrantfile"
		;;
  esac




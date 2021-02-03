#!/bin/bash
cd /home/root
mkdir mysql-backup
if [[ ${DB_USER} == "" ]]; then
	echo "Missing DB_USER env variable"
	exit 1
fi
if [[ ${DB_PASS} == "" ]]; then
	echo "Missing DB_PASS env variable"
	exit 1
fi
if [[ ${DB_HOST} == "" ]]; then
	echo "Missing DB_HOST env variable"
	exit 1
fi

databases=`mysql --user="${DB_USER}" --password="${DB_PASS}" --host="${DB_HOST}" -e "SHOW DATABASES;" | tr -d "| " | grep -v Database`
for db in $databases; do
    if [[ "$db" != "information_schema" ]] && [[ "$db" != "performance_schema" ]] && [[ "$db" != "mysql" ]] && [[ "$db" != _* ]]; then
        echo "Dumping database: $db"
        mysqldump --user="${DB_USER}" --password="${DB_PASS}" --host="${DB_HOST}" --databases $db > mysql-backup/$db.sql
    fi
done

#Compressing backup file for upload
tar -zcvf mysql-backup.tar.gz mysql-backup/
filesize=$(stat -c %s mysql-backup.tar.gz)

mfs=10
if [[ "$filesize" -gt "$mfs" ]]; then
# Uploading to s3
aws s3 cp mysql-backup.tar.gz $S3_BUCKET
fi

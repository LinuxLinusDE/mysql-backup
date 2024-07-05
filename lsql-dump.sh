# Backup storage directory 
backupfolder=/data/smbshare

# Site
site=020-RTT

# Notification email address 
recipient_email=linus.stehr@coesfeld.schule

# MySQL user
user=root

# MySQL password
password=zPd2MfReGdZh

# Number of days to store the backups 
keep_day=0

# Checkfile
ckeckfile=$backupfolder/smbready

if [ ! -f "$ckeckfile" ]; then
  echo 'Fehler: Datei '$ckeckfile ' existiert nicht.' | mailx -s "ERROR: Backup on $site was not created!" $recipient_email
  echo 'Backup-Datei existiert nicht!'
  exit 1
fi

sqlfile=$backupfolder/all-database-$(date +%d-%m-%Y_%H-%M-%S).sql
zipfile=$backupfolder/all-database-$(date +%d-%m-%Y_%H-%M-%S).zip 

# Create a backup 
sudo mysqldump -u $user -p$password --all-databases > $sqlfile 

if [ $? == 0 ]; then
  echo 'Sql dump created' 
else
  echo 'mysqldump return non-zero code' | mailx -s "ERROR: Backup on $site was not created!" $recipient_email  
  exit 
fi 

# Compress backup 
zip $zipfile $sqlfile 
if [ $? == 0 ]; then
  echo 'The backup was successfully compressed' 
else
  echo 'Error compressing backup' | mailx -s "ERROR: Backup on $site was not created!" $recipient_email 
  exit 
fi 
rm $sqlfile 
echo $zipfile | mailx -s "OK: Backup on $site was successfully created" $recipient_email 

# Delete old backups 
#find $backupfolder -mtime +$keep_day -delete
find $backupfolder -name "all-database*" -type f -mtime +$keep_day -exec rm -f {} \;

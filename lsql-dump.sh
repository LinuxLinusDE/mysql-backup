# Backup storage directory 
backupfolder=/data/smbshare

# Site
site=020-RTT

# Notification email address 
recipient_email=xxxxxxxxx

# MySQL user
user=root

# MySQL password
password=xxxxxxxxxxx

# Number of days to store the backups 
keep_day=30

# Checkfile
ckeckfile=$backupfolder/smbready

if [ ! -f "$ckeckfile" ]; then
  echo 'Fehler: Datei '$checkfile ' existiert nicht.' | mailx -s "ERROR: Backup on $site was not created!" $recipient_email
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

# After creating and compressing the current backup

# Find the most recent backup file before the current one
previous_backup=$(find $backupfolder -name "all-database*.zip" -type f -printf "%T+ %p\n" | sort -r | head -n 2 | tail -n 1 | cut -d' ' -f2-)

if [ ! -z "$previous_backup" ]; then
  # Get file sizes
  current_size=$(stat -c%s "$zipfile")
  previous_size=$(stat -c%s "$previous_backup")

  # Calculate the size difference in percentage
  size_diff=$((100 - (100 * current_size / previous_size)))

  # Check if the size difference is within acceptable range (e.g., +/- 10%)
  if [ $size_diff -gt 10 ] || [ $size_diff -lt -10 ]; then
    echo "Warning: The size difference between the current and previous backup is more than 10%." | mailx -s "WARNING: Backup size variation on $site" $recipient_email
  else
    echo "The current backup size is similar to the previous one."
  fi
else
  echo "This seems to be the first backup or the previous backup was not found."
fi

# Delete old backups 
#find $backupfolder -mtime +$keep_day -delete
find $backupfolder -name "all-database*" -type f -mtime +$keep_day -exec rm -f {} \;

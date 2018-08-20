#write out current crontab
crontab -l > mycron
#echo new cron into cron file
echo "*/5 * * * * /opt/aws-scripts-mon/mon-put-instance-data.pl --mem-used-incl-cache-buff --mem-util --disk-space-util --disk-path=/ --from-cron" >> mycron
#install new cron file
crontab mycron
rm mycron
sudo service crond restart
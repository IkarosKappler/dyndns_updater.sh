

This is a Dyndns.org updater script 
===================================

Idea
---- 
For some time I was just running my private PC with SSH and a HTTP daemon installed when I was planning to 
go somewhere and wanted to access my files and/or my system. I even let my system running over days and
nights when I offered temporary web sites running on my local host. For IP resolution I registered a dyndns
host name.
 - drawback 1: my machine will die earlier.
 - drawback 2: electricity costs.
 - drawback 3: the flopping cooler noises when I want to sleep.


Solution for the drawbacks
--------------------------
I got me a Raspberry for about 35£.
   For those who do not know what a Raspberry is: a full computer on a single board with a single-core ARM 
   processor at 700mHz, a simple graphics chip, port for a flash drive (for a debian system and for storage)
   HDMI and composite video, audio, two usb connectors and an ethernet port. And all this on a board of the 
   size of a credit card. The device runs via USB power at 700-1200mA.
   

So I got me a Raspberry and I want it to run as a server when I'm not at home.



Problem (first part)
--------------------
My router regularily fails to perform the dyndns-update on IP changes ;(
So again and again I had no access to my files.



Problem (second part)
---------------------
After about 4 days and some hardware checking I had my raspberry running: "yeah, the green LEDs are glowing!"
But when working on my home PC I still wanted it to be the dyndns host. 
When away or offline the Raspberry should do the work.
But the idea of running 2 scripts or more synchronously on different machines all accessing the same DNS 
server saying "Hello, update my address, please" was frightening me.



So I wrote this tiny script (my first real shell script) that would lookup its priority inside your local LAN
and then - if allowed - send a dyndns update. And only then.



Ther are 5 files:

 - cached_ip.txt
   This is a backup file storing the latest IP address that was used for the update.
   The file is not meant to be edited and will be created on the first run if it does not exist.


 - ip_list.txt
   Store your _local_ network addresses here (IPv4).
   Each line represents an IP address of a machine in your local network.
   You are allowed to store comments (beginning with '#').


 - dyndns_updater.sh
   The actual shell script.


 - credentials.txt
   The script will try to read the authorization credentials from this file.
   The file MUST consist of at least these three lines (additional lines will be dropped):
     - your dyndns host name
     - your dyndns user name
     - your base64-encoded username plus colon plus password
       (Example: base64_encode("testuser:secret_password"))
       This is not really secure but I didn't want to store my pw in plain text so anyone
       peeking at my monitor would read it if I had the file open.
   
   If this files does not exist the script will prompt the credentials via stdin.
   Actually this is not helpful when called by cron.d but I wanted to know how to make a
   password prompt using /bin/sh :)


- This README.txt file.



Known Issues 
------------
Later I realized that the 'gethostip' program is not included in raspbian's bind9 package,
so my updater script failed when run on the raspi.

-> I added a second mini script getipfromping.sh which would try to resolve a host's IP
   using the system's ping command (which should really be available on most systems).
-> Then I modified the old script and replace gethostip by getipfromping. Finally it worked :)
   The modified script is located at ./dyndns_updater.ping.sh




Install a cron job
------------------

To add a new cron tab type this command 
> crontab -e

and edit the opening file.
Add something like this:


# 0,10,20,30,40,50 All ten minutes
# * each hour
# * each day of month
# * each month
# * each day of week

# WARNING: do NOT add the '-f' param to the script! 
# It is part of the dyndns.org policy that clients 
# MUST NOT send repeated update requests if the IP
# did not change at all!
0,10,20,30,40,50 * * * * /path_to_your_updater_script/dyndns_updater.ping.sh


# -END-Of-CRON-FILE


Done :)


Fell free to modify and have fun!


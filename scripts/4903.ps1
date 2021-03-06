###############################################################################################################################
# Script: getmacs.ps1
# Description: Very basic script that gets mac addresses (NetBIOS table) from a list of remote hosts.
# Qodosh
# Date: 2.14.2014 
# Version: 1.1
# Usage: 
# 1. Make a text file with a list of hosts names that you want to get mac addresses from. 
# 2. Edit $strservers in-between the quotes and enter the path to your list. 
# 3. Edit $log in-between the quotes. Put the location you want to make the log file. 
#
# Location of the servers you want to grab a NetBIOS table from
$Servers = Get-Content 'C:\servers.txt'
# Location of the log file. Feel free to change.
$log = 'c:\log.txt'
# Loops through each server performing a simple nbtstat command and pipes output to log variable. 
foreach ($Server in $Servers)
{
    nbtstat -a $Server >> $log
} 
# Opens log file once operation completes
start $log

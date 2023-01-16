#     Copyright (C) 2023  Paul Colman

#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU Affero General Public License as published
#     by the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.

#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU Affero General Public License for more details.

#     You should have received a copy of the GNU Affero General Public License
#     along with this program.  If not, see <https://www.gnu.org/licenses/>.

#!/bin/bash

#Custom Parameters
. ./config/parameters.config

#Stable Parameters
date=$(date +"%Y-%m-%d")
dateTime=$(date +"%Y-%m-%d--%T")

#Setting up log file
if [ ! -d "$logDir" ]; then
  mkdir $logDir
fi

if [ ! -e "$logDir/cloudflare-zone-backup.log" ]; then
  touch -a $logDir/cloudflare-zone-backup.log
fi

#Default log file
logFile="$logDir/cloudflare-zone-backup.log"

#Log New Backup Job Started
echo $(date +"%Y-%m-%d--%T")": ##################################################" >>$logFile
echo $(date +"%Y-%m-%d--%T")": ############### Backup Job Started ###############" >>$logFile
echo $(date +"%Y-%m-%d--%T")": ##################################################" >>$logFile

#Create temp file directory if it doesn't exist
if [ ! -d "$tmpDir" ]; then
  mkdir $tmpDir
  echo $(date +"%Y-%m-%d--%T")": Created temp file directory $tmpDir" >>$logFile
else
  echo $(date +"%Y-%m-%d--%T")": Temp file directory $tmpDir exists" >>$logFile
fi

#Create backup directory if it doesn't exist
if [ ! -d "$backupTmpDir" ]; then
  mkdir $backupTmpDir
  echo $(date +"%Y-%m-%d--%T")": Created backup temp file directory $backupTmpDir" >>$logFile
else
  echo $(date +"%Y-%m-%d--%T")": Backup temp file directory $backupTmpDir exists" >>$logFile
fi

#Create backup directory if it doesn't exist
if [ ! -d "$backupDir" ]; then
  mkdir $backupDir
  echo $(date +"%Y-%m-%d--%T")": Created backup file directory $backupDir" >>$logFile
else
  echo $(date +"%Y-%m-%d--%T")": Backup file directory $backupDir exists" >>$logFile
fi

#Log API Key Validation
echo $(date +"%Y-%m-%d--%T")": API Key Validation:" >>$logFile

#Validate API Key
validateAPIkey() {
  curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
    -H "Authorization: Bearer $cloudFlareAPIToken" \
    -H "Content-Type:application/json"
}

validateAPIkey >>$logFile

#Log Zone Limit
echo "running" >>$logFile
echo $(date +"%Y-%m-%d--%T")": API validation check completed" >>$logFile
echo $(date +"%Y-%m-%d--%T")": Number of zones to export limited to "$zoneLimit" in parameters.config" >>$logFile

#Export list of DNS zones
zoneDump() {
  curl -X GET "https://api.cloudflare.com/client/v4/zones?per_page=$zoneLimit" \
    -H "Authorization: Bearer $cloudFlareAPIToken" \
    -H "Content-Type:application/json"
}

#Write Zone Dump to working file in temp directory
zoneDump >"./$tmpDir/zoneDump.data"

#Log Zone List Export Completion Message
echo $(date +"%Y-%m-%d--%T")": List of Zones Exported:" >>$logFile

#Create list of zone IDs for log file
zoneList() {
  grep -oE '"name":"[^"]*"|"id":"[^"]*"' "./$tmpDir/zoneDump.data" | grep -v "${FLAGS[@]}" | awk -F'"' '{print $4}' | paste - -
}

#Write Zone List to log file
zoneList >>$logFile
zoneList >"./$tmpDir/zoneList.data"

#Reading zone list and exporting individual zones into backup temp directory
echo $(date +"%Y-%m-%d--%T")": All existing temp backup files purged to prepare for new zone exports" >>$logFile
rm $backupTmpDir/*
while read -r id domain; do
  curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${id}/dns_records/export" \
    -H "Authorization: Bearer $cloudFlareAPIToken" \
    -H "Content-Type: application/json" >"$backupTmpDir/$domain"
done <"$tmpDir/zoneList.data"

#Create compressed backup file that contains all exported dns zones
echo $(date +"%Y-%m-%d--%T")": Compressing zone file exports into a single backup file:" >>$logFile
if zip -r $backupDir/$dateTime.cf-dns-backup.zip ./$backupTmpDir >>$logFile; then 
  echo $(date +"%Y-%m-%d--%T")": Backup file created" >>$logFile
else
  echo "Backup creation failed" >>$logFile
fi

#Cleanup of temporary files
echo $(date +"%Y-%m-%d--%T")": Evaluating Cleanup Settings" >>$logFile
if [ $runCleanup = true ]; then
  #Purge temp backup files
  if [ $rmTmpBackup = true ]; then
    echo $(date +"%Y-%m-%d--%T")": Temp backup files purged" >>$logFile
    rm $backupTmpDir/*
  else
    echo $(date +"%Y-%m-%d--%T")": Temp backup files not purged - located in $backupTmpDir" >>$logFile
  fi
  #Purge temp zone file list export
  if [ $rmZoneData = true ]; then
    echo $(date +"%Y-%m-%d--%T")": Temp zone list exports purged" >>$logFile
    rm $tmpDir/*
  else
    echo $(date +"%Y-%m-%d--%T")": Temp zone list exports not purged - located in $tmpDir" >>$logFile
  fi
  #Purge log file
  if [ $rmLog = true ]; then
    echo $(date +"%Y-%m-%d--%T")": Log file purged" >>$logFile
    rm $logDir/*
  else
    echo $(date +"%Y-%m-%d--%T")": Log file not purged" >>$logFile
  fi
else
  echo $(date +"%Y-%m-%d--%T")": Cleanup of temporary files not enabled in parameters.config" >>$logFile
fi
echo $(date +"%Y-%m-%d--%T")": Done! Backups can be found in the $backupDir directory." >>$logFile
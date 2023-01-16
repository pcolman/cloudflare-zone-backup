# cloudflare-zone-backup
Backup utility for Cloudflare DNS Zones

The cloudflare-zone-backup script was designed to leverage the Cloudflare API to discover all DNS Zones within a Cloudflare tenant and create a single compressed backup file containing individual zone file exports for every discovered zone.

Although this solution has been tested for functionality on the following platforms, your mileage may vary:
  - MacOS
  - Ubuntu 20.04

USING THE UTILITY

Review and modify the following files to meet the needs of your environment:
  - /config/parameters.config *** Be sure to add your Cloudflare API key
  - Temporarily disable temp file cleanup (runCleanup="false") until you are comforatable with your configuration settings
  - Launch the backup process by running 'backup.sh'

Note: Disable temp file cleanup during inital deployment so that you can use the temporary working files to fine tune the configuration. Reference the zoneList.data file in the .tmp directory to identify zones that you would like to exclude. Exclusions are managed in the parameters.config file.

Note: This solution requires a Cloudflare API key with DNS Zone 'Read' permissions. It is highly reccomended to limit the scope and permissions of the API used by this process to only what is necessary to read the DNS zone files.

# AzureProject
Nilavembu Herbs Project in Azure

Business Requirement:
A low cost solution based on demand of dynamic business conditions.
As the business expands across EastUS and SEA, they would like to have their DataCenter virtualised using cloud computing.
Critical Data should be made available in case of disaster.
Sales manager should access his resource from windows explorer.


Technical Requirement:


--SEA region
2 web servers with 99.95% high availability
These web services has to be utilised with proper balance with client affinity with Public IP
Selected web servers should be reachable via RDP from internet
A jump port should accessible from internet to upload contents to web servers.
Protect web server traffic restricted to allowed based on ip addresses which will be updated as warranted
Enable backup for WebServers
Have alert generated in case of 80% above cpu usage


--EastUS
EastUS server (Server11) should be accessible from internet via public IP
Establish secure Connection to SEA-EUS Azure sites
All servers should be reachable with internal ip addresses


--STORAGE Requirement
EUS based resources should provide data resiliency in case of azure datacentre failure. 
The storage should be accessible  by applications with secure access. provide access urls and keys.
Sales manager should access his resource from windows explorer.
SEA data resources must provide high resiliency in case of even multiple azure data center failures

--Azure resource 
Create Vmadmin user who can manage all VM in the subscription
Create Backup_admin user who can manage backup only in EUS servers in EURG

# Pi Monitor
This code is used to monitor pi stats via a sotred file that can be processed into zabbix

## Install
run the PiMonitorInstaller.bsx
it will ask you where to save the zabbix file

## Start Monitor
    systemctl start piMonitor.service
## Check Monitor
    systemctl status piMonitor.service
## Stop Monitor
    systemctl stop piMonitor.service
   
## Versions

### 1.1.0
#### Features
* Add ability to track Memory
#### Bugs

### 1.0.0
#### Features
Initial release
#### Bugs
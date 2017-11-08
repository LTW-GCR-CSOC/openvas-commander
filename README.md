# openvas-commander
A Bash script that can install [OpenVAS](http://www.openvas.org/) from source and streamlines its management. A modified fork of [leonov-av/openvas-commander](https://github.com/leonov-av/openvas-commander). 

## How to use

The following was tested on a [Raspberry Pi 3](https://www.raspberrypi.org) with [Ubuntu MATE](https://ubuntu-mate.org/) 16.04.2 for Raspberry Pi and a [VMWare Fusion](https://www.vmware.com/products/fusion.html) 8.5.8 virtual machine with Ubuntu MATE 16.04.2 LTS for 64-bit systems, a 2.0 GHz quad core and 4 GB of RAM. Both test machines had 32 GB of disk space and were installing OpenVAS 9.

The install process took around 1-3 hours on the VM instance, while the Raspberry Pi 3 took around 4-6 hours.

Before installing, make sure that all the latest updates for the currently installed packages have been installed.

To avoid problems during installation, run all commands as the root user (either through ```sudo su``` or ```sudo <COMMAND>```)

***Method 1: Use the automated Bash script***
```
wget https://raw.githubusercontent.com/LTW-GCR-CSOC/csoc-installation-scripts/master/openvas/openvasinstall.sh
chmod +x openvasinstall.sh
sudo ./openvasinstall.sh
```

***Method 2: Manually insert the commands***

Taken from https://avleonov.com/2017/04/10/installing-openvas-9-from-the-sources/

```
sudo su

apt-get -y install curl
apt-get -y install cmake

wget https://raw.githubusercontent.com/LTW-GCR-CSOC/openvas-commander/master/openvas_commander.sh
chmod +x openvas_commander.sh

./openvas_commander.sh --install-redis-source
./openvas_commander.sh --install-dependencies

./openvas_commander.sh --download-sources "OpenVAS-9"
./openvas_commander.sh --create-folders

./openvas_commander.sh --install-all
./openvas_commander.sh --configure-all
./openvas_commander.sh --update-content
./openvas_commander.sh --start-all
./openvas_commander.sh --rebuild-content

./openvas_commander.sh --check-proc

./openvas_commander.sh --check-status v9
./openvas_commander.sh --install-service

su <YOUR_USERNAME>
```

**Post-install**

Once it's confirmed that OpenVAS installed correctly, open a web browser and go to localhost (use either ```localhost``` or ```127.0.0.1```). The default user/password combo is ```admin/1```

## Getting help

If there is confusion on what openvas-commander can do, use ```./openvas_commander --help```

In the event OpenVAS didn't install correctly, use ```sudo ./openvas_commander.sh --check-status v9``` to narrow down the issue.

## Changes made

* Updated the dependencies installed to allow compatibility with Ubuntu MATE and enable some optional features
* The script now installs the [Redis](https://redis.io/) package from source. A separate function handles the installation and configuration. The function was taken from https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-redis-on-ubuntu-16-04
* OpenVAS can now be installed as a service and configured to auto-start on boot
* Slight cleanup of the help text

Details on the original script can be found at: http://avleonov.com/2016/06/26/openvas-commander-for-openvas-installation-and-management/

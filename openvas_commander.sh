#!/usr/bin/env bash

function install_dependencies()
{
    sudo apt-get install -y build-essential devscripts dpatch curl libassuan-dev libpcre3-dev libpth-dev libwrap0-dev libgmp-dev libgmp3-dev libgpgme11 libgpgme11-dev quilt cmake pkg-config libpcap0.8 libpcap0.8-dev uuid-runtime uuid-dev bison libksba8 libksba-dev doxygen libsql-translator-perl xmltoman sqlite3 libsqlite3-dev wamerican libhiredis0.13 libhiredis-dev libsnmp-base libsnmp-dev libmicrohttpd-dev libxml2-dev libxslt1-dev xsltproc libldap-2.4-2 libldap2-dev autoconf nmap libgnutls30 libgnutls-dev gnutls-bin libpopt-dev heimdal-dev heimdal-multidev mingw-w64 texlive-full rpm alien nsis rsync python2.7 python-setuptools checkinstall libmicrohttpd10 libmicrohttpd-dev libglib2.0-dev libperl-dev libssh2-1 libssh2-1-dev libssh-dev flex libfreeradius-client2 libfreeradius-client-dev clang-4.0
}

function install_redis_source()
{
    # https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-redis-on-ubuntu-16-04
    # Add Creative Commons note here
    # Install Redis from source
    sudo apt-get -y update
    sudo apt-get -y install build-essential tcl
    cd /tmp
    curl -O http://download.redis.io/redis-stable.tar.gz
    tar xzvf redis-stable.tar.gz
    cd redis-stable

    make
    make test
    sudo make install

    sudo mkdir /etc/redis
    cd /etc/redis
    wget https://raw.githubusercontent.com/LTW-GCR-CSOC/openvas-commander/master/InstallerFiles/redis.conf
    cd /etc/systemd/system/
    wget https://raw.githubusercontent.com/LTW-GCR-CSOC/openvas-commander/master/InstallerFiles/redis.service

    sudo adduser --system --group --no-create-home redis
    sudo mkdir /var/lib/redis
    sudo chown redis:redis /var/lib/redis
    sudo chmod 770 /var/lib/redis

    sudo systemctl start redis

    sudo systemctl enable redis

    echo -n "Redis is currently: "
    sudo systemctl is-active redis
}

function get_openvas_source_table()
{
    curl -s http://openvas.org/install-source.html | sed -e ':a;N;$!ba;s/\n/ /g' -e 's/.*<table class="dl_table"//' -e 's/<\/table>.*//' -e 's/<tr>/\n<tr>/g' | grep "<tr>" | grep -v "bgcolor"  | sed  -e 's/[ \t]*<\/t[dh]>[ \t]*/|/g' -e 's/"[ \t]*>[^<]*<\/a>//g' -e 's/<a href="//g' -e 's/[ \t]*<[/]*t[rdh]>[ \t]*//g' -e 's/|$//' | grep -v "Supports OMP "
}

function get_available_source_sets()
{
    get_openvas_source_table | head -n 1 | sed 's/|/\n/g'
}

function check_releas_name()
{
    local release_name="$1"
    is_available=`get_available_source_sets | grep "^$release_name$"`
    if [ "$is_available" == "" ]
    then
        echo "wrong release name"
    else
        echo "ok"
    fi
}

function get_source_set()
{
    local release_name="$1"
    col=`get_available_source_sets | awk -v name="$release_name" '{ if ( $0 == name ){print NR}}'`
    echo "$openvas_source_table" | awk -F"|" -v col="$col" '{ if ( NR != 1 && $1 != "" && $col != "" ){print $col}}'
}

function download_source_set()
{
    mkdir openvas 2>/dev/null
    cd openvas/
    get_source_set "$release_name" | xargs -i wget '{}'
    cd ../
}

function create_folders()
{
    cd openvas/
    find | grep ".tar.gz$" | xargs -i tar zxvfp '{}'
    cd ../
}

function install_component()
{
    local component="$1"
    cd openvas
    cd $component-* 
    mkdir build 
    cd build 
    cmake .. 
    make 
    make doc-full 
    version=`pwd | sed 's/\//\n/g' | grep "$component" | sed "s/$component-//"`
    checkinstall --pkgname "$component" --pkgversion "$version" --maintainer "openvas_commander" -y     
    cd ../../../
}


function mkcerts()
{
    
    openvas-mkcert 2>/dev/null
    openvas-mkcert-client -n -i 2>/dev/null
    openvas-manage-certs -a 2>/dev/null
}

function install_service()
{
    cd /etc/systemd/system/
    sudo wget https://raw.githubusercontent.com/LTW-GCR-CSOC/openvas-commander/master/InstallerFiles/openvas.service

    cd /usr/local/sbin/
    sudo wget https://raw.githubusercontent.com/LTW-GCR-CSOC/openvas-commander/master/InstallerFiles/openvas_launcher
    sudo chmod +x openvas_launcher

    sudo systemctl start openvas

    sudo systemctl enable openvas
}

function print_help()
{

    echo "Usage: ./openvas_commander.sh OPTION [PARAM]

 Installing dependencies:
  --install-dependencies           Install Debian packages
  --install-redis-source           Install Redis from source files and configure it for use

 Getting data from openvas.org:
  --show-releases                  Show release version, e.g. OpenVAS-9
  --show-sources RELEASE           Show RELEASE source archives
  --download-sources RELEASE       Download RELEASE sources archives

 Process software components:
  --create-folders                 Create folders for sources archives

  --install-all                    Install all components
  --install-component COMPONENT    Install COMPONENT

  --uninstall-all                  Uninstall all components
  --uninstall-component COMPONENT  Uninstall COMPONENT

 Configuration:
  --configure-all                  Configure all components
  --delete-admin                   Delete OpenVAS admin account

 Process software components:
  --update-content                 Update OpenVAS NVT, OVAL and CERT content
  --update-content-nvt             Update only OpenVAS NVT content
  --rebuild-content                Rebuild database

 Manage processes:
  --start-all                      Start openvasmd, openvassd and gsad processes
                                   Use --check-proc to make sure that processes ready
  --kill-all                       Kill openvasmd, openvassd and gsad processes
  --check-proc                     Check state of openvasmd, openvassd and gsad processes

 Check installation status:
  --check-status [VERSION]         Download and run openvas-check-setup tool
                                   \"v9\" by default
 Post-install:
  --install-service                Install OpenVAS service and launcher script
                                   Will configure OpenVAS to launch on startup
                                   NOTE: After logging in, around 5 minutes will be needed 
                                   before OpenVAS can be used to allow openvassd to reload NVTs
 Other:
  --help, -h, ?                    Help page"

}

#################################

release_name="$1"
openvas_source_table=`get_openvas_source_table`

if [ "$1" == "--help" ] || [ "$1" == "-h" ] || [ "$1" == "?" ]
then
    print_help
elif [ "$1" == "--install-dependencies" ]
then
    install_dependencies
elif [ "$1" == "--install-redis-source" ]
then
    install_redis_source
elif [ "$1" == "--show-releases" ]
then
    get_available_source_sets
elif [ "$1" == "--show-sources" ]
then
    release_name="$2"
    check=`check_releas_name "$release_name"`
    if [ "$check" == "ok" ]
    then
        get_source_set "$release_name"
    else
        echo "$check"
    fi
elif [ "$1" == "--download-sources" ]
then
    release_name="$2"
    check=`check_releas_name "$release_name"`
    if [ "$check" == "ok" ]
    then
        download_source_set "$release_name"
    else
        echo "$check"
    fi
elif  [ "$1" == "--create-folders" ]
then
    create_folders
elif [ "$1" == "--uninstall-all" ]
then
    dpkg -r "openvas-smb"
    dpkg -r "openvas-libraries"
    dpkg -r "openvas-scanner"
    dpkg -r "openvas-manager"
    dpkg -r "openvas-cli"
    dpkg -r "greenbone-security-assistant"
elif  [ "$1" == "--install-all" ]
then
    install_component "openvas-smb"
    install_component "openvas-libraries"
    install_component "openvas-scanner"
    install_component "openvas-manager"
    install_component "openvas-cli"
    install_component "greenbone-security-assistant"
elif [ "$1" == "--install-component" ]
then
    install_component "$2"
elif [ "$1" == "--uninstall-component" ]
then
    dpkg -r "$2"
elif [ "$1" == "--configure-all" ]
then
    mkdir /usr/local/var/lib/openvas/openvasmd/
    mkdir /usr/local/var/lib/openvas/openvasmd/gnupg
    mkcerts
    ldconfig
    openvasmd --create-user=admin --role=Admin && openvasmd --user=admin --new-password=1
elif [ "$1" == "--delete-admin" ]
then
    openvasmd --delete-user=admin
elif [ "$1" == "--update-content" ]
then
    if [ -f /usr/local/sbin/openvas-nvt-sync ]
    then
        /usr/local/sbin/openvas-nvt-sync
        /usr/local/sbin/openvas-scapdata-sync
        /usr/local/sbin/openvas-certdata-sync
    fi 
    if [ -f /usr/local/sbin/greenbone-certdata-sync ]
    then
        /usr/local/sbin/greenbone-nvt-sync
        /usr/local/sbin/greenbone-scapdata-sync
        /usr/local/sbin/greenbone-certdata-sync
    fi
elif [ "$1" == "--update-content-nvt" ]
then
    if [ -f /usr/local/sbin/openvas-nvt-sync ]
    then
        /usr/local/sbin/openvas-nvt-sync --curl
    fi 
    if [ -f /usr/local/sbin/greenbone-certdata-sync ]
    then
        /usr/local/sbin/greenbone-nvt-sync --curl
    fi
elif [ "$1" == "--rebuild-content" ]
then
    /usr/local/sbin/openvasmd --rebuild --progress
elif  [ "$1" == "--start-all" ]
then

    mkdir /usr/local/var/run 2>/dev/null; 
    mkdir /usr/local/var/run/openvasmd 2>/dev/null; 
    touch /usr/local/var/run/openvasmd/openvasmd.pid;

    /usr/local/sbin/openvasmd
    /usr/local/sbin/openvassd
    /usr/local/sbin/gsad
elif  [ "$1" == "--kill-all" ]
then
    ps aux | egrep "(openvas|gsad)" | awk '{print $2}' | xargs -i kill -9 '{}'
elif [ "$1" == "--check-status" ]
then
    if [ ! -f openvas-check-setup ]; 
    then
        wget https://svn.wald.intevation.org/svn/openvas/trunk/tools/openvas-check-setup --no-check-certificate
        chmod 0755 openvas-check-setup
    fi
    
    if [ "$2" == "" ]
    then
        version="v9"
    else
        version="$2"
    fi
    
    ./openvas-check-setup --$version --server
elif  [ "$1" == "--check-proc" ]
then
    ps aux | egrep "(openvas.d|gsad)"
elif [ "$1" == "--install-service" ]
then
    install_service
else
    echo "Unknown command"
    print_help
fi

#### TODO OSPD

#cd ospd-1*
#python setup.py install --prefix=/usr/local
#cd ../


#cd ospd-ancor-*
#python setup.py install --prefix=/usr/local
#cd ../

#cd ospd-debsecan-*
#python setup.py install --prefix=/usr/local
#cd ../

#cd ospd-ovaldi-*
#python setup.py install --prefix=/usr/local
#cd ../

#cd ospd-paloalto-*
#python setup.py install --prefix=/usr/local
#cd ../

#cd ospd-w3af-*
#python setup.py install --prefix=/usr/local
#cd ../

#!/bin/bash
# PARQ Masternode Setup Script V1 for Ubuntu 16.04 LTS
#
# Script will attempt to autodetect primary public IP address
# and generate masternode private key unless specified in command line
#
# Usage:
# bash parq.autoinstall.sh
#

#Color codes
RED='\033[0;91m'
BLUE='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#TCP port
PORT=12415
RPC=12416
apt-get -qq install build-essential && apt-get -qq install libtool libevent-pthreads-2.0-5 autotools-dev autoconf automake && apt-get -qq install libssl-dev && apt-get -qq install libboost-all-dev && apt-get -qq install software-properties-common && add-apt-repository -y ppa:bitcoin/bitcoin && apt update && apt-get -qq install libdb4.8-dev && apt-get -qq install libdb4.8++-dev && apt-get -qq install libminiupnpc-dev && apt-get -qq install libqt4-dev libprotobuf-dev protobuf-compiler && apt-get -qq install libqrencode-dev && apt-get -qq install git && apt-get -qq install pkg-config && apt-get -qq install libzmq3-dev
#Clear keyboard input buffer
function clear_stdin { while read -r -t 0; do read -r; done; }

#Delay script execution for N seconds
function delay { echo -e "${BLUE}Sleep for $1 seconds...${NC}"; sleep "$1"; }

#Stop daemon if it's already running
function stop_daemon {
    if pgrep -x 'parqd' > /dev/null; then
        echo -e "${YELLOW}Attempting to stop parqd${NC}"
        parq-cli stop
        sleep 30
        if pgrep -x 'parqd' > /dev/null; then
            echo -e "${RED}parqd daemon is still running!${NC} \a"
            echo -e "${RED}Attempting to kill...${NC}"
            sudo pkill -9 parqd
            sleep 30
            if pgrep -x 'parqd' > /dev/null; then
                echo -e "${RED}Can't stop parqd! Reboot and try again...${NC} \a"
                exit 2
            fi
        fi
    fi
}

#Process command line parameters
genkey=$1
clear

echo -e "${GREEN} ------- PARQ MASTERNODE INSTALLER v2.0.0--------+
 |                                                  |
 |                                                  |::
 |       The installation will install and run      |::
 |        the masternode under a user ESBC.         |::
 |                                                  |::
 |        This version of installer will setup      |::
 |           fail2ban and ufw for your safety.      |::
 |                                                  |::
 +------------------------------------------------+::
   ::::::::::::::::::::::::::::::::::::::::::::::::::S${NC}"
echo "Do you want me to generate a masternode private key for you?[y/n]"
read DOSETUP

if [[ $DOSETUP =~ "n" ]] ; then
          read -e -p "Enter your private key:" genkey;
              read -e -p "Confirm your private key: " genkey2;
    fi

#Confirming match
  if [ $genkey = $genkey2 ]; then
     echo -e "${GREEN}MATCH! ${NC} \a" 
else 
     echo -e "${RED} Error: Private keys do not match. Try again or let me generate one for you...${NC} \a";exit 1
fi
sleep .5
clear

# Determine primary public IP address
dpkg -s dnsutils 2>/dev/null >/dev/null || sudo apt-get -y install dnsutils
publicip=$(dig +short myip.opendns.com @resolver1.opendns.com)

if [ -n "$publicip" ]; then
    echo -e "${YELLOW}IP Address detected:" $publicip ${NC}
else
    echo -e "${RED}ERROR: Public IP Address was not detected!${NC} \a"
    clear_stdin
    read -e -p "Enter VPS Public IP Address: " publicip
    if [ -z "$publicip" ]; then
        echo -e "${RED}ERROR: Public IP Address must be provided. Try again...${NC} \a"
        exit 1
    fi
fi
if [ -d "/var/lib/fail2ban/" ]; 
then
    echo -e "${BLUE}Packages already installed...${NC}"
else
    echo -e "${BLUE}Updating system and installing required packages...${NC}"

sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove
sudo apt-get -y install wget nano htop jq
sudo apt-get -y install libzmq3-dev
sudo apt-get -y install libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev -y
sudo apt-get -y install libevent-dev -y
sudo apt-get install unzip
sudo apt install unzip
sudo apt -y install software-properties-common
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get -y update
sudo apt-get -y install libdb4.8-dev libdb4.8++-dev -y
sudo apt-get -y install libminiupnpc-dev
sudo apt-get -y install fail2ban
sudo service fail2ban restart
sudo apt-get install libdb5.3++-dev libdb++-dev libdb5.3-dev libdb-dev && ldconfig -y
sudo apt-get install -y unzip libzmq3-dev build-essential libssl-dev libboost-all-dev libqrencode-dev libminiupnpc-dev libboost-system1.58.0 libboost1.58-all-dev libdb4.8++ libdb4.8 libdb4.8-dev libdb4.8++-dev libevent-pthreads-2.0-5 -y
sudo apt-get install libdb5.3++-dev libdb++-dev libdb5.3-dev libdb-dev && ldconfig -y
   fi

#Network Settings
echo -e "${BLUE}Installing Network Settings...${NC}"
{
sudo apt-get install ufw -y
} &> /dev/null
echo -ne '[##                 ]  (10%)\r'
{
sudo apt-get update -y
} &> /dev/null
echo -ne '[######             ] (30%)\r'
{
sudo ufw default deny incoming
} &> /dev/null
echo -ne '[#########          ] (50%)\r'
{
sudo ufw default allow outgoing
sudo ufw allow ssh
} &> /dev/null
echo -ne '[###########        ] (60%)\r'
{
sudo ufw allow $PORT/tcp
sudo ufw allow $RPC/tcp
} &> /dev/null
echo -ne '[###############    ] (80%)\r'
{
sudo ufw allow 22/tcp
sudo ufw limit 22/tcp
} &> /dev/null
echo -ne '[#################  ] (90%)\r'
{
echo -e "${YELLOW}"
sudo ufw --force enable
echo -e "${NC}"
} &> /dev/null
echo -ne '[###################] (100%)\n'

#Generating Random Password for  JSON RPC
rpcuser=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
rpcpassword=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

#Create 2GB swap file
if grep -q "SwapTotal" /proc/meminfo; then
    echo -e "${BLUE}Skipping disk swap configuration...${NC} \n"
else
    echo -e "${YELLOW}Creating 2GB disk swap file. \nThis may take a few minutes!${NC} \a"
    touch /var/swap.img
    chmod 600 swap.img
    dd if=/dev/zero of=/var/swap.img bs=1024k count=2000
    mkswap /var/swap.img 2> /dev/null
    swapon /var/swap.img 2> /dev/null
    if [ $? -eq 0 ]; then
        echo '/var/swap.img none swap sw 0 0' >> /etc/fstab
        echo -e "${BLUE}Swap was created successfully!${NC} \n"
    else
        echo -e "${RED}Operation not permitted! Optional swap was not created.${NC} \a"
        rm /var/swap.img
    fi
fi
 
#Installing Daemon
cd ~
rm -rf /usr/local/bin/parq*
rm -rf daemon*
wget https://github.com/PARQ/ParqCore/releases/download/1.0.0/daemon.zip
unzip daemon.zip
cd daemon/
sudo chmod -R 755 parq-cli
sudo chmod -R 755 parqd
cp -p -r parqd /usr/local/bin
cp -p -r parq-cli /usr/local/bin
cd
rm daemon*

  parq-cli stop
 
 

 
 #Create datadir
 if [ ! -f ~/.parq/parq.conf ]; then 
 	sudo mkdir ~/.parq
 fi
clear
echo -e "${YELLOW}Creating parq.conf...${NC}"

# If genkey was not supplied in command line, we will generate private key on the fly
if [ -z $genkey ]; then
    cat <<EOF > ~/.parq/parq.conf
rpcuser=$rpcuser
rpcpassword=$rpcpassword
EOF

    sudo chmod 755 -R ~/.parq/parq.conf

    #Starting daemon first time just to generate masternode private key
    parqd -daemon
echo -ne '[##                 ] (15%)\r'
sleep 6
echo -ne '[######             ] (30%)\r'
sleep 6
echo -ne '[########           ] (45%)\r'
sleep 6
echo -ne '[##############     ] (72%)\r'
sleep 6
echo -ne '[###################] (100%)\r'
echo -ne '\n'

    #Generate masternode private key
    echo -e "${YELLOW}Generating masternode private key...${NC}"
    genkey=$(parq-cli masternode genkey)
    if [ -z "$genkey" ]; then
        echo -e "${RED}ERROR: Can not generate masternode private key.${NC} \a"
        echo -e "${RED}ERROR: Reboot VPS and try again or supply existing genkey as a parameter.${NC}"
        exit 1
    fi
    
    #Stopping daemon to create parq.conf
    parq-cli stop
    sleep .5
fi
# Create parq.conf
cat <<EOF > ~/.parq/parq.conf
rpcuser=$rpcuser
rpcpassword=$rpcpassword
rpcallowip=127.0.0.1
rpcport=$RPC
port=$PORT
listen=1
server=1
daemon=1
logtimestamps=1
maxconnections=256
masternode=1
externalip=$publicip
bind=$publicip
masternodeaddr=$publicip
masternodeprivkey=$genkey
 
EOF

#Finally, starting daemon with new parq.conf
parqd -daemon
sleep 5

#Setting auto start cron job for parq
cronjob="@reboot sleep 30 && parq"
crontab -l > tempcron
if ! grep -q "$cronjob" tempcron; then
    echo -e "${BLUE}Configuring crontab job...${NC}"
    echo $cronjob >> tempcron
    crontab tempcron
fi
rm tempcron

echo -e "========================================================================
${BLUE}Masternode setup is complete!${NC}
========================================================================
Masternode was installed with VPS IP Address: ${BLUE}$publicip${NC}
Masternode Private Key: ${BLUE}$genkey${NC}
Now you can add the following string to the masternode.conf file 
======================================================================== \a"
echo -e "${BLUE}parq_mn1 $publicip:$PORT $genkey TxId TxIdx${NC}"
echo -e "========================================================================
Use your mouse to copy the whole string above into the clipboard by
tripple-click + single-click (Dont use Ctrl-C) and then paste it 
into your ${BLUE}masternode.conf${NC} file and replace:
    ${BLUE}parq_mn1${NC} - with your desired masternode name (alias)
    ${BLUE}TxId${NC} - with Transaction Id from masternode outputs
    ${BLUE}TxIdx${NC} - with Transaction Index (0 or 1)
     Remember to save the masternode.conf and restart the wallet!
To introduce your new masternode to the parq network, you need to
issue a masternode start command from your wallet, which proves that
the collateral for this node is secured."

clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "Wait for the node wallet on this VPS to sync with the other nodes
on the network. Eventually the 'Is Synced' status will change
to 'true', which will indicate a comlete sync, although it may take
from several minutes to several hours depending on the network state.
Your initial Masternode Status may read:
    ${BLUE}Node just started, not yet activated${NC} or
    ${BLUE}Node  is not in masternode list${NC}, which is normal and expected.
"
clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "
${BLUE}...scroll up to see previous screens...${NC}
Here are some useful commands and tools for masternode troubleshooting:
========================================================================
To view masternode configuration produced by this script in parq.conf:
${BLUE}cat ~/.parq/parq.conf${NC}
Here is your parq.conf generated by this script:
-------------------------------------------------${BLUE}"
echo -e "${BLUE}parq_mn1 $publicip:$PORT $genkey TxId TxIdx${NC}"
cat ~/.parq/parq.conf
echo -e "${NC}-------------------------------------------------
NOTE: To edit parq.conf, first stop the parqd daemon,
then edit the parq.conf file and save it in nano: (Ctrl-X + Y + Enter),
then start the parqd daemon back up:
to stop:              ${BLUE}parq-cli stop${NC}
to start:             ${BLUE}parqd${NC}
to edit:              ${BLUE}nano ~/.parq/parq.conf${NC}
to check mn status:   ${BLUE}parq-cli masternode status${NC}
========================================================================
To monitor system resource utilization and running processes:
                   ${BLUE}htop${NC}
========================================================================
"
sleep 10

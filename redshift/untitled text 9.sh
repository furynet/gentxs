#Setting up constants
FURY_HOME=$HOME/.fury
FURY_SRC=$FURY_HOME/src/fury
COSMOVISOR_SRC=$FURY_HOME/src/cosmovisor

FURY_VERSION="v1.0.1"
COSMOVISOR_VERSION="cosmovisor-v1.0.1"

mkdir -p $FURY_HOME
mkdir -p $FURY_HOME/src
mkdir -p $FURY_HOME/bin
mkdir -p $FURY_HOME/logs
mkdir -p $FURY_HOME/cosmovisor/genesis/bin
mkdir -p $FURY_HOME/cosmovisor/upgrades/

echo "--------------installing dependendies---------------------------"
sudo apt update
sudo apt upgrade
sudo apt-get update
sudo apt-get upgrade
sudo apt install git build-essential ufw curl jq snapd wget --yes

echo "--------------installing golang---------------------------"
gcc_source="/opt/rh/gcc-toolset-9/enable"
if test -f $gcc_source; then
   source gcc_source
fi

set -eu

echo "--------------installing golang---------------------------"
curl https://dl.google.com/go/go1.16.4.linux-amd64.tar.gz --output $HOME/go.tar.gz
tar -C $HOME -xzf $HOME/go.tar.gz
rm $HOME/go.tar.gz
export PATH=$PATH:$HOME/go/bin
export GOPATH=$HOME/go
echo "export GOPATH=$HOME/go" >> ~/.bashrc
go version

echo "----------------------installing fury---------------"
git clone -b fanfury https://github.com/fanfury-sports/fanfuryfury.git 
cd fanfury 
make build && make install
mv fury $FURY_HOME/cosmovisor/genesis/bin/fury

echo "-------------------installing cosmovisor-----------------------"
git clone -b $COSMOVISOR_VERSION https://github.com/onomyprotocol/onomy-sdk $COSMOVISOR_SRC
cd $COSMOVISOR_SRC
make cosmovisor
cp cosmovisor/cosmovisor $FURY_HOME/bin/cosmovisor

echo "-------------------adding binaries to path-----------------------"
chmod +x $FURY_HOME/bin/*
export PATH=$PATH:$FURY_HOME/bin
chmod +x $FURY_HOME/cosmovisor/genesis/bin/*
export PATH=$PATH:$FURY_HOME/cosmovisor/genesis/bin

echo "export PATH=$PATH" >> ~/.bashrc

# set the cosmovisor environments
echo "export DAEMON_HOME=$FURY_HOME/" >> ~/.bashrc
echo "export DAEMON_NAME=fury" >> ~/.bashrc
echo "export DAEMON_RESTART_AFTER_UPGRADE=true" >> ~/.bashrc

echo "Fury binaries are installed successfully."

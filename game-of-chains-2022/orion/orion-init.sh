#!/bin/bash
# Set up a orion service to join the mib-orion chain.

# Configuration
# You should only have to modify the values in this block
PRIV_VALIDATOR_KEY_FILE=~/priv_validator_key.json
NODE_KEY_FILE=~/node_key.json
NODE_HOME=~/.orion
NODE_MONIKER=orion
# ***

CHAIN_BINARY_URL='https://github.com/made-in-block/mib-consumer-chain/releases/download/v0.1.0/oriond'
CHAIN_BINARY='oriond'
CHAIN_ID=mib-orion
PERSISTENT_PEERS="3a78c8fb17f34a3bd21cfc0d580209fbe3e50606@95.217.235.1:23456"

# Install go 1.19.2
echo "Installing go..."
rm go1.19.2.linux-amd64.tar.gz
wget https://go.dev/dl/go1.19.2.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.19.2.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Install chain binary
echo "Installing orion..."
mkdir -p $HOME/go/bin

# Download Linux amd64,
wget $CHAIN_BINARY_URL -O $HOME/go/bin/$CHAIN_BINARY
chmod +x $HOME/go/bin/$CHAIN_BINARY

# or install from source
# echo "Installing build-essential..."
# sudo apt install build-essential -y
# rm -rf orion
# git clone https://github.com/made-in-block/mib-consumer-chain.git
# cd orion
# git checkout tags/v0.1.0
# make install

export PATH=$PATH:$HOME/go/bin

# Initialize home directory
echo "Initializing $NODE_HOME..."
rm -rf $NODE_HOME
$CHAIN_BINARY init $NODE_MONIKER --chain-id $CHAIN_ID --home $NODE_HOME

# Replace keys
echo "Replacing keys and genesis file..."
cp $PRIV_VALIDATOR_KEY_FILE $NODE_HOME/config/priv_validator_key.json
cp $NODE_KEY_FILE $NODE_HOME/config/node_key.json

# Reset state
$CHAIN_BINARY tendermint unsafe-reset-all --home $NODE_HOME

sudo rm /etc/systemd/system/$NODE_MONIKER.service
sudo touch /etc/systemd/system/$NODE_MONIKER.service

echo "[Unit]"                               | sudo tee /etc/systemd/system/$NODE_MONIKER.service
echo "Description=Orion service"       | sudo tee /etc/systemd/system/$NODE_MONIKER.service -a
echo "After=network-online.target"          | sudo tee /etc/systemd/system/$NODE_MONIKER.service -a
echo ""                                     | sudo tee /etc/systemd/system/$NODE_MONIKER.service -a
echo "[Service]"                            | sudo tee /etc/systemd/system/$NODE_MONIKER.service -a
echo "User=$USER"                            | sudo tee /etc/systemd/system/$NODE_MONIKER.service -a
echo "ExecStart=$HOME/go/bin/$CHAIN_BINARY start --x-crisis-skip-assert-invariants --home $NODE_HOME --p2p.persistent_peers $PERSISTENT_PEERS" | sudo tee /etc/systemd/system/$NODE_MONIKER.service -a
echo "Restart=always"                       | sudo tee /etc/systemd/system/$NODE_MONIKER.service -a
echo "RestartSec=3"                         | sudo tee /etc/systemd/system/$NODE_MONIKER.service -a
echo "LimitNOFILE=4096"                     | sudo tee /etc/systemd/system/$NODE_MONIKER.service -a
echo ""                                     | sudo tee /etc/systemd/system/$NODE_MONIKER.service -a
echo "[Install]"                            | sudo tee /etc/systemd/system/$NODE_MONIKER.service -a
echo "WantedBy=multi-user.target"           | sudo tee /etc/systemd/system/$NODE_MONIKER.service -a

# Start service
echo "Starting $NODE_MONIKER.service..."
sudo systemctl daemon-reload

# Add go and gaiad to the path
echo "Setting up paths for go..."
echo "export PATH=$PATH:/usr/local/go/bin" >> .profile

echo "***********************"
echo "After you have updated the genesis file, start the orion service:"
echo "sudo systemctl enable $NODE_MONIKER.service"
echo "sudo systemctl start $NODE_MONIKER.service"
echo "And follow the log with:"
echo "journalctl -fu $NODE_MONIKER.service"
echo "***********************"

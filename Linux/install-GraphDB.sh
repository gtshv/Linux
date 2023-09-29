#!/bin/bash

# Step 1: Create the /opt/graphdb directory if it doesn't exist
sudo mkdir -p /opt/graphdb

# Step 2: Download GraphDB 10.3.3 zip directly to /opt/graphdb
curl -C - -o /opt/graphdb/graphdb-10.3.3-dist.zip https://maven.ontotext.com/repository/owlim-releases/com/ontotext/graphdb/graphdb/10.3.3/graphdb-10.3.3-dist.zip

# Step 3: Change the working directory to /opt/graphdb
cd /opt/graphdb

# Step 4: Unzip GraphDB in the current directory
sudo apt-get update
sudo apt-get install -y unzip
unzip -o graphdb-10.3.3-dist.zip

# Step 5: Install Java (OpenJDK 11)

sudo apt-get install openjdk-11-jdk

# Step 6: Confirm Java installation
java -version

# Step 7: Generate a keystore for GraphDB in the current directory
sudo keytool -genkey -keyalg RSA -alias graphdb -keystore /etc/ssl/certs/keystore.jks -storepass 12345678 -validity 365 -keysize 2048 -dname "CN=Kris, OU=DevOps, O=Ontotext
, L=Varna, ST=NA, C=BG"

# Step 8: Create graphdb.properties file in the /etc/graphdb directory
sudo mkdir -p /etc/graphdb
cat <<EOF | sudo tee /etc/graphdb/graphdb.properties
graphdb.connector.port = 7205
graphdb.connector.SSLEnabled = true
graphdb.connector.scheme = https
graphdb.connector.secure = true
graphdb.connector.keystoreFile = /etc/ssl/certs/keystore.jks
graphdb.connector.keystorePass = 12345678
graphdb.connector.keyAlias = graphdb
graphdb.connector.keyPass = 12345678
EOF

# Step 9: Clean up the downloaded zip file (optional)
#rm graphdb-10.3.3-dist.zip

# Step 10: Start GraphDB with specific properties file
#cd /opt/graphdb/graphdb-10.3.3/bin/
#sudo ./graphdb -Dgraphdb.home.conf=/etc/graphdb/

# Function to install the systemd service
install_graphdb_service() {

# Create a dedicated user for the GraphDB service (replace 'graphdbuser' with your desired username)
sudo useradd -r -s /bin/false graphdbuser
#sudo usermod -aG sudo graphdbuser
sudo chown -R graphdbuser /opt/graphdb/

# Create the systemd service unit file
cat <<EOF | sudo tee /etc/systemd/system/graphdb.service
[Unit]
Description=GraphDB Service
After=network.target

[Service]
Type=simple
User=graphdbuser
ExecStart= /opt/graphdb/graphdb-10.3.3/bin/graphdb -Dgraphdb.home.conf=/etc/graphdb/

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Start and enable the GraphDB service
sudo systemctl start graphdb
sudo systemctl enable graphdb

# Check the status of the service
#sudo systemctl status graphdb
}

#Prompt the user if they want to start GraphDB as a systemd service

read -p "Do you want to start GraphDB as a systemd service? (y/n): " start_service

if [ "$start_service" = "y" ]; then
    install_graphdb_service
    echo "GraphDB has been set up as a systemd service."
else
    cd /opt/graphdb/graphdb-10.3.3/bin/ && sudo ./graphdb -Dgraphdb.home.conf=/etc/graphdb/ -d
    echo "GraphDB was startet normally on Port 7205 (for testing purposes)."
fi
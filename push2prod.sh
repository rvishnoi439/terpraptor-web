#!/bin/bash

# Variables
ARCHIVE_NAME="prod_$(date +%Y%m%d_%H%M%S).tar.gz"  # Archive name with timestamp
REMOTE_USER="need to fill this in"   # Replace with the remote username
REMOTE_HOST="need to fill this in"   # Replace with the remote host/IP
REMOTE_DIR="need to fill this in"  # Replace with the remote directory path

#########################################################################################
## Remote in and remove existing website & what not
#########################################################################################

echo "cleaning up remote and making way for new prod"
ssh $REMOTE_USER@$REMOTE_HOST "
    cd ~/website/frontend;
    ls -la;
    docker compose down;
    cd ~;
    rm -rf ~/website;
    ls -l;
    mkdir ~/website
"

#########################################################################################
## Push the website contents and everything to the server
#########################################################################################

# Create tar.gz archive of the current directory
echo "Creating archive: $ARCHIVE_NAME"
tar -czf "$ARCHIVE_NAME" ./frontend

# Check if the archive was created successfully
if [ $? -ne 0 ]; then
    echo "Error: Failed to create archive."
    exit 1
fi

# Securely copy the archive to the remote location
echo "Transferring $ARCHIVE_NAME to $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR"
scp "$ARCHIVE_NAME" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR"

# Check if the transfer was successful
if [ $? -eq 0 ]; then
    echo "Transfer complete."
    # Optionally, delete the archive after successful transfer
    rm "$ARCHIVE_NAME"
    echo "Local archive removed."
else
    echo "Error: Transfer failed."
    exit 1
fi

#########################################################################################
## Remote in and run specific commands to automate bringup
#########################################################################################
REMOTE_COMMANDS="
cd ~/website;
ls -la;
tar -xvf ${ARCHIVE_NAME}
cd ~/website/frontend
docker compose up -d
"
ssh $REMOTE_USER@$REMOTE_HOST "${REMOTE_COMMANDS}"
echo "New prod running, website should be up. SSH in if there are issues"

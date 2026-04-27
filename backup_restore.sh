#!/bin/bash

# Ensure the script is run with superuser privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Check if a mode and destination folder are provided
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 /backup|/restore <folder>"
  exit 1
fi

# Parse command-line arguments
MODE=$1
BACKUP_DIR=$2

# Create the backup directory if it doesn't exist (only for backup mode)
if [ "$MODE" == "/backup" ] && [ ! -d "$BACKUP_DIR" ]; then
  echo "Creating backup directory: $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
fi

# Define the list of configuration files and directories to back up
CONFIG_FILES=(
  "/etc/fstab"
  "/etc/hostname"
  "/etc/hosts"
  "/etc/apt/"
  "/etc/network/"
  "/etc/default/"
  "/etc/grub.d/"
  "/etc/systemd/"
  "/etc/xdg/"
  "/etc/udev/hwdb.d/"
  "/etc/mysql/"            # MySQL configuration directory
  "/usr/local/bin/"
  "/home/$SUDO_USER/.config/"
  "/home/$SUDO_USER/.bashrc"
  "/home/$SUDO_USER/.profile"
  "/home/$SUDO_USER/.bash_aliases"
  "/home/$SUDO_USER/.vimrc"
  "/home/$SUDO_USER/Documents"
)

# Database configuration
MYTH_DB_BACKUP="$BACKUP_DIR/mythtv_database_backup.sql"
DB_USER="mythtv"         # Update if you have a different user
DB_NAME="mythconverg"    # Default database name for MythTV

# Backup Function
backup() {
#  # Prompt for the MySQL root password
#  read -sp "Enter MySQL root password: " MYSQL_ROOT_PASS
#  echo
#
#  # Grant PROCESS privilege to the mythtv user
#  echo "Granting PROCESS privilege to user '$DB_USER' on host '$DB_HOST'..."
#  mysql -u root -p"$MYSQL_ROOT_PASS" -e "GRANT PROCESS ON *.* TO '$DB_USER'@'$DB_HOST'; FLUSH PRIVILEGES;"
#
#  # Check if the command was successful
#  if [ $? -eq 0 ]; then
#    echo "Successfully granted PROCESS privilege to '$DB_USER'!"
#  else
#    echo "Error: Failed to grant PROCESS privilege."
#    exit 1
#  fi

  echo "Backing up configuration files to $BACKUP_DIR..."
  for ITEM in "${CONFIG_FILES[@]}"; do
    if [ -e "$ITEM" ]; then
      echo "Backing up $ITEM"
      rsync -aR "$ITEM" "$BACKUP_DIR"
    else
      echo "Skipping $ITEM (not found)"
    fi
  done

  # Backup MythTV database
  echo "Backing up MythTV database to $MYTH_DB_BACKUP..."
  mysqldump -u "$DB_USER" -p "$DB_NAME" > "$MYTH_DB_BACKUP"
  
  if [ $? -eq 0 ]; then
    echo "MythTV database backup completed successfully!"
  else
    echo "Error: Failed to backup MythTV database."
  fi

  echo "Backup process completed!"
}

# Restore Function
restore() {
  echo "Restoring configuration files from $BACKUP_DIR..."
  for ITEM in "${CONFIG_FILES[@]}"; do
    REL_PATH=$(echo "$ITEM" | sed 's/^\///')  # Remove leading slash for relative path
    if [ -e "$BACKUP_DIR/$REL_PATH" ]; then
      echo "Restoring $ITEM"
      rsync -a "$BACKUP_DIR/$REL_PATH" "/"
    else
      echo "Skipping $ITEM (not found in backup)"
    fi
  done

  # Restore MythTV database
  if [ -f "$MYTH_DB_BACKUP" ]; then
    echo "Restoring MythTV database from $MYTH_DB_BACKUP..."
    mysql -u "$DB_USER" -p "$DB_NAME" < "$MYTH_DB_BACKUP"

    if [ $? -eq 0 ]; then
      echo "MythTV database restored successfully!"
    else
      echo "Error: Failed to restore MythTV database."
    fi
  else
    echo "MythTV database backup not found. Skipping restore."
  fi

  echo "Restore process completed!"
}

# Run the appropriate function based on the mode
case "$MODE" in
  "/backup")
    backup
    ;;
  "/restore")
    restore
    ;;
  *)
    echo "Invalid mode. Use /backup or /restore."
    exit 1
    ;;
esac

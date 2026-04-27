#!/bin/bash

# Function to clean up the '00-date' directory and its symbolic links
tidy() {
    if [ -d "00-date" ]; then
        echo "Removing symbolic links and the 'date' directory..."
        rm -rf 00-date
        echo "'00-date' directory and symlinks removed."
    else
        echo "'00-date' directory does not exist. Nothing to tidy."
    fi
}

# Tidy up the exisiting folder
tidy

# Check for the /tidy switch and exit if present
if [[ "$1" == "/tidy" ]]; then
    exit 0
fi

# Create the '00-date' directory if it doesn't exist
mkdir -p 00-date

# Loop through all files and directories in the current directory
for item in *; do
    # Skip the '00-date' directory itself
    if [[ "$item" == "00-date" ]]; then
        continue
    fi

    # Get the creation date in YYYY-MM-DD format
    # Use 'stat -c %w' to get the creation date (birth date) on supported systems
    creation_date=$(stat -c %w "$item" | cut -d' ' -f1)

    # If the creation date is unknown ('-' output), fall back to using the modification date
    if [[ "$creation_date" == "-" ]]; then
        creation_date=$(stat -c %y "$item" | cut -d' ' -f1)
    fi

    # Create a symbolic link in the '00-date' directory, prefixing with the access date
    ln -s "$(realpath "$item")" "00-date/${creation_date}_${item}"
done

echo "Symbolic links created in the '00-date' directory."

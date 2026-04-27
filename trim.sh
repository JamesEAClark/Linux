#!/bin/bash

# Set the maximum age of recordings to keep (in seconds)
max_age=$((30 * 24 * 60 * 60))

# Connect to the MythTV MySQL database
mysql -h localhost -u mythtv -pmythtv mythconverg << EOF

# Query the database for recordings and their associated files
SELECT recorded.id, recorded.starttime, recorded.basename, recorded.dirname, recorded.filesize
FROM recorded
WHERE recorded.deletepending = 0 AND recorded.filesize > 0
INTO OUTFILE '/home/temp/recordings.txt';

EOF

# Loop through each recording in the text file
while read id starttime basename dirname filesize; do
    # Get the age of the recording in seconds
    age=$(( $(date +%s) - $(date +%s -d "$starttime") ))

    # Check if the recording is older than the maximum age
    if [[ $age -gt $max_age ]]; then
        # Delete the recording and its associated file
        echo "Deleting recording $basename"
        #rm "$dirname/$basename"
        #mysql -h localhost -u mythtv -pmythtv mythconverg -e "DELETE FROM recorded WHERE id=$id;"
    fi
done < /home/temp/recordings.txt

# Delete the temporary text file
rm /home/temp/recordings.txt

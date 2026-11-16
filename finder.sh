#!/bin/bash

# --- Configuration ---
IP_PREFIX="172.26.22"
START_IP=2
END_IP=255
PORT="8080"
DOWNLOAD_DIR="downloaded_pages"
MOLE_SERVERS_LIST="mole_servers.txt"

# --- End Configuration ---

echo "--- Starting 'Mole' Server Scan ---"

# 1. Prepare environment
echo "[1/3] Creating clean directory: $DOWNLOAD_DIR"
rm -rf "$DOWNLOAD_DIR"
mkdir -p "$DOWNLOAD_DIR"
# Clear the results file from any previous run
> "$MOLE_SERVERS_LIST"

# 2. Scan and Download
echo "[2/3] Scanning $IP_PREFIX.$START_IP to $IP_PREFIX.$END_IP on port $PORT..."

for i in $(seq $START_IP $END_IP); do
    IP="$IP_PREFIX.$i"
    URL="http://$IP:$PORT"
    FILENAME="$DOWNLOAD_DIR/page_${IP}.html"
    
    # Use curl with a 1-second connect timeout
    # -s = silent
    # -L = follow redirects
    # -o = output file
    # We use 'printf' to show progress without spamming newlines
    printf "Checking $IP... "
    curl -L -s --connect-timeout 1 "$URL" -o "$FILENAME"
    
    # Check if the download was successful (file is not empty)
    if [ -s "$FILENAME" ]; then
        echo "OK"
    else
        # If the file is empty (connection failed), remove it
        echo "Failed"
        rm "$FILENAME"
    fi
done

echo "" # Newline after the progress dots
echo "Scan and download phase complete."

# 3. Search for 'mole'
echo "[3/3] Searching downloaded files for the word 'mole'..."

# Use grep -l (lowercase L) to list filenames that contain the word "mole"
# Search all .html files in the download directory
grep -l "mole" "$DOWNLOAD_DIR"/*.html > "$MOLE_SERVERS_LIST"

# --- FINAL RESULTS ---
echo "----------------------------------------------------------------"
echo "--- SCAN COMPLETE ---"
echo "----------------------------------------------------------------"
echo ""

if [ -s "$MOLE_SERVERS_LIST" ]; then
    echo "Congratulations! Found 'mole' on the following servers:"
    echo ""
    # Cat the file, but also use sed to make the output cleaner (just the IP)
    cat "$MOLE_SERVERS_LIST" | sed "s|$DOWNLOAD_DIR/page_||" | sed "s|.html||"
    echo ""
    echo "A full list of matching filenames is in: $MOLE_SERVERS_LIST"
else
    echo "No 'mole' servers were found on the network."
fi

echo "All downloaded HTML pages are saved in the '$DOWNLOAD_DIR' directory."
echo ""
echo "Script finished."

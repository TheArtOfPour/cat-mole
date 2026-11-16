#!/bin/bash

# --- Configuration ---
NGINX_PORT="8080"
NGINX_CONFIG_FILE="/etc/nginx/sites-available/default"
HTML_FILE_PATH="/var/www/html/index.html"

# --- End Configuration ---

# Must be run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or with sudo."
  exit 1
fi

echo "--- Starting Nginx Port 8080 Server Setup ---"

# 1. Install Nginx
echo "[1/6] Installing Nginx..."
apt-get update
apt-get install -y nginx

# 2. Configure Nginx to listen on the new port
echo "[2/6] Configuring Nginx to listen on port $NGINX_PORT..."
# Use sed to replace 'listen 80' and 'listen [::]:80'
sed -i "s/listen 80 default_server;/listen $NGINX_PORT default_server;/" "$NGINX_CONFIG_FILE"
sed -i "s/listen \[::\]:80 default_server;/listen \[::\]:$NGINX_PORT default_server;/" "$NGINX_CONFIG_FILE"

# 3. Configure Firewall (UFW)
echo "[3/6] Configuring firewall to allow port $NGINX_PORT..."
ufw allow "$NGINX_PORT/tcp"
ufw reload

# 4. Generate random number and choose the word
echo "[4/6] Generating random word..."
RANDOM_NUM=$(( (RANDOM % 8) + 1 )) # Random number 1-8

if [ "$RANDOM_NUM" -eq 2 ]; then
  WORD="mole"
else
  WORD="cat"
fi

echo "Random number was $RANDOM_NUM. The chosen word is: $WORD"

# 5. Create the "artistic" HTML page
echo "[5/6] Creating new default HTML page at $HTML_FILE_PATH..."

# Write the HTML head and CSS styles
cat << EOF > "$HTML_FILE_PATH"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>The Word Page</title>
    <style>
        body {
            background-color: #111;
            font-family: 'Courier New', Courier, monospace;
            text-align: center;
            padding: 20px;
            overflow: hidden; /* Hide scrollbars from the mass of text */
        }
        h1 {
            color: #eee;
            font-size: 3rem;
            text-transform: uppercase;
            letter-spacing: 5px;
        }
        .word-container {
            line-height: 1.4;
            font-size: 1.5rem;
            font-weight: bold;
            word-wrap: break-word; /* Ensure words wrap */
        }
        /* Define the color classes */
        .c1 { color: #ff6b6b; }
        .c2 { color: #f06595; }
        .c3 { color: #cc5de8; }
        .c4 { color: #845ef7; }
        .c5 { color: #5c7cfa; }
        .c6 { color: #339af0; }
        .c7 { color: #22b8cf; }
        .c8 { color: #20c997; }
        .c9 { color: #51cf66; }
        .c10 { color: #fcc419; }
        .c11 { color: #ff922b; }
    </style>
</head>
<body>
    <h1>The Word is: $WORD</h1>
    <div class="word-container">
EOF

# Append 300 instances of the word, each with a random color class
# We pipe this loop's output to 'tee -a' to append to the file
for i in {1..300}
do
    # Generate a random number from 1 to 11 for the 11 color classes
    COLOR_NUM=$(( (RANDOM % 11) + 1 ))
    
    # Add the word in a span with the random color class.
    # Add a space after the word for separation.
    echo "<span class=\"c$COLOR_NUM\">$WORD </span>"
done >> "$HTML_FILE_PATH"

# Close the HTML tags
cat << EOF >> "$HTML_FILE_PATH"
    </div>
</body>
</html>
EOF

# 6. Restart Nginx to apply all changes
echo "[6/6] Restarting Nginx service..."
systemctl restart nginx

# --- FINAL INSTRUCTIONS ---
echo "----------------------------------------------------------------"
echo "--- SETUP COMPLETE ---"
echo "----------------------------------------------------------------"
echo ""
echo "Nginx is now running and serving your custom page."
echo "Visit this URL in your browser:"
echo ""
echo "    http://$(hostname -I | cut -d' ' -f1):$NGINX_PORT"
echo ""
echo "Setup finished."

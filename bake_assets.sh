#!/bin/sh
set -e

# Directory containing the public assets
PUBLIC_DIR="./Public"

# Get timestamp of the newest CSS/JS asset for cache busting
# (so a change to any busted asset invalidates all busted references)
TIMESTAMP=0
for F in "$PUBLIC_DIR/css/retro.css" "$PUBLIC_DIR/js/components.js"; do
    if [ -f "$F" ]; then
        T=$(date -r "$F" +%s)
        if [ "$T" -gt "$TIMESTAMP" ]; then TIMESTAMP=$T; fi
    fi
done
if [ "$TIMESTAMP" -eq 0 ]; then
    echo "Warning: none of css/retro.css, js/components.js found; skipping cache busting."
    TIMESTAMP=$(date +%s)
else
    echo "Asset Timestamp: $TIMESTAMP"
fi

# Function to process a file
process_file() {
    file="$1"
    
    # Skip directories
    if [ -d "$file" ]; then return; fi
    
    # Skip .DS_Store
    if [ "$(basename "$file")" = ".DS_Store" ]; then return; fi

    echo "Processing $file..."

    # Inject cache busting
    # strict replacement of /css/retro.css with /css/retro.css?v=TIMESTAMP
    sed -i "s|/css/retro.css|/css/retro.css?v=$TIMESTAMP|g" "$file"
    # strict replacement of /js/components.js with /js/components.js?v=TIMESTAMP
    sed -i "s|/js/components.js|/js/components.js?v=$TIMESTAMP|g" "$file"

    # Rename extensionless files to .html if they are likely HTML
    # We assume file is HTML if it doesn't have an extension
    filename=$(basename "$file")
    if echo "$filename" | grep -qv '\.'; then
        mv "$file" "$file.html"
        echo "Renamed $file to $file.html"
    fi
}

export TIMESTAMP
export PUBLIC_DIR

# Find and process files
# We process top level files and files in subdirectories that are likely content
find "$PUBLIC_DIR" -type f -not -path "*/css/*" -not -path "*/js/*" -not -path "*/images/*" | while read -r file; do
    process_file "$file"
done

echo "Asset baking complete."

#!/bin/sh
set -e

# Directory containing the public assets
PUBLIC_DIR="./Public"

# Get timestamp of main.css for cache busting
CSS_FILE="$PUBLIC_DIR/css/main.css"
if [ -f "$CSS_FILE" ]; then
    TIMESTAMP=$(date -r "$CSS_FILE" +%s)
    echo "CSS Timestamp: $TIMESTAMP"
else
    echo "Warning: css/main.css not found, skipping cache busting."
    TIMESTAMP=$(date +%s)
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
    # strict replacement of /css/main.css with /css/main.css?v=TIMESTAMP
    sed -i "s|/css/main.css|/css/main.css?v=$TIMESTAMP|g" "$file"

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

unzip_to_dir() {
    # Check if an argument was provided
    if [ $# -eq 0 ]; then
        echo "Usage: unzip_to_dir <zipfile>"
        return 1
    fi

    local ZIPFILE="$1"

    # Check if the file exists
    if [ ! -f "$ZIPFILE" ]; then
        echo "Error: File '$ZIPFILE' not found"
        return 1
    fi

    # Check if it's a zip file
    if [[ ! "$ZIPFILE" =~ \.zip$ ]]; then
        echo "Error: File must have a .zip extension"
        return 1
    fi

    # Get the filename without the .zip extension
    local DIRNAME="${ZIPFILE%.zip}"

    # Create the directory if it doesn't exist
    mkdir -p "$DIRNAME"

    # Unzip into the directory
    unzip "$ZIPFILE" -d "$DIRNAME"

    echo "Successfully extracted '$ZIPFILE' to '$DIRNAME/'"
}


unzip_all() {
    local count=0
    local success=0
    local failed=0

    # Check if there are any zip files
    if ! ls *.zip >/dev/null 2>&1; then
        echo "No zip files found in current directory"
        return 1
    fi

    echo "Found zip files. Starting extraction..."
    echo "----------------------------------------"

    # Loop through all zip files in current directory
    for zipfile in *.zip; do
        ((count++))
        echo ""
        echo "[$count] Processing: $zipfile"

        if unzip_to_dir "$zipfile"; then
            ((success++))
        else
            ((failed++))
        fi
    done

    echo ""
    echo "----------------------------------------"
    echo "Summary: $count total, $success successful, $failed failed"
}
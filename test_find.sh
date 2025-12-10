#!/bin/bash

INPUT_DIR="$1"

echo "Testing find commands..."
echo ""

echo "Method 1: Simple find with -print"
find "$INPUT_DIR" -type f -name "*.zip" | head -5
echo ""

echo "Method 2: Find with -print0 and tr"
find "$INPUT_DIR" -type f -name "*.zip" -print0 | tr '\0' '\n' | head -5
echo ""

echo "Method 3: Process substitution"
count=0
while IFS= read -r -d $'\0' file; do
    echo "Found: $file"
    ((count++))
    if [ $count -ge 5 ]; then break; fi
done < <(find "$INPUT_DIR" -type f -name "*.zip" -print0)
echo ""

echo "Method 4: Using a temp file"
find "$INPUT_DIR" -type f -name "*.zip" > /tmp/test_files.txt
while IFS= read -r file; do
    echo "Found: $file"
done < /tmp/test_files.txt | head -5
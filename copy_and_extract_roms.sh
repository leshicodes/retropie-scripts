#!/bin/bash

#==============================================================================
# ROM Archive Copy & Extract Script
# Recursively copies and extracts .zip and .7z ROM archives from backup
# to active ROM directories with idempotent behavior
#==============================================================================

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global flags
DRY_RUN=false
#  

#==============================================================================
# PHASE 0: Argument Parsing & Validation
#==============================================================================

show_usage() {
    cat << EOF
Usage: $0 <input_dir> <output_dir> [--dry-run]

Arguments:
    input_dir   Source directory containing ROM archives (e.g., /home/user/RetroPie/backup-roms)
    output_dir  Target directory for extracted ROMs (e.g., /home/user/RetroPie/roms)
    --dry-run   Show what would be done without making any changes

Example:
    $0 /home/jjambrose1s/RetroPie/backup-roms /home/jjambrose1s/RetroPie/roms --dry-run
    $0 /home/jjambrose1s/RetroPie/backup-roms /home/jjambrose1s/RetroPie/roms

EOF
    exit 1
}

parse_arguments() {
    if [ $# -lt 2 ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        show_usage
    fi

    INPUT_DIR="$1"
    OUTPUT_DIR="$2"

    # Check for dry-run flag
    if [ $# -eq 3 ] && [ "$3" == "--dry-run" ]; then
        DRY_RUN=true
        echo -e "${YELLOW}=== DRY RUN MODE ===${NC}"
        echo -e "${YELLOW}No files will be copied, extracted, or deleted${NC}"
        echo ""
    fi

    # Validate input directory
    if [ ! -d "$INPUT_DIR" ]; then
        echo -e "${RED}Error: Input directory does not exist: $INPUT_DIR${NC}"
        exit 1
    fi

    # Validate output directory
    if [ ! -d "$OUTPUT_DIR" ]; then
        echo -e "${RED}Error: Output directory does not exist: $OUTPUT_DIR${NC}"
        exit 1
    fi

    echo -e "${GREEN}Input directory:${NC}  $INPUT_DIR"
    echo -e "${GREEN}Output directory:${NC} $OUTPUT_DIR"
    echo ""
}

#==============================================================================
# PHASE 1: Helper Functions
#==============================================================================

# Map emulator directory names (handle special cases)
map_emulator_name() {
    local emulator="$1"
    
    case "$emulator" in
        "dc")
            echo "dreamcast"
            ;;
        "nintendo-dsi")
            echo "nds"
            ;;
        *)
            echo "$emulator"
            ;;
    esac
}

# Check if archive is already extracted in output directory
is_already_extracted() {
    local archive_path="$1"
    local output_emulator_dir="$2"
    
    # Get archive filename without extension
    local archive_name=$(basename "$archive_path")
    local dir_name="${archive_name%.*}"  # Remove .zip or .7z extension
    
    # Check if extraction directory already exists
    local extract_dir="$output_emulator_dir/$dir_name"
    
    if [ -d "$extract_dir" ]; then
        return 0  # Already extracted
    else
        return 1  # Not extracted
    fi
}

# Extract archive (supports .zip and .7z)
extract_archive() {
    local archive_path="$1"
    local extract_to_dir="$2"
    
    # Get archive filename and extension
    local archive_name=$(basename "$archive_path")
    local extension="${archive_name##*.}"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${CYAN}[DRY RUN]${NC} Would extract: $archive_path"
        echo -e "${CYAN}[DRY RUN]${NC} To directory: $extract_to_dir"
        return 0
    fi
    
    # Create extraction directory
    mkdir -p "$extract_to_dir"
    
    # Extract based on file type
    case "$extension" in
        "zip")
            if unzip -q "$archive_path" -d "$extract_to_dir"; then
                echo -e "${GREEN}✓${NC} Extracted: $archive_name"
                return 0
            else
                echo -e "${RED}✗${NC} Failed to extract: $archive_name"
                return 1
            fi
            ;;
        "7z")
            if 7z x "$archive_path" -o"$extract_to_dir" -y > /dev/null 2>&1; then
                echo -e "${GREEN}✓${NC} Extracted: $archive_name"
                return 0
            else
                echo -e "${RED}✗${NC} Failed to extract: $archive_name"
                return 1
            fi
            ;;
        *)
            echo -e "${RED}✗${NC} Unsupported archive format: $extension"
            return 1
            ;;
    esac
}

# Copy archive to destination
copy_archive() {
    local source="$1"
    local destination="$2"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${CYAN}[DRY RUN]${NC} Would copy: $source"
        echo -e "${CYAN}[DRY RUN]${NC} To: $destination"
        return 0
    fi
    
    if cp "$source" "$destination"; then
        return 0
    else
        echo -e "${RED}✗${NC} Failed to copy: $(basename "$source")"
        return 1
    fi
}

# Cleanup archive after successful extraction
cleanup_archive() {
    local archive_path="$1"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${CYAN}[DRY RUN]${NC} Would delete: $archive_path"
        return 0
    fi
    
    if rm "$archive_path"; then
        echo -e "${GREEN}✓${NC} Cleaned up: $(basename "$archive_path")"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} Failed to cleanup: $(basename "$archive_path")"
        return 1
    fi
}

#==============================================================================
# PHASE 2: Main Processing Logic
#==============================================================================

process_archives() {
    local input_dir="$1"
    local output_dir="$2"
    
    # Statistics
    local total_found=0
    local total_skipped=0
    local total_processed=0
    local total_failed=0
    
    echo -e "${BLUE}Scanning for archives...${NC}"
    echo ""
    
    # Find all .zip and .7z files recursively, excluding neo* directories
    # Using -L to follow symbolic links
    while IFS= read -r -d $'\0' archive; do
        ((total_found++))
        
        # Extract emulator name from path
        # Path structure: /backup-roms/{EMULATOR}/roms/...
        local relative_path="${archive#$input_dir/}"
        local emulator=$(echo "$relative_path" | cut -d'/' -f1)
        
        # Skip neo* directories
        if [[ "$emulator" == neo* ]]; then
            echo -e "${YELLOW}[IGNORE]${NC} Skipping neo* directory: $emulator/$(basename "$archive")"
            ((total_skipped++))
            continue
        fi
        
        # Map emulator name to output directory name
        local output_emulator=$(map_emulator_name "$emulator")
        local output_emulator_dir="$output_dir/$output_emulator"
        
        # Check if output emulator directory exists
        if [ ! -d "$output_emulator_dir" ]; then
            echo -e "${YELLOW}[SKIP]${NC} Output emulator directory doesn't exist: $output_emulator_dir"
            ((total_skipped++))
            continue
        fi
        
        # Check if already extracted
        if is_already_extracted "$archive" "$output_emulator_dir"; then
            local archive_name=$(basename "$archive")
            local dir_name="${archive_name%.*}"
            echo -e "${YELLOW}[SKIP]${NC} Already extracted: $emulator/$(basename "$archive")"
            echo -e "       Exists: $output_emulator_dir/$dir_name/"
            ((total_skipped++))
            continue
        fi
        
        # Process this archive
        echo -e "${GREEN}[PROCESS]${NC} $emulator/$(basename "$archive")"
        
        local archive_name=$(basename "$archive")
        local dir_name="${archive_name%.*}"
        local dest_archive="$output_emulator_dir/$archive_name"
        local dest_extract_dir="$output_emulator_dir/$dir_name"
        
        # Copy archive
        if ! copy_archive "$archive" "$dest_archive"; then
            ((total_failed++))
            echo ""
            continue
        fi
        
        # Extract archive
        if ! extract_archive "$dest_archive" "$dest_extract_dir"; then
            ((total_failed++))
            echo ""
            continue
        fi
        
        # Cleanup archive
        cleanup_archive "$dest_archive"
        
        ((total_processed++))
        echo ""
        
    done < <(find -L "$input_dir" -type f -name "*.zip" -print0; find -L "$input_dir" -type f -name "*.7z" -print0)
    # Print summary
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "Total archives found:    $total_found"
    echo -e "${YELLOW}Skipped (already done):  $total_skipped${NC}"
    echo -e "${GREEN}Successfully processed:  $total_processed${NC}"
    echo -e "${RED}Failed:                  $total_failed${NC}"
    echo ""
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}This was a DRY RUN - no changes were made${NC}"
        echo -e "${YELLOW}Run without --dry-run to perform actual operations${NC}"
    fi
}

#==============================================================================
# Main Execution
#==============================================================================

main() {
    # Check dependencies
    if ! command -v unzip &> /dev/null; then
        echo -e "${RED}Error: 'unzip' command not found. Please install it.${NC}"
        exit 1
    fi
    
    if ! command -v 7z &> /dev/null; then
        echo -e "${RED}Error: '7z' command not found. Please install p7zip-full.${NC}"
        exit 1
    fi
    
    # Parse and validate arguments
    parse_arguments "$@"
    
    # Process archives
    process_archives "$INPUT_DIR" "$OUTPUT_DIR"
}

# Run main function
main "$@"
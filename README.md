# RetroPie ROM Management Scripts

A collection of Bash scripts for managing ROM archives in RetroPie setups.

## Scripts

### `copy_and_extract_roms.sh`

Recursively copies and extracts `.zip` and `.7z` ROM archives from a backup directory to your active RetroPie ROM directories with intelligent idempotent behavior.

#### Features

- ✅ **Idempotent** - Skips archives that are already extracted (safe to run multiple times)
- ✅ **Dry-run mode** - Preview what will happen before making changes
- ✅ **Multi-format support** - Handles both `.zip` and `.7z` archives
- ✅ **Multi-disc game support** - Automatically consolidates multi-disc games into single directories
- ✅ **Symbolic link aware** - Follows symlinks in source directories
- ✅ **Smart emulator mapping** - Handles special cases (dc→dreamcast, nintendo-dsi→nds)
- ✅ **Selective processing** - Can ignore specific emulator directories
- ✅ **Auto-cleanup** - Removes archives after successful extraction
- ✅ **Detailed reporting** - Color-coded output with statistics

#### Requirements

- `unzip` - For extracting ZIP files
- `7z` (p7zip-full) - For extracting 7z files

Install on Debian/Ubuntu/RetroPie:
```bash
sudo apt-get install unzip p7zip-full
```

#### Usage

```bash
./copy_and_extract_roms.sh <input_dir> <output_dir> [--dry-run]
```

**Arguments:**
- `input_dir` - Source directory containing ROM archives (e.g., `/home/user/RetroPie/backup-roms`)
- `output_dir` - Target directory for extracted ROMs (e.g., `/home/user/RetroPie/roms`)
- `--dry-run` - (Optional) Show what would be done without making any changes

#### Examples

**Dry run (recommended first):**
```bash
./copy_and_extract_roms.sh /home/jjambrose1s/RetroPie/backup-roms /home/jjambrose1s/RetroPie/roms --dry-run
```

**Actual execution:**
```bash
./copy_and_extract_roms.sh /home/jjambrose1s/RetroPie/backup-roms /home/jjambrose1s/RetroPie/roms
```

#### Directory Structure

**Expected Input Structure:**
```
/backup-roms/
├── n64/
│   └── roms/
│       ├── Super Mario 64 (USA).zip
│       └── Legend of Zelda (USA).zip
├── snes/
│   └── roms/
│       └── Super Metroid (USA).zip
├── psx/
│   └── roms/
│       ├── Final Fantasy VII (USA) (Disc 1).7z
│       ├── Final Fantasy VII (USA) (Disc 2).7z
│       └── Final Fantasy VII (USA) (Disc 3).7z
└── dc/
    └── roms/
        └── Crazy Taxi (USA).7z
```

**Output Structure:**
```
/roms/
├── n64/
│   ├── Super Mario 64 (USA)/
│   │   └── [extracted ROM files]
│   └── Legend of Zelda (USA)/
│       └── [extracted ROM files]
├── snes/
│   └── Super Metroid (USA)/
│       └── [extracted ROM file]
├── psx/
│   └── Final Fantasy VII (USA)/
│       ├── Final Fantasy VII (USA) (Disc 1).bin
│       ├── Final Fantasy VII (USA) (Disc 1).cue
│       ├── Final Fantasy VII (USA) (Disc 2).bin
│       ├── Final Fantasy VII (USA) (Disc 2).cue
│       ├── Final Fantasy VII (USA) (Disc 3).bin
│       └── Final Fantasy VII (USA) (Disc 3).cue
└── dreamcast/
    └── Crazy Taxi (USA)/
        └── [extracted game files]
```

#### How It Works

1. **Scans** input directory recursively for `.zip` and `.7z` files
2. **Extracts** emulator name from path structure
3. **Maps** emulator names (handles special cases like `dc` → `dreamcast`)
4. **Detects multi-disc games** (e.g., `(Disc 1)`, `(Disc 2)`) and strips disc numbers
5. **Checks** if archive is already extracted in output directory
6. **Skips** if already extracted (idempotent behavior)
7. **Copies** archive to output emulator directory (only if needed)
8. **Extracts** to folder matching the base game name (multi-disc games share one directory)
9. **Cleans up** the copied archive after successful extraction

#### Multi-Disc Game Handling

The script intelligently detects and consolidates multi-disc games:

- **Patterns detected**: `(Disc N)`, `(Disk N)`, `[Disc N]`, `[Disk N]` (case insensitive)
- **Behavior**: All discs extract into a single parent directory named after the game
- **Example**: 
  - Input: `Final Fantasy VIII (USA) (Disc 1).7z`, `Final Fantasy VIII (USA) (Disc 2).7z`, etc.
  - Output directory: `Final Fantasy VIII (USA)/` containing all disc files
- **Safety**: Only removes disc patterns at the end of filenames, preserving region codes, languages, and revision numbers like `(USA)`, `(En,Ja)`, `(Rev 2)`

#### Special Emulator Mappings

The script handles these special cases automatically:

| Input Directory | Output Directory |
|-----------------|------------------|
| `dc` | `dreamcast` |
| `nintendo-dsi` | `nds` |

#### Ignored Directories

The script automatically **ignores** all directories matching `neo*`:
- `neogeo`
- `neogeoaes`
- `neogeomvs`
- `neo-geo-cd`
- `neo-geo-x`

These are skipped to avoid conflicts or redundant processing.

#### Output Examples

**Dry Run Output:**
```
=== DRY RUN MODE ===
No files will be copied, extracted, or deleted

Input directory:  /home/jjambrose1s/RetroPie/backup-roms
Output directory: /home/jjambrose1s/RetroPie/roms

Scanning for archives...

[PROCESS] n64/Super Mario 64 (USA).zip
[DRY RUN] Would copy: /home/jjambrose1s/RetroPie/backup-roms/n64/roms/Super Mario 64 (USA).zip
[DRY RUN] To: /home/jjambrose1s/RetroPie/roms/n64/Super Mario 64 (USA).zip
[DRY RUN] Would extract: /home/jjambrose1s/RetroPie/roms/n64/Super Mario 64 (USA).zip
[DRY RUN] To directory: /home/jjambrose1s/RetroPie/roms/n64/Super Mario 64 (USA)
[DRY RUN] Would delete: /home/jjambrose1s/RetroPie/roms/n64/Super Mario 64 (USA).zip

[SKIP] Already extracted: n64/Mario Kart 64 (USA).zip
       Exists: /home/jjambrose1s/RetroPie/roms/n64/Mario Kart 64 (USA)/

[IGNORE] Skipping neo* directory: neogeo/game.zip

========================================
Summary
========================================
Total archives found:    50
Skipped (already done):  40
Successfully processed:  8
Failed:                  0

This was a DRY RUN - no changes were made
Run without --dry-run to perform actual operations
```

#### Troubleshooting

**No archives found:**
- Ensure input directory path is correct
- If using symbolic links, the script uses `-L` flag to follow them
- Check that archives are in `{emulator}/roms/` subdirectories

**Permission denied:**
```bash
chmod +x copy_and_extract_roms.sh
```

**7z command not found:**
```bash
sudo apt-get install p7zip-full
```

**Archives not being extracted:**
- Verify output emulator directory exists
- Check that archive isn't already extracted (look for matching directory name)
- Run with dry-run to see what's being skipped

### `helper_functions.sh`

Legacy helper functions for unzipping archives. These are standalone functions that can be sourced in other scripts.

#### Functions

- `unzip_to_dir <zipfile>` - Extracts a single ZIP file to a directory matching its name
- `unzip_all` - Extracts all ZIP files in current directory to matching directories

**Note:** These functions only support `.zip` files, not `.7z`. For comprehensive archive handling, use `copy_and_extract_roms.sh`.

## Contributing

Feel free to submit issues or pull requests for improvements!

## License

These scripts are provided as-is for personal use with RetroPie setups.
#!/usr/bin/env python3
"""
Script to remove all .png files from the VEIL-OF-RUIN repository.
This script:
- Finds all .png files recursively
- Deletes ONLY .png files (leaves .png.import files untouched)
- Does not modify any code or project configuration
- Reports what was deleted
"""

import os
import sys
from pathlib import Path

def remove_all_pngs(repo_root="."):
    """Remove all .png files from the repository."""
    repo_path = Path(repo_root)
    deleted_files = []
    failed_files = []
    
    # Find all .png files recursively
    png_files = list(repo_path.rglob("*.png"))
    
    if not png_files:
        print("No .png files found in the repository.")
        return
    
    print(f"Found {len(png_files)} .png files to delete.\n")
    
    # Delete each .png file
    for png_file in png_files:
        try:
            os.remove(png_file)
            deleted_files.append(str(png_file.relative_to(repo_path)))
            print(f"✓ Deleted: {png_file.relative_to(repo_path)}")
        except Exception as e:
            failed_files.append((str(png_file.relative_to(repo_path)), str(e)))
            print(f"✗ Failed to delete: {png_file.relative_to(repo_path)} - {e}")
    
    # Print summary
    print(f"\n{'='*60}")
    print(f"Summary:")
    print(f"  Total .png files deleted: {len(deleted_files)}")
    if failed_files:
        print(f"  Failed deletions: {len(failed_files)}")
        for file, error in failed_files:
            print(f"    - {file}: {error}")
    print(f"{'='*60}")
    
    # Verify .png.import files were NOT deleted
    remaining_imports = list(repo_path.rglob("*.png.import"))
    print(f"\n✓ Verification: {len(remaining_imports)} .png.import files preserved")
    
    return len(deleted_files), len(failed_files)

if __name__ == "__main__":
    repo_root = sys.argv[1] if len(sys.argv) > 1 else "."
    deleted, failed = remove_all_pngs(repo_root)
    sys.exit(0 if failed == 0 else 1)

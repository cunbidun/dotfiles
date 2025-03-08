#!/usr/bin/env python3

import os
import sys
import subprocess
import argparse
import logging

# Set up basic logging
logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")

def get_installed_extensions():
    """
    Returns a set of extension IDs currently installed in VS Code by calling 'code --list-extensions'.
    """
    try:
        result = subprocess.run(
            ["code", "--list-extensions"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True
        )
        extensions = set(result.stdout.splitlines())
        logging.info("Retrieved %d installed extensions.", len(extensions))
        return extensions
    except subprocess.CalledProcessError as e:
        logging.error("Error retrieving installed extensions: %s", e.stderr.strip())
        sys.exit(1)

def freeze_extensions(file_path):
    """
    Freeze the list of currently installed VS Code extensions into the given file.

    - The file is expected to have comment lines (starting with '#') and blank lines.
    - Existing extension IDs in the file that are no longer installed will be removed.
    - New extensions (installed but not in the file) will be appended at the end.
    """
    installed = get_installed_extensions()

    # Ensure the directory exists.
    os.makedirs(os.path.dirname(file_path), exist_ok=True)
    
    # Read existing file contents if the file exists.
    existing_lines = []
    if os.path.exists(file_path):
        with open(file_path, "r") as f:
            existing_lines = f.readlines()
        logging.info("Read %d lines from %s", len(existing_lines), file_path)
    else:
        logging.info("No existing file at %s. A new file will be created.", file_path)

    # Parse current extension IDs from file and preserve comment/blank lines.
    preserved_lines = []
    recorded_extensions = set()
    for line in existing_lines:
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            # Preserve comment and blank lines as-is.
            preserved_lines.append(line.rstrip("\n"))
        else:
            # This is assumed to be an extension ID.
            if stripped in installed:
                recorded_extensions.add(stripped)
                preserved_lines.append(stripped)
            else:
                # Extension in file but no longer installed; skip it.
                logging.info("Removing extension from file (no longer installed): %s", stripped)

    # Determine which installed extensions are not yet recorded.
    missing_extensions = installed - recorded_extensions
    if missing_extensions:
        preserved_lines.append("")  # Blank line separator.
        preserved_lines.append("# New extensions added:")
        for ext in sorted(missing_extensions):
            preserved_lines.append(ext)
            logging.info("Appending new extension: %s", ext)

    # Write back to file.
    try:
        with open(file_path, "w") as f:
            f.write("\n".join(preserved_lines) + "\n")
        logging.info("Successfully updated the extensions file: %s", file_path)
    except IOError as e:
        logging.error("Error writing to file %s: %s", file_path, str(e))
        sys.exit(1)

def load_extensions(file_path):
    """
    Synchronize VS Code extensions with those listed in the given file.

    - Installs any extension listed in the file that is not currently installed.
    - Uninstalls any extension currently installed that is not in the file.
    """
    # Ensure the file exists.
    if not os.path.exists(file_path):
        logging.error("Extensions file does not exist: %s", file_path)
        sys.exit(1)

    # Parse desired extensions from file.
    with open(file_path, "r") as f:
        lines = f.readlines()
    desired_extensions = set()
    for line in lines:
        stripped = line.strip()
        if stripped and not stripped.startswith("#"):
            desired_extensions.add(stripped)
    logging.info("Desired extensions count from file: %d", len(desired_extensions))

    # Get currently installed extensions.
    installed_extensions = get_installed_extensions()

    # Install extensions that are in the file but not currently installed.
    to_install = desired_extensions - installed_extensions
    for ext in sorted(to_install):
        logging.info("Installing extension: %s", ext)
        try:
            subprocess.run(["code", "--install-extension", ext], check=True)
        except subprocess.CalledProcessError as e:
            logging.error("Failed to install extension %s: %s", ext, e.stderr.strip())

    # Uninstall extensions that are installed but not in the file.
    to_uninstall = installed_extensions - desired_extensions
    for ext in sorted(to_uninstall):
        logging.info("Uninstalling extension: %s", ext)
        try:
            subprocess.run(["code", "--uninstall-extension", ext], check=True)
        except subprocess.CalledProcessError as e:
            logging.error("Failed to uninstall extension %s: %s", ext, e.stderr.strip())

    logging.info("Extension synchronization complete.")

def main():
    parser = argparse.ArgumentParser(
        description="Manage VS Code extensions: freeze current state or load/synchronize extensions."
    )
    default_file = os.path.expanduser("~/dotfiles/utilities/Code/extensions.txt")
    parser.add_argument("action", choices=["freeze", "load"],
                        help="Action to perform: 'freeze' to save installed extensions, 'load' to synchronize extensions.")
    parser.add_argument("--file", default=default_file,
                        help=f"Path to the extensions file (default: {default_file}).")
    args = parser.parse_args()

    if args.action == "freeze":
        freeze_extensions(args.file)
    elif args.action == "load":
        load_extensions(args.file)
    else:
        logging.error("Unknown action: %s", args.action)
        sys.exit(1)

if __name__ == "__main__":
    main()

#!/usr/bin/env bash

# Function to get stable generation IDs from Git tags
get_stable_generations() {
    git_tags=$(git tag -l 'nixos/stable-*')
    stable_generations=()
    for tag in $git_tags; do
        # Extract the generation ID from the tag
        gen_id=$(echo $tag | sed -n 's/.*-generation-\([0-9]*\)-tag/\1/p')
        stable_generations+=($gen_id)
    done
    echo "${stable_generations[@]}"
}

# List all generations and get their IDs
generations=$(sudo nix-env --list-generations -p /nix/var/nix/profiles/system)

# Get stable generation IDs from Git tags
stable_generations=($(get_stable_generations))

# Print stable generations
echo "Stable generations (from Git tags):"
for gen_id in "${stable_generations[@]}"; do
    echo "Stable Generation ID: $gen_id"
done

# Get the current date in seconds since epoch
current_date=$(date +%s)

# Array to hold generations to delete
generations_to_delete=()

# Iterate over each generation
while IFS= read -r line; do
    # Extract generation ID and date
    gen_id=$(echo "$line" | awk '{print $1}')
    gen_date=$(echo "$line" | awk '{print $2 " " $3 " " $4}')
    
    # Convert generation date to seconds since epoch
    gen_date_seconds=$(date -d "$gen_date" +%s)
    
    # Calculate the age of the generation in days
    age_days=$(( (current_date - gen_date_seconds) / 86400 ))
    
    # Check if the generation is older than 14 days and not a stable generation
    if [[ $age_days -gt 14 ]] && [[ ! " ${stable_generations[@]} " =~ " ${gen_id} " ]]; then
        # Add to the list of generations to delete
        generations_to_delete+=($gen_id)
    fi
done <<< "$generations"

# Print the list of generations that will be deleted for confirmation
echo "The following generations will be deleted (older than 14 days and not stable):"
for gen_id in "${generations_to_delete[@]}"; do
    echo "Generation ID: $gen_id"
done

# Confirm deletion
read -p "Do you want to proceed with deletion? (y/n): " confirm
if [[ $confirm == "y" ]]; then
    # Delete the old generations
    for gen_id in "${generations_to_delete[@]}"; do
        echo "Deleting generation $gen_id"
        sudo nix-env --delete-generations $gen_id -p /nix/var/nix/profiles/system
    done
    # Run garbage collection
    sudo nix-collect-garbage
    echo "Deletion and garbage collection completed."
else
    echo "Deletion canceled."
fi

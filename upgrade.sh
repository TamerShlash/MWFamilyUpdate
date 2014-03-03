#!/bin/bash

if [[ $# -eq 0 ]]; then
  echo "Usage Guide"
  exit
fi

echo "Downloading update file from: $1"
wget $1

update_gz=$(echo $1 | awk -F'/' '{print $(NF)}')
if ! [[ -e $update_gz ]]; then
  echo "Couldn't download update file, terminating..."
  exit
fi

echo "Unzipping update file..."
gunzip $update_gz

update_file=$(echo $update_gz | awk -F'.gz' '{print $1}')

if ! [[ -e $update_file ]]; then
  echo "Error while unzipping update file, terminating..."
  exit
fi


if [[ $update_file == *patch* ]]; then
  # Update for patches like 1.22.1 and 1.22.2

  echo -e "Doing a dry run for the patch file:\n"
  patch -p1 --dry-run < $update_file
  echo "Now the patch will be run actually, proceed? (Y/N)"
  read ans
  if [ $ans -eq 'N' -o $ans -eq 'n' ]; then
    echo "You have chosen not to proceed with the patch, terminating..."
    exit
  fi

  echo "Patching..."
  patch -p1 < $update_file
  echo "DONE: Patching files, now running the update script..."
else
  # Update for majors like 1.22 and 1.23
  echo "Extracting new files..."
  tar -xvf $update_file -C ./ --strip-components=1
  echo "DONE: Files extraction, now running the update script..."
fi

# Generic update steps like running update.php for DB update, and rebuilding localization cache
echo "Backing up the main LocalSettings.php file..."
mv "LocalSettings.php" "LocalSettings.php.backup"

for f in LocalSettings_*.php
do
  echo "Running Update for $f"
  cp $f "LocalSettings.php"
  php "maintenance/update.php"
  php "maintenance/rebuildLocalisationCache.php" #"--force"
  rm "LocalSettings.php"
  echo -e "DONE: Updating for $f\n"
done

echo "DONE: Updating for all wikis, now restoring the LocalSettings.php file..."
mv "LocalSettings.php.backup" "LocalSettings.php"
echo "Removing update file(s)..."
if [[ -e $update_gz ]]; then
  rm $update_gz
fi
if [[ -e $update_file ]]; then
  rm $update_file
fi
echo "All Done, Have Fun!"

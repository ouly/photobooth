#!/bin/bash
# Slideshow script for self-made photo-booth. This script has been tested and
# used on Lubuntu 16.04 and Lubuntu 18.04.
#
# Requirements:
# 
# -   Needs following packages: gpicview, gphoto2
# 
#         $ sudo apt-get install gpicview gphoto2
# 
# -   Do not mount camera folder! Otherwise gphoto2 won't be able to access the
#     folder.
# -   For the slideshow to run fullscreen, following lines must be added to
#     ~/.config/openbox/lubuntu-rc.xml
# 
#         <application name="gpicview">
#          <fullscreen>true</fullscreen>
#         </application>
# 
#     Then, reconfigure OpenBox for previous settings change to take effect:
# 
#         $ openbox --reconfigure
# 
# Author: Olivier Wenger
# Version: 2023-10-25
# 
# Bibliography
#
# 1.  Contributors of LXDE forum, _Start gpicview in fullscreen_, 2013,
#     https://forum.lxde.org/viewtopic.php?p=48226&sid=e429cd449d64844c0c71f9dd2dd4f844#p48226
# 2.  _The gPhoto2 Reference (the man pages)_,
#     http://www.gphoto.org/doc/manual/ref-gphoto2-cli.html

# Configuration, adjust as necessary
varCameraFolder="/store_00020001/DCIM/100CANON"
varDestFolder="${HOME}/Images/photobooth"
varSleepTime=5

# Check config
if [ ! -d "${varDestFolder}" ]; then
    echo "ERROR: destination folder does not exist!"
    exit
fi

# DEBUG: useful commands for debugging...
#
#     $ gphoto2 --list-ports
#     $ gphoto2 --auto-detect
#     $ gphoto2 --summary

if [ "$(gphoto2 --auto-detect | tail -n +3)" == "" ]; then
    echo "ERROR: no camera found!"
    exit
fi

# Initialisation
varNewest="${varDestFolder}/$(ls -1t -- "${varDestFolder}/" | head -1)"
varCountPic=$(gphoto2 --num-files --folder "${varCameraFolder}")
varCountPic=${varCountPic##* }
echo "INFO: ${varCountPic} pictures already on the camera!"
echo "DEBUG: newest entry found in dest folder: ${varNewest}"

while true; do
    echo "INFO: start of main loop..."
    for varCurrFile in "${varDestFolder}"/*.JPG; do
        varDisplayFile=""
        while [ "${varCurrFile}" != "${varDisplayFile}" ]; do
            varDisplayFile="${varCurrFile}"
            echo "INFO: trying to display file: ${varDisplayFile}"
            # Sync files
            varNewCountPic=$(gphoto2 --num-files --folder "${varCameraFolder}")
            varNewCountPic=${varNewCountPic##* }
            if [ "${varCountPic}" != "${varNewCountPic}" ]; then
                echo "INFO: new pictures found, last index: ${varNewCountPic}"
                cd "${varDestFolder}"
                gphoto2 --get-file=$((varCountPic+1))-${varNewCountPic} --folder "${varCameraFolder}"
                varCountPic=${varNewCountPic}
            fi
            # Switch to newly added file, if present
            varCheckNew="${varDestFolder}/$(ls -1t -- "${varDestFolder}/" | head -1)"
            if [ "${varNewest}" != "${varCheckNew}" ]; then
                varNewest="${varCheckNew}"
                varDisplayFile="${varCheckNew}"
                echo "INFO: new file detected and dispatched for display!"
            fi
            # Display the file with GPicView and kill previous instances
            # Note: killing is done after sleeping to reduce visual glitches
            echo "INFO: display file: ${varDisplayFile}"
            varProc=$(pgrep gpicview | xargs)
            gpicview "${varDisplayFile}" &
            # Keep picture on the screen during a certain time
            sleep ${varSleepTime}
            if [ "${varProc}" != "" ]; then
                kill ${varProc}
                varProc=""
            fi
        done
    done
    echo "INFO: end of main loop."
done

# END OF FILE #

#!/bin/bash
# This script resizes all the png or jpg files in the current folder.
#
# The files must follow a specific naming convention and should be indexed
# by a number. The name of a file must have the following format:
#
#		{name}_{number}.{extension}
#
# where {name} is a generic name for all the files to be processed,
# {number} is the number that indexes each of the files and {extension} is
# the file extension, that is either .png or .jpg"
#
# A new folder will be created, that will store all the resized and compressed
# files.


Help() {
	echo "Resize and compress all the jpg or png files in this folder"
	echo
	echo "The files must follow the naming convention {name}_{number}.{ext},"
	echo "where {name} is the same for all the files you want to compress,"
	echo "{number} is a number that uniquely identifies each photo and {ext}"
	echo "is the file extension (either .jpg or .png)"
	echo
	echo "Syntax:	resize_and_compress <start> <end> <file_name> <ext> <width>"
	echo
	echo "<start> is the number of the first file to be processed"
	echo "<end> is the number of the last file to be processed"
	echo "<file_name> is the name of the files you want to process."
	echo "	This name must be the same for all the files, the only thing"
	echo "	that differentiates them should be the {number}."
	echo "<ext> is the extension of the file (png or jpg)"
	echo "<width> is the width of the resized file."
	echo
	echo
}

Help


# File name should have the following format: <<${file_name}_${number}.jpg>>
# <<number>> will be added to the file name in the while loop.

# First and last index of the files
start_it=$1
end_it=$2
# Generic file name
file_name=$3
# File extension (png or jpg)
ext=$4
# Width of the resized file
width=$5
# Name of the temporary file
temp_name="temp_file.jpg"

# Print the data received as input for control purposes
echo "Generic file name is ${file_name}"
echo "Start and end indexes are ${start_it}, ${end_it}"
echo "File extension is ${ext}"
echo "Image width is ${width}"

# Create a folder for the resized and compressed images, if it does not already exist
folder_name="resize_comp_${width}"
if [ ! -d ${folder_name} ]; 
then
	echo "Created directory ${folder_name}."
	mkdir $folder_name
fi

iter=$start_it
# Take the first file to be compressed
while [ $iter -le $end_it ];
do
	# Build the name of the first file, out of the generic file name
	# and the number we currently process
	fil="${file_name}_${iter}.${ext}"
	# Only proceed with processing if the file exists
	if [ -f ${fil} ];
	then
		# Build the name of the output file 
		out_fil="${folder_name}/${file_name}_resz_${iter}.${ext}"
		# Create a temporary resized file, with the width given as a parameter
		ffmpeg -y \
		-loglevel error \
		-i $fil \
		-vf scale=$width:-1 \
		$temp_name
		# Take the resized file and compress it. Save it in the folder given
		# by $folder_name and append <<resz>> to its name, to indicate it was resized
		ffmpeg -y \
		-loglevel error \
		-i $temp_name \
		-compression_level 70 \
		$out_fil
		echo "${fil} resized and compressed"
	else
		echo "${fil} not found"
	fi
	# Pass to the next file
	((iter++))
done


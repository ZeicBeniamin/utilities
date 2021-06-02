#!/bin/bash
# Intercepts the SIGINT signal
function ctrl_c() {
	# Retrieve the list of process id-s that was passed as argument
	PID_LIST=("$@");
	echo
	echo "SIGINT Intercepted"
	echo "Killing threads:"
	# Display each of the id-s in the PID_LIST array
	for i in "${PID_LIST[@]}";
	do
		echo "- $i"
	done
	# Kill all the threads that have the given id-s and exit the script
	kill $PID_LIST
	echo "Exiting ..."
	exit
}

function Help() 
{
	echo "Convert files in folder to mp4 videos with specified parameters"
	echo 
	echo "Syntax:"
	echo "video_conv2 <path_to_folder> <output_folder> <bitrate> <crop>"
	echo 
	echo "path_to_folder	Path to the folder that contains the video files"
	echo "output_folder 	Name of folder that will store output files"
	echo "			This folder is contained within the one"
	echo "			specified in path_to_folder"
	echo "bitrate		Bitrate of the converted video. Read the"
	echo "			ffmpeg documentation to find out the valid"
	echo "			formats for the bitrate."
	echo "crop		Specifies the crop pattern for the video."
	echo "			Pattern is  (crop(top)x(bottom)x(left)x(right))"
	echo
}

##############################################################################
# MAIN PROGRAM 								     #
##############################################################################
# Print the help message
Help

# Take the command line arguments. Their description is given in Help() 
path=$1;
out_folder=$2;
bitrate=$3;
crop_pat=$4;

# $counter counts the number of threads started from the beggining of the 
# execution. The counter is zero-based.
counter=0;
# Declare the maximum number of parallel threads to be run at a time
max_threads=3;

# Check if the path passed as argument exists
if [[ -d $path ]]; then
	# Take each file or folder in the path. All the files in the folder should be
	# video files that have their format compatible with ffmpeg.
	for entry in $path*
	do
		# Take only the files from the specified path
		if [[ -f $entry ]]; then
			# Strip path from filename, but keep file extension
			fname_w_ext=${entry##*/};
			# Remove file extension
			fname=${fname_w_ext%.*};
			# Build the path of the input file
			in_path=${path}${fname_w_ext};
			# Debug-only outputs
			#echo "fname $fname";
			# Build the path and name of the output file
			out_path=${path}${out_folder}/${fname}"_comp.mp4";
			#Debug-only outputs
			#echo "output file is $out_path";
			#echo "input file is $in_path";
			# Build the command string for running ffmpeg on the
			# file currently processed
			command="ffmpeg -loglevel error \
			-y -vsync 0 \
			-hwaccel cuvid \
			-hwaccel_output_format cuda \
			-c:v h264_cuvid \
			-crop $crop_pat \
			-i '$in_path' \
			-c:a copy \
			-c:v h264_nvenc \
			-b:v $bitrate \
			'$out_path'";
			# Display the command
			echo "Command is:"
			echo $command;
			# Start the command in a separate thread and get the 
			# id of the process
			eval $command & pid=$!;
			# Debug-only
			#sleep 2s & pid=$!;
			# Display a message to the terminal
			echo "Started thread number ${counter}";
			echo "Thread id is:"
			echo $pid;
			# Add the process to the list of active processes
			PID_LIST+=" $pid";
			# Increment the thread counter. It keeps the total 
			# number of threads ran up until the current moment
			counter=$((counter + 1));
			# Trap SIGINT and send it to the function that hanles
			# interruptions, together with the PID_LIST array
			trap "ctrl_c ${PID_LIST[@]}" SIGINT
			# Limit the number of currently running threads to 
			# $max_threads.
			if [ $(($counter % $max_threads)) -eq 0 ]; then
				echo "Waiting for threads to complete"
				wait $PID_LIST;
				echo "Finished $max_threads threads"
			# Empty the list of threads after they have completed
				PID_LIST="";
			fi
		fi
	done
	# If the threads initialized were not a multiple of $max_threads
	# there have remained some threads that we did not wait for. We must
	# wait for them to complete.
	if [ $(($counter % $max_threads)) -ne 0 ]; then
		echo "Waiting for threads to complete"
		wait $PID_LIST;
		echo "Finished $(($counter % $max_threads)) threads"
		PID_LIST="";
	fi

fi

trap "kill $PID_LIST" SIGINT
echo "";
#echo "Output path is $destination";




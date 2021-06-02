#!/bin/bash
PID_LIST=()

function check_threads() {
    running_th=0;
    for i in "${!PID_LIST[@]}";
    do
        # Check if the currently processed thread is running
        output=$(ps -p "${PID_LIST[i]}")
        # If not, remove it
        if [ $? -ne 0 ]; then
            echo "Thread ${PID_LIST[i]} was stopped"
            unset 'PID_LIST[i]';
		else 
		# If it's still running, add it to the counter
			running_th=$((running_th + 1));
        fi
    done
	# Return the number of running threads.
    return $running_th
}

# Intercepts the SIGINT signal
function ctrl_c() {
	# Retrieve the list of process id-s that was passed as argument
#	PID_LIST=("$@");
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
v_bitrate=$3;
a_bitrate=$4
crop_pat=$5;

# $counter counts the number of threads started from the beggining of the 
# execution. The counter is zero-based.
counter=0;
finished=0;
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
			-b:v $v_bitrate \
			-b:a $a_bitrate \
			'$out_path'";
			# Display the command
			echo "Command is:"
			echo $command;
			# Start the command in a separate thread and get the 
			# id of the process
			eval $command & pid=$!;
			# Debug-only
#			sleep ${counter}s & pid=$!;
			# Display a message to the terminal
			echo "Started thread number ${counter}";
			echo "Thread id is: $pid"
			# Add the process to the list of active processes
			PID_LIST+=("$pid");
			# Increment the thread counter. It keeps the total 
			# number of threads ran up until the current moment
			counter=$((counter + 1));
			# Trap SIGINT and send it to the function that hanles
			# interruptions, together with the PID_LIST array
			trap 'ctrl_c' SIGINT
			# Check the number of currently running threads
			check_threads;
			running_threads=$?
			echo
			echo "$running_threads threads running"
			# If we have more threads than the maximum value, we
			# will wait for one thread to terminate, before 
			# starting another one. The check interval is 3s.
			while [ "$running_threads" -ge "$max_threads" ] 
			do	
				check_threads;
				running_threads=$?
				sleep 3s;
			done
		fi
	done
	# After leaving the loop, we still have $max_threads-1 threads
	# running. We must wait for those threads too.
	echo "Waiting for threads to complete"
	wait $PID_LIST;
	echo "Finished $(($counter % $max_threads)) threads"
fi



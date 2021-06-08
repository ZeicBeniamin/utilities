PID_LIST=()

function check_threads() {
	all_running=1;
	for i in "${!PID_LIST[@]}";
	do
		echo "List elems ${!PID_LIST[@]}"
		# Check if the currently processed process is running
		echo "Ia lista ${PID_LIST[i]}";
		output=$(ps -p "${PID_LIST[i]}")
		# If not, remove it and return 0
		if [ $? -ne 0 ]; then
			all_running=0;
			unset 'PID_LIST[i]';
			echo "Thread ${PID_LIST[i]} is stopped"
		fi
	done
	return $all_running
}


#for h in $(seq 1 20);
#do
	id=4527
	PID_LIST+=("$id")
	id=4400
	PID_LIST+=("$id")
	id=4532
	PID_LIST+=("$id")
	echo "LIST is" $PID_LIST
	check_threads
	echo $?
	check_threads
	echo $?

#done

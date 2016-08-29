. $(cd `dirname $0` && pwd)/boards.conf

# do not edit below this line
function get_variable {
	var_name=$1

	if [ ! -v "$var_name" ]; then
		echo "variable $var_name requested but not set, check the configuration file"
		exit
	fi

	echo ${!var_name}
}

function check_empty {
	if [ -z "$1" ]; then
		echo "error: $2"
		exit
	fi
}

function create_dir {
	mkdir -p "$1"

	if [ ! -d "$1" ]; then
		echo "error: $1 is not a directory!"
		exit
	fi
}

function create_dir_empty {
	mkdir -p "$1"

	if [ ! -d "$1" ]; then
		echo "error: $1 is not a directory!"
		exit
	fi

	if [ "$(ls -A $1)" ]; then
		echo "error: $1 is not empty!"
		exit
	fi
}

function make_temp_suffix {
	echo `mktemp --suffix=$1`
}

function remote_file_exists {
	f=$1

	if ! ssh ${TYR_USER}@${TYR_HOST} [ -f $f ]; then
		echo "remote file $f does not exist!"
		echo "$2"
		exit 1
	fi
}

function download {
	src=$1
	dst=$2

	echo "downloading $1"
	scp ${TYR_USER}@${TYR_HOST}:$src $dst
}

function rel_to_abs_file {
	echo $(cd `dirname $1` && pwd)/`basename $1`
}

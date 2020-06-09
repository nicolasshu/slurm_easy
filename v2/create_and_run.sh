echo "Begin"
file=""
env="../envs/speech"
comment=""
email="nshu@emory.edu"
mailtype="ALL"
verbose=false
time="5-23:0:0"
cp_data=""
dir="/tmp/nshu/tests"

# Parse all of the arguments
while [ ! $# -eq 0 ]
do
	case "$1" in 
		--help | -h)
			echo "Help"
			echo "-f | --file         Path to Python file"
			echo "-e | --env          Path to Python environment"
			echo "                        (Optional) Default '../envs/speech'"
			echo "-c | --comment      Custom comment"
			echo "                        (Optional) Default ''"
			echo "--email             Email recipient"
			echo "                        (Optional) Default nshu@emory.edu"
			echo "--mail-type         Type of alerts on email"
			echo "                        (Optional) Default: ALL"
			echo "-v | --verbose      Verbose boolean"
			echo "                        (Optional) Default false"
			echo "--copy-data         Copy a specific dataset"
			echo "-d | --dir          Location of experiment"
			exit
			;;
		--file | -f)
			file=$2
			name="${file%.*}"
			echo "Input file:  ${file}"
			echo "File name:   ${name}"
			;;
		--env | -e)
			echo $2
			env=$2
			echo "Environment: ${env}"
			;;
		--comment | -c)
			comment=$2
			;;
		--email)
			email=$2
			;;
		--mail-type)
			mailtype=$2
			;;
		--verbose | -v)
			verbose=true
			;;
		--time | -t)
			time=$2
			;;
		--dir | -d)
			dir=$2
			;;
		--copy-data)
			cp_data="cp -r /home/data/$2 /tmp/nshu/data"
			;;
	esac
	shift
done

# Throw error if no file is passed
if [ "$file" == "" ]
then
	echo " "
	echo "ERROR: No input file was given. Please enter a file with -f/--file"
	exit
fi

if [ "$dir" == "/tmp/nshu/tests" ]
then
	echo "The location of the experiments is the same as the default"
	echo $dir
fi

# Set the comment as its name if no comment is passed
if [ "$comment" == "" ]
then
	comment="${name}"
fi

# Create the main script
eval "cat << EOF 
source ${env}/bin/activate
python ${file}
EOF" > wrapper.sh


eval 'cat << EOF
#!/bin/sh
#SBATCH -J ${name}
#SBATCH --comment "${comment}"
#SBATCH --time ${time}

# Output and Error Files
#SBATCH --output results/%A_$name.out
#SBATCH --error results/%A_$name.err

#SBATCH --mem 6G
#SBATCH --nodes 1

#SBATCH --mail-user=${email}
#SBATCH --mail-type=${mail-type}

# Make dirs only if needed
mkdir -p ${dir}
mkdir -p /tmp/nshu/data

# Copy Data (Optional)
${cp_data}

# Copy Python and Wrapper file to /tmp
cp $file $dir
cp wrapper.sh $dir

# Change to that directory
cd $dir

# Make Symbolic Links
ln -s /tmp/nshu/data $dir 
ln -s /tmp/nshu/data_loaders/audioloaders $dir
ln -s /tmp/nshu/mci/net $dir

# Run the wrapped Python file
scl enable rh-python36 "bash wrapper.sh $file"

# Copy Back

EOF' > ${name}.sh


# Create the wrapper file
if [ "$verbose" = true ]
then
	echo "===================="
	echo "${name}.sh"
	echo "===================="
	cat ${name}.sh
	echo " "
	echo "===================="
	echo "wrapper.sh"
	echo "===================="
	cat wrapper.sh
fi 



# Clean up
#rm ${name}.sh
#rm wrapper.sh

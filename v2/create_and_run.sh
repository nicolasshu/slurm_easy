file=""
env="/home/nshu/envs/speech"
comment=""

cwd=$(pwd)

# PLEASE CHANGE THIS ======================
email="nshu@emory.edu"
# =========================================

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
			echo "-c | --comment      Custom comment"
			echo "                        (Optional) Default ''"
			echo "--copy-data         Copy a specific dataset"
			echo "-d | --dir          Location of experiment"
			echo "--email             Email recipient"
			echo "                        (Optional) Default $email"
			echo "-e | --env          Path to Python environment"
			echo "-f | --file         Path to Python file"
			echo "                        (Optional) Default $env"
			echo "--mail-type         Type of alerts on email"
			echo "                        (Optional) Default: $mailtype"
			echo "-t | --time         Desired time for the job"
			echo "                        (Optional) Default 5-23:0:0"
			echo "-v | --verbose      Verbose boolean"
			echo "                        (Optional) Default $verbose"
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
			dir="/tmp/nshu/$2"
			;;
		--copy-data)
			cp_data="cp -r /home/nshu/data/$2 /tmp/nshu/data"
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

# Create a folder to copy contents back to
mkdir -p ./results

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
#SBATCH --mail-type=${mailtype}

# ----------- CUSTOM COPYING BY NICOLAS SHU ----------------

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

# Copy environment
# cp -r ${env} ${dir}/../

# Copy gits
cp -r /home/nshu/basegits/mci /tmp/nshu/
cp -r /home/nshu/basegits/dataset_loaders /tmp/nshu/

# Make Symbolic Links
ln -s /tmp/nshu/data $dir 
ln -s /tmp/nshu/dataset_loaders/audioloaders $dir
ln -s /tmp/nshu/mci/net $dir

# -----------------------------------------------------------

# Run the wrapped Python file
scl enable rh-python36 "bash wrapper.sh $file"

# Copy Back
cp -r $dir $cwd/results


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
	echo " "
fi 

sbatch ${name}.sh

# Clean up
#rm ${name}.sh
#rm wrapper.sh


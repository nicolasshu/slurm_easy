echo " 1) Begin"
date

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

echo " 2) Parse arguments"
date

# Parse all of the arguments
while [ ! $# -eq 0 ]
do
	case "$1" in 
		--help | -h)
			echo "Help"
			echo "-f | --file         Path to Python file"
			echo "-e | --env          Path to Python environment"
			echo "                        (Optional) Default $env"
			echo "-c | --comment      Custom comment"
			echo "                        (Optional) Default ''"
			echo "--email             Email recipient"
			echo "                        (Optional) Default $email"
			echo "--mail-type         Type of alerts on email"
			echo "                        (Optional) Default: $mailtype"
			echo "-v | --verbose      Verbose boolean"
			echo "                        (Optional) Default $verbose"
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
			dir="/tmp/nshu/$2"
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

# Create a folder to copy contents back to
mkdir -p ./results

echo " 3) Create results folder"
date

# Create the main script
eval "cat << EOF 
source ${env}/bin/activate
echo '18) Activated the environment'
date
python ${file}
echo '19) Ran the python script'
date
EOF" > wrapper.sh

echo " 4) Created wrapper.sh"
date

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

echo " 8) Established the SBATCH parameters"
date

# Make dirs only if needed
mkdir -p ${dir}
echo " 9) Created ${dir}"
date

mkdir -p /tmp/nshu/data
echo "10) Created /tmp/nshu/data"
date

# Copy Data (Optional)
${cp_data}
echo "11) Copied the data"
date

# Copy Python and Wrapper file to /tmp
cp $file $dir
echo "12) Copied $file to $dir"
date
cp wrapper.sh $dir
echo "13) Copied wrapper.sh to $dir"
date

# Change to that directory
cd $dir
echo "14) Changed the directory"
date

# Copy environment
# cp -r ${env} ${dir}/../

# Copy gits
cp -r /home/nshu/basegits/mci /tmp/nshu/
cp -r /home/nshu/basegits/dataset_loaders /tmp/nshu/
echo "15) Copied the basegits"
date

# Make Symbolic Links
ln -s /tmp/nshu/data $dir 
ln -s /tmp/nshu/dataset_loaders/audioloaders $dir
ln -s /tmp/nshu/mci/net $dir
echo "16) Created symbolic links"
date

# -----------------------------------------------------------

# Run the wrapped Python file
echo "17) Run scl enable rh-python36"
date
scl enable rh-python36 "bash wrapper.sh $file"

# Copy Back
echo "20) Copying results back"
date
cp -r $dir $cwd/results


EOF' > ${name}.sh

echo ' 5) Created ${name}.sh'
date

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

echo " 6) Show scripts"
date

echo " 7) Deploy job via sbatch"
date
sbatch ${name}.sh

sleep 30
echo "21) Removing shell scripts"
date
# Clean up
rm ${name}.sh
rm wrapper.sh


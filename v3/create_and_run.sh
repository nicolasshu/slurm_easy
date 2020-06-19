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
basedir="/tmp/nshu/"
dir="tests"
deps=()
lns=()
dep_cmd=""
ln_cmd=""


# Parse all of the arguments
while [ ! $# -eq 0 ]
do
    case "$1" in 
        --help | -h)
            echo "HELP GUIDE"
            echo " "
            echo "-b, --basedir       Base directory"
            echo "                        (Optional) Default: ${basedir}"
            echo "                            E.g. -b /tmp/user/"
            echo "-c, --comment       Custom comment"
            echo "                        (Optional) Default: ''"
            echo "--copy-data         Copy a specific dataset"
            echo "                         E.g. If "
            echo "-d, --dir           Location of experiment in /tmp/ folder"
            echo "                        (Optional) Default: $dir"
            echo "                            E.g. -d foo    =>    testdir=/tmp/user/foo/"
            echo "                            E.g. -d bar    =>    testdir=/tmp/user/bar/"
            echo "--dep               Dependencies to be copied as well to the base directory"
            echo "                        (Optional) Default: None"
            echo "                            E.g. --dep pkg1 ~/pkg2    => "
            echo "                                /tmp/user/"
            echo "                                  > pkg1"
            echo "                                  > pkg2"
            echo "--email             Email recipient"
            echo "                        (Optional) Default: $email"
            echo "                            E.g. -d user@mail.org"
            echo "-e, --env           Path to Python environment"
            echo "                        (Optional) Default: ''"
            echo "                            E.g. -e ~/envs/myenv/"
            echo "-f, --file        **[REQUIRED] Path to Python file"
            echo "                            E.g. -f my_script.py"
            echo "--ln                Create symbolic links in dir folder"
            echo "                        (Optional) Default: None"
            echo "                            E.g. --ln ../pkg1 ../../pkg2"
            echo "--mail-type         Type of alerts on email"
            echo "                        (Optional) Default: $mailtype"
            echo "-t, --time          Desired time for the job"
            echo "                        (Optional) Default: $time"
            echo "-v, --verbose       Verbose boolean (i.e. no arguments needed)"
            echo "                        (Optional) Default: $verbose"
            exit
            ;;
        --comment | -c)
            comment=$2
            ;;
        --copy-data)
            cp_data=$2
            ;;
        --dir | -d)
            dir=$2
            ;;
        --dep)
            i=1
            # Iterate through dependencies and put them in an array
            for var in "${@:2}"
            do 
                if [ ${var:0:1} = "-" ]
                then 
                    break
                fi
                # Append the dependency to the array deps
                deps+=("$var")
                i=$((i=i+1))
            done
            ;;

        --email)
            email=$2
            ;;
        --env | -e)
            env=$2
            ;;
        --file | -f)
            file=$2
            name="${file%.*}"
            echo "Input file:        ${file}"
            echo "File name:         ${name}"
            ;;

        --mail-type)
            mailtype=$2
            ;;
        --ln)
            # Iterate through symbolic links and put them in an array
            for var in "${@:2}"
            do 
                if [ ${var:0:1} = "-" ]
                then 
                    break
                fi
                # Append the symbolic links to the array lns
                lns+=("$var")
            done
            ;;
            
        --time | -t)
            time=$2
            ;;
        --verbose | -v)
            verbose=true
            ;;


    esac
    shift
done

# Concatenate the base directory and test directory
testdir="${basedir%*/}/${dir}"

# CREATE COPYING COMMAND FOR DATASET
#     -n for skipping existing files
if [ "$cp_data" != "" ]
then 
    # Append the base directory, the data, and the dataset
    #     /tmp/user/data/dataset
    data_dir=${basedir%*/}/data/${cp_data}

    # Create a copy of dataset without overwriting files 
    cp_data_cmd="cp -rn /home/nshu/data/${cp_data} ${data_dir}"
fi 


# THROW ERROR IF NO INPUT FILE IS PASSED
if [ "$file" == "" ]
then
    echo " "
    echo "ERROR: No input file was given. Please enter a file with -f/--file"
    exit
fi

# LOG THE TEST DIRECTORY
if [ "$testdir" == "/tmp/nshu/tests" ]
then
    echo "Test dir:          ${testdir}"
    echo "                   (The location of the experiments is the same as the default)"
else
    echo "Test dir:          ${testdir}"
fi

# DEPENDENCIES (OPTIONAL)
if [ ${#deps[@]} -eq 0 ]
then 
    echo "Dependencies:      None"
else 
    echo "Dependencies(${#deps[@]}):   ${deps[@]}"

    # With the array of dependencies, for each dependency
    # create a copy command of that dependency to the base directory
    #     cp -rn /path/to/dep1/ /tmp/user/
    #     cp -rn /path/to/dep2/ /tmp/user/
    #     cp -rn /path/to/dep3/ /tmp/user/
    for dep in "${deps[@]}"
    do 
        var_cmd="cp -rn ${dep} ${basedir}"
        dep_cmd="${dep_cmd}${var_cmd}
"
    done
fi

# SYMBOLIC LINKS (OPTIONAL)
if [ ${#lns[@]} -eq 0 ]
then 
    echo "Symbolic Links:      None"
else 
    echo "Symbolic Links(${#lns[@]}):   ${lns[@]}"

    for ln in "${lns[@]}"
    do 
        var_cmd="ln -s ${ln}"
        ln_cmd="${ln_cmd}${var_cmd}
"
    done
fi


# Set the comment as its name if no comment is passed
if [ "$comment" == "" ]
then
    comment="${name}"
fi

# ENVIRONMENT (OPTIONAL)
if [ "$env" = "" ]
then 
    echo "Environment:       None selected"
else
    echo "Environment:       ${env}"

    # Establish the activate path 
    activate_path=${env%*/}/bin/activate

    # Write command to activate path
    source_activate="source ${activate_path}"
fi

# Create a folder to copy contents back to
# mkdir -p ./results

# Create the main script
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

#SBATCH -w cnode3

# ----------- CUSTOM COPYING BY NICOLAS SHU ----------------
# Activate the environment
${source_activate}

# Make dirs only if needed
mkdir -p ${testdir%*/}
mkdir -p ${basedir%*/}/data

# Copy dependencies (Optional)
${dep_cmd}

# Copy Data (Optional)
${cp_data_cmd}

# Copy Python and Wrapper file to /tmp
cp $file ${testdir}

# Change to that directory
cd ${testdir}

# Create Symbolic Links
${ln_cmd}

# -----------------------------------------------------------

# Run the wrapped Python file
python ${file}


EOF' > ${name}.sh

if $verbose
then 
    cat ${name}.sh
fi 

rm ${name}.sh
# sbatch ${name}.sh

# Example:
# bash create_and_run.sh -f py.py -e "~/envs/speech/" --copy-data dcase --dep /home/nshu/mci /home/nshu/dataset -d 'tests' -v
# bash create_and_run.sh -f py.py -e "~/envs/speech/" --copy-data dcase --dep /home/nshu/mci /home/nshu/dataset -d 'tests' --ln ../dataset_loaders/audioloaders ../data -v

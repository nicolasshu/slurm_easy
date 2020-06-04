#!/bin/sh
name=$1

cat << EOF
#!/bin/sh
#SBATCH -J $name
#SBATCH --comment "__enter_comment_here__"

# Partition and Time Span
#SBATCH --partition batch
#SBATCH --time 5-23:0:0

# Output and Error File
#SBATCH --output results/log_%A.out
#SBATCH --error results/log_%A.err 

#SBATCH --mem 6G
#SBATCH --nodes 1

#SBATCH --mail-user=nshu@emory.edu
#SBATCH --mail-type=ALL

scl enable rh-python36 "bash wrapper_template.sh $name"
EOF

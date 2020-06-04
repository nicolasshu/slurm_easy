#!/bin/sh
name=$1

cat << EOF
#!/bin/sh
#SBATCH -J $name
eval "bash wrapper_template.sh $name"
EOF

name=$1

bash template.sh $name > $name.sh
sbatch $name.sh
rm $name.sh

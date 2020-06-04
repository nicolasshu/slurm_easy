name=$1

bash template.sh $name > $name.sh
bash $name.sh
rm $name.sh

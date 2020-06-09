# Slurm - A Quick Solution for Python with Virtual Envs

![](20200605_slurm_easy.png)

This is a quick solution for running `sbatch` on Python scripts that are assumed to run on virtual environments.

## Instructions

1. If not done yet, create your Python virtual environment at `/path/to/env/`, where it should have a file `/path/to/env/bin/activate` file
1. Make sure that you have the following scripts on the same directory of your Python script
    - `create_and_run.sh`
    - `template.sh`
    - `test.sh`
    - `wrapper_template.sh`
1. Edit `template.sh` to ensure your `#SBATCH` options are custom to you
1. Edit your `wrapper_template.sh` script such that it sources the `activate` file in your environment location
    - E.g. `source /path/to/env/bin/activate`
1. (Optional) The `create_and_run.sh` script is set to remove the sbatch script (`rm $name.sh`). If you do not wish to remove it after releasing the submitting the job, comment that line
1. (Optional) If your Python script takes in arguments, you might have to fiddle with `wrapper_template.sh` a little bit. 
1. Run the `create_and_rush.sh` with the name (without extension) of the Python file as an argument. It only takes a single argument and uses it to create shell script and runs it 


```shell
$ bash create_and_run.sh test # to run test.py
```


_Assumptions:_
- This assumes that the command `python` runs your desired type of Python. If your environment uses a different name, then make sure to adjust `wrapper_template.sh`
- This assumes that your Python script `*.py` is in the same directory as the other 4 scripts. Otherwise, you might have to adjust how it names its files and what each of the files call. 
    - `create_and_run.sh`
    - `template.sh`
    - `test.sh`
    - `wrapper_template.sh`

## Additional Optional Steps
You may also write a function and write it on your `~/.bashrc` (or `~/.zshrc`, or whatever shell you use) file 

```shell
# ~/.bashrc
function create_and_run(){
    bash template.sh $1 > $1.sh
    sbatch $1.sh
}
```

And (after sourcing your `~/.bashrc`), you may simply run
```shell
$ create_and_run test
```

## TODO 
[ ] What if the Python script takes in arguments?
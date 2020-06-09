# Version 2

## Arguments



| Full Flag   | Short Flag | Description                                                  |
| ----------- | ---------- | ------------------------------------------------------------ |
| --comment   | -c         | Description of the job as a comment<br />E.g. `--comment "My fifth experiment"`<br />Default: It's corresponding name |
| --copy-data |            | Option to copy a dataset to a `/tmp` folder<br />E.g. `--copy-data ~/data/LibriSpeech`<br />Default: disabled |
| --dir       | -d         | Target directory to temporarily store experiments and then from where<br />to fetch the results. <br />E.g. `--dir /tmp/user/lstm_experiment`<br />Default `/tmp/nshu/tests` |
| --email     |            | Email to receive alerts<br />E.g. `--email linus@linux.org`<br />Default: `nshu@emory.edu` |
| --env       | -e         | Path to Python virtual environment<br />E.g. `--env ~/envs/myenv`<br />Default: `/home/nshu/envs/speech` |
| **--file**  | **-f**     | **(Required) Path to the Python file**<br />E.g. `--file lstm.py` |
| --mail-type |            | Type of alerts to receive from from Slurm server<br />Please see the [Slurm docs](https://slurm.schedmd.com/sbatch.html)<br />E.g. `--mail-type END `<br />Default: `ALL` |
| --time      | -t         | Desired maximum time for the job to run<br />E.g. `--time 2-11:57:46`<br />Default: `5-23:0:0` |
| --verbose   | -v         | If this flag is used, then it will log the `wrapper.sh` script and the corresponding<br />sbatch shell script. Default: disabled. |



## Description Step-by-Step

This is a description of what will happen to the with this script in order. Let us call the current working directory `$cwd`, and that the passed `--dir` argument is at `/tmp/nshu/tests` in the computational node.

1. Check whether there it received a file or not with the `-f / --file` option. If so, it will have `${name}` only the name of the file, without the extension. E.g. "test" for "example.py"

2. Create a directory `results` at `$cwd/results`

   ```power
   user@bmi: cwd $ ls
   cwd/
   	> create_and_run.sh
   	> example.py
   	> results/
   ```

   

3. Create a `wrapper.sh` script at `$cwd/wrapper.sh` which activates the given virtual environment prior to running the Python script

   ```shell
   # wrapper.sh
   source ${env}/bin/activate
   ```

   ```power
   user@bmi: cwd $ ls
   cwd/
   	> create_and_run.sh
   	> example.py
   	> results/
   	> wrapper.sh
   ```

4. Create a `${name}.sh` script at `$cwd/${name}.sh`. More on this will be described later

   ```power
   user@bmi: cwd $ ls
   cwd/
   	> create_and_run.sh
   	> example.py
   	> example.sh
   	> results/
   	> wrapper.sh
   ```

   

5. (Optional) If the `--verbose` flag was activated, it will show the created `wrapper.sh` and `${name}.sh` scripts just created.

6. Deploy the `${name}.sh` script via sbatch

   ```shell
   # example.sh
   sbatch ${name}.sh
   ```

   Now we will see what happens inside `${name}.sh` (E.g. `example.sh`). 

7. First establish all of the passed parameters for the SBATCH parameters.

   ```shell
   #SBATCH -J ${name}
   #SBATCH --comment "${comment}"
   #SBATCH --time ${time}
   #SBATCH --output results/%A_$name.out
   #SBATCH --error results/%A_$name.err
   
   #SBATCH --mem 6G
   #SBATCH --nodes 1
   
   #SBATCH --mail-user=${email}
   #SBATCH --mail-type=${mailtype}
   ```

8. Create the directory `${dir}` = `/tmp/user/tests`, with all of its parents

   ```powershell
   /tmp
   	> nshu
   		> tests
   ```

   

9. Create the `data` folder at `/tmp/nshu/data`, with all of its parents. (If you wish to change, it should be directly after `mkdir -p ${dir}`)

   ```powershell
   /tmp/
   	> nshu/
   		> data/
   		> tests
   ```

10. If `--copy-data` was passed, it will copy the dataset from `/home/nshu/data/${data}`. (If you wish to change, look at the while case loop for `--copy-data`, where it defines the `cp_data` variable)

    ```powershell
    user@bmi: cwd $ tree /tmp
    /tmp/
    	> nshu/
    		> data/SomeDataset
    		> tests
    ```

11. Copy the `${file}` to `${dir}/`. So, if you passed `-f example.py`, it will copy it from `$cwd/example.py` to `/tmp/user/tests/example.py`

    ```powershell
    user@bmi: cwd $ tree /tmp
    /tmp/
    	> nshu/
    		> data/...
    		> tests
    			> example.py
    ```

12. Copy the `wrapper.sh` to `${dir}/`.

    ```powershell
    user@bmi: cwd $ tree /tmp
    /tmp/
    	> nshu/
    		> data/...
    		> tests
    			> example.py
    			> wrapper.sh
    ```

13. Change the location to `${dir}`

    ```powershell
    user@bmi: cwd $ cd $dir
    user@bmi: /tmp/nshu/tests $ 
    ```

14. (NS) Copy the git repos for the packages to be accessed by your code. You may wish to tweak with this if you have specific dependencies or modules that you've built yourself. E.g. 

    ```powershell
    user@bmi: /tmp/nshu/tests $ tree /tmp
    /tmp/
    	> nshu/
    		> data/...
    		> dataset_loaders/
    			> audioloaders/
    		> mci/
    			> net
    		> tests
    			> example.py
    			> wrapper.sh
    ```

15. (NS) Create symbolic links 

    ```powershell
    user@bmi: /tmp/nshu/tests $ tree /tmp
    /tmp/
    	> nshu/
    		> data/...
    		> dataset_loaders/
    			> audioloaders/
    		> mci/
    			> net
    		> tests
    			> audioloaders @ ---> /tmp/dataset_loaders/audioloaders
    			> data         @ ---> /tmp/nshu/data
    			> net          @ ---> /tmp/nshu/mci/net
    			> example.py
    			> wrapper.sh
    ```

    

16. Under a `rh-python36` environment, run the wrapper script

    ```powershe
    user@bmi: /tmp/nshu/tests $ scl enable rh-python36 "bash wrapper.sh ${file}"
    ```

17. Inside the `wrapper.sh` script, activate the given environment

18. Run the `${file}` Python script.

19. Once the script is done, copy this whole directory to `$cwd/results` directory 

    ```shell
    user@bmi: /tmp/nshu/tests $ cp -r $dir $cwd/results
    user@bmi: /tmp/nshu/tests $ cd $cwd/results; tree
    cwd/
    	> create_and_run.sh
    	> example.py
    	> example.sh
    	> results/
    		> tests
    			> audioloaders @ ---> ?
    			> data         @ ---> ?
    			> net          @ ---> ?
    			> example.py
    			> wrapper.sh
    			...
    	> wrapper.sh
    ```

    


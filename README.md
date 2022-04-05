# scp-polyfill
Polyfill for SCP (now on his way to deprecation) using sftp and rsync

## Features
- Full coverage for both `sftp` and `rsync` commands. (see the corresponding voice in [the docs](#default-program))

## SCP supported options
As of _April 05 2022_ the supported options are:
<!-- https://www.tablesgenerator.com/markdown_tables -->
|          Parameter          	|    Type    	|                                           Description                                           	|
|:---------------------------:	|:----------:	|:-----------------------------------------------------------------------------------------------:	|
| **`-C`**                    	| _OPTIONAL_ 	| Enables compression                                                                             	|
| **`-o`**                    	| _OPTIONAL_ 	| Can be used to pass options to ssh in the format used in ssh_config(5).                         	|
| **`-q` (or `--quiet`)**     	| _OPTIONAL_ 	| Quiet mode: disables the progress meter as well as warning and diagnostic messages from ssh(1). 	|
| **`-r` (or `--recursive`)** 	| _OPTIONAL_ 	| Recursively copy entire directories.                                                            	|
| **`-v` (or `--verbose`)**   	| _OPTIONAL_ 	| Verbose mode.                                                                                   	|

## How to use
#### 1. Source it
```console
source src/scp.sh
```
> **WARNING!**
> 
> Note that this way you will temporarily overwrite the "legacy" `scp`!  
> Restarting the shell will make things go back to normal.


#### 2. Use scp like you would normally
##### 2.1) Basic use
Here it is a simple everyday use-case:
- **Command:**
  ```console
  scp test_scp.txt myuser@127.0.0.1:/tmp
  ```
- **Output:**
  ```
  myuser@127.0.0.1's password:
  sftp> put test_scp.txt
  ```
  
##### 2.1) Advanced use
In the following more advanced example all the supported options will be used:
- I have a directory with two files inside:
  ```console
  $ ls -l test_dir/
  totale 0
  -rw-rw-rw-+ 1 Luca Salvarani NESSUNO 0  5 apr 03.29 test_file.txt
  -rw-rw-rw-+ 1 Luca Salvarani NESSUNO 0  5 apr 03.29 test_file2.txt
  ```
- Now i upload the whole folder into the remote `/tmp`:
  ```console
  $ scp -r -C -q -o UserKnownHostsFile=/dev/null -o "LogLevel=QUIET" -o StrictHostKeyChecking=NO test_dir myuser@127.0.0.1:/tmp
  myuser@127.0.0.1's password:
  sftp> put test_dir
  Entering test_dir/
  ```
- The directory has been successfully uploaded:
  ```console
  $ ssh myuser@127.0.0.1 "ls -l /tmp/test_dir"
  myuser@127.0.0.1's password:
  total 0
  -rw-r--r--. 1 root root 0 Apr  5 03:29 test_file2.txt
  -rw-r--r--. 1 root root 0 Apr  5 03:29 test_file.txt
  ```

## Docs

### Default program
- By default the polyfill will target `sftp` if installed, otherwise will use `rsync`.
- If neither of the two is present, then an error will be shown and the program will end.
- The use of a specific program can be made by using the special flag `--set-command-preference=COMMAND_NAME`. Note that if it is not one of the supported commands the program will end with an error.

# scp-polyfill
Polyfill for SCP (now on his way to deprecation) using sftp and rsync


```console
Luca Salvarani@LAPTOP-3JJIKG4C ~
$ source src/scp.sh
```

Command:
```console
scp -o StrictHostKeyChecking=NO test_scp.txt myuser@127.0.0.1:/tmp
```
Output:
```
myuser@127.0.0.1's password:
sftp> put test_scp.txt
```

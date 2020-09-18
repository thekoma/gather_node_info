# gather_node_info
Utilizzo:
effettuare il login verso il cluster da cui si vuole estrarre il conteggio:
```bash
oc login CLUSTER:8443 --username=MYUSER --password=MIPASS
```


Eseguire lo script:
```bash
./extract.sh
```

Output di esempio:
```log
./extract.sh                                       
Output verrà salvato in /tmp/tmp.qdnzXSXwAW/out.log
Sei collegato come acervesa@redhat.com al server https://api.lab01.gpslab.club:6443
[master] CPU:12 RAM:46Gi
[worker] CPU:48 RAM:188Gi
```


# kubectl debug

устанавливаем агента в кластер

```
kubectl apply -f ../kubernetes-intro/web-pod.yaml
```

устанавливаем pod из первого ДЗ

```
kubectl apply -f ../kubernetes-intro/web-pod.yaml
```

используем debug
```
kubectl debug web
```

запускаем внутри контейнера strace
```
bash-5.0# strace -c -p1
strace: test_ptrace_get_syscall_info: PTRACE_TRACEME: Operation not permitted
strace: attach: ptrace(PTRACE_ATTACH, 1): Operation not permitted
```

strace не работает... пробуем починить. 
```
~ gcloud compute ssh gke-gke-test-default-node-pool-9ad8cf92-5r9s 
[sergey@gke-gke-test-default-node-pool-9ad8cf92-5r9s ~]$ sudo -i
[root@gke-gke-test-default-node-pool-9ad8cf92-5r9s  ~]# docker ps |grep netshoot
2b9d7cd9f755        nicolaka/netshoot:latest                   "bash"                   9 minutes ago       Up 9 minutes                            confident_bose
```

Посмотрим какие имеются Capability
```
[root@gke-gke-test-default-node-pool-9ad8cf92-5r9s  ~]# docker inspect 2b9d7cd9f755 |grep Cap
            "CapAdd": null,
            "CapDrop": null,
            "Capabilities": null,
```

Перезапуск контейнера с нужными Capability не помогает, так при запуске 'kubectl debug web ' пулится всегда новый image контейнера 'netshoot'.

```
docker run -it --cap-add SYS_PTRACE --cap-add SYS_ADMIN nicolaka/netshoot:latest
```
Pod c debug-agent cкачиваеи образ netshoot и не устанавливает нужные Capability. Для начала надо посмотреть есть ли другая версия debug-agent, где данная проблема могла быть устранена. Попробуем сначала использовать последнюю версию образа предлагаемую разработчиком. Изменим манифест debug agent, удалим старую версию из DaemonSet и применим новый. 

```
containers:
  - image: aylei/debug-agent:latest
```
```
kubectl delete ds debug-agent
kubectl apply -f strace/agent_daemonset.yml
```
Снова попробуем запустить strace в debug поде
```
bash-5.0# ps aux
PID   USER     TIME  COMMAND
    1 1001      0:00 /bin/sh -c python3 -m http.server 8000 --directory /app
    6 1001      0:02 python3 -m http.server 8000 --directory /app
 1075 root      0:00 bash
 1163 root      0:00 ps aux
bash-5.0# strace -p 6 -c
strace: Process 6 attached
^Cstrace: Process 6 detached
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 65.44    0.000640           8        76           poll
 28.32    0.000277          19        14           futex
  2.97    0.000029           4         7           clone
  2.56    0.000025           3         7           accept4
  0.72    0.000007           7         1           restart_syscall
------ ----------- ----------- --------- --------- ----------------
100.00    0.000978                   105           total

bash-5.0#
```
Все работает!

---

# iptables-tailer

Применяем манифесты

```
kubectl apply -f kit/deploy/crd.yaml
kubectl apply -f kit/deploy/rbac.yaml
kubectl apply -f kit/deploy/operator.yaml
kubectl apply -f kit/deploy/cr.yaml
```

проверяем

```
➜  kubernetes-debug git:(kubernetes-debug) ✗ kubectl describe netperf.app.example.com/example 
Name:         example
Namespace:    default
Labels:       <none>
Annotations:  <none>
API Version:  app.example.com/v1alpha1
Kind:         Netperf
Metadata:
  Creation Timestamp:  2020-09-25T03:26:01Z
  Generation:          4
  Resource Version:    31572
  Self Link:           /apis/app.example.com/v1alpha1/namespaces/default/netperfs/example
  UID:                 b9b5d0e0-4eb5-48fe-80af-9a2244fa839b
Spec:
  Client Node:  
  Server Node:  
Status:
  Client Pod:          netperf-client-9a2244fa839b
  Server Pod:          netperf-server-9a2244fa839b
  Speed Bits Per Sec:  7063.18
  Status:              Done
Events:                <none>
```

Применяем сетевую политику calico

```
kubectl apply -f kit/netperf-calico-policy.yaml
```

Запускаем тест повторно
```
kubectl delete -f kit/deploy/cr.yaml
kubectl apply -f kit/deploy/cr.yaml
```

проверяем

```
➜  kubernetes-debug git:(kubernetes-debug) ✗ kubectl describe netperf.app.example.com/example 
Name:         example
Namespace:    default
Labels:       <none>
Annotations:  <none>
API Version:  app.example.com/v1alpha1
Kind:         Netperf
Metadata:
  Creation Timestamp:  2020-09-25T03:36:33Z
  Generation:          3
  Resource Version:    35429
  Self Link:           /apis/app.example.com/v1alpha1/namespaces/default/netperfs/example
  UID:                 74d6d31d-cf31-4ef0-9f5e-86214736be86
Spec:
  Client Node:  
  Server Node:  
Status:
  Client Pod:          netperf-client-86214736be86
  Server Pod:          netperf-server-86214736be86
  Speed Bits Per Sec:  0
  Status:              Started test
Events:                <none>
```
видим, что тест висит в состоянии Started. Подключаемся к ноде c клиентом по ssh

```
root@gke-gke-test-default-node-pool-9ad8cf92-dnl5:~# iptables --list -nv | grep DROP
Chain FORWARD (policy DROP 0 packets, 0 bytes)
...
33  1980 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* cali:He8TRqGPuUw3VGwk */
...

root@gke-gke-test-default-node-pool-9ad8cf92-dnl5:~# iptables --list -nv | grep LOG 
    0     0 LOG        all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* cali:XWC9Bycp2Xf7yVk1 */ LOG flags 0 level 5 prefix "calico-packet: "
   34  2040 LOG        all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* cali:B30DykF1ntLW86eD */ LOG flags 0 level 5 prefix "calico-packet: "

root@gke-gke-test-default-node-pool-9ad8cf92-dnl5:~# journalctl -k | grep calico
Sep 25 03:36:35 gke-gke-test-default-node-pool-9ad8cf92-dnl5 kernel: calico-packet: IN=calibb6007ff7fc OUT=eth0 MAC=ee:ee:ee:ee:ee:ee:9a:67:5e:e2:62:83:08:00 SRC=10.44.2.4 DST=10.44.0.6 LEN=60 TOS=0x00 PREC=0x00 TTL=63 ID=12442 DF PROTO=TCP SPT=51813 DPT=12865 WINDOW=42600 RES=0x00 SYN URGP=0 
...
```
iptables-tailer

```
kubectl apply -f kit/iptables-tailer.yaml
kubectl delete -f kit/deploy/cr.yaml
kubectl apply -f kit/deploy/cr.yaml
```

```
kubectl get events -A
```
```
...
kube-system   38s         Warning   FailedCreate        daemonset/kube-iptables-tailer           Error creating: pods "kube-iptables-tailer-" is forbidden: error looking up service account kube-system/kube-iptables-tailer: serviceaccount "kube-iptables-tailer" not found
```

Нужен service account
```
kubectl apply -f kit/kit-serviceaccount.yaml
kubectl apply -f kit/kit-clusterrole.yaml
kubectl apply -f kit/kit-clusterrolebinding.yaml
kubectl delete -f kit/iptables-tailer.yaml
kubectl apply -f kit/iptables-tailer.yaml
```
```
➜  kubernetes-debug git:(kubernetes-debug) ✗ kubectl get ds -n kube-system | grep kube-iptables-tailer
kube-iptables-tailer       4         4         4       4            4           <none>             77s
```

Теперь видим
```
kubectl describe pod --selector=app=netperf-operator
```
```
...
Events:
  Type     Reason      Age    From                                                   Message
  ----     ------      ----   ----                                                   -------
  Normal   Scheduled   7m     default-scheduler                                      Successfully assigned default/netperf-server-ef3dbc68076e to gke-gke-test-default-node-pool-9ad8cf92-dnl5
  Normal   Pulled      7m     kubelet, gke-gke-test-default-node-pool-9ad8cf92-dnl5  Container image "tailoredcloud/netperf:v2.7" already present on machine
  Normal   Created     6m59s  kubelet, gke-gke-test-default-node-pool-9ad8cf92-dnl5  Created container netperf-server-ef3dbc68076e
  Normal   Started     6m59s  kubelet, gke-gke-test-default-node-pool-9ad8cf92-dnl5  Started container netperf-server-ef3dbc68076e
  Warning  PacketDrop  2m24s  kube-iptables-tailer                                   Packet dropped when receiving traffic from netperf-client-ef3dbc68076e (10.44.0.7)
  Warning  PacketDrop  78s    kube-iptables-tailer                                   Packet dropped when receiving traffic from netperf-client-ef3dbc68076e (10.44.0.7)
```

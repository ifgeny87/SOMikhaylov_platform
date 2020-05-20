# Kubernetes controllers. ReplicaSet, Deployment, DaemonSet

## ReplicaSet

```
kubectl apply -f frontend-replicaset.yaml
```

```
kubectl apply -f paymentservice-replicaset.yaml
```

> ReplicaSet не проверяет соответствие pod-ов шаблону, контроллер следит только за количеством реплик

### Полезные команды

проверка образа указанного в шаблоне (в примере paymentservice)

```
kubectl get replicaset paymentservice -o=jsonpath='{.spec.template.spec.containers[0].image}'
```

проверка образа запущенного в Pod (в примере paymentservice)
```
kubectl get pods -l app=paymentservice -o=jsonpath='{.items[0:3].spec.containers[0].image}'
``` 

--- 

## Deployment

```
kubectl apply -f paymentservice-deployment.yaml
```

### Полезные команды

история версий Deployment (в примере paymentservice)
```
kubectl rollout history deployment paymentservice
```
откат к первой версии (в примере paymentservice)
```
kubectl rollout undo deployment paymentservice --to-revision=1 | kubectl get rs -lapp=paymentservice -w
```
---
## Deployment (*)

blue-green deployment
```
kubectl apply -f paymentservice-deployment-bg.yaml
```
ReverseRollingUpdate
```
kubectl apply -f paymentservice-deployment-reverse.yaml
```

## Deployment + Probes

```
kubectl apply -f frontend-deployment.yaml
```

### Полезные команды

отслеживать статус выполнения
```
kubectl rollout status deployment/frontend
```

---

## DaemonSet


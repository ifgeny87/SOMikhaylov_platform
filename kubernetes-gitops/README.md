# **Microservices-demo**
- подготовлен репозиторий - https://gitlab.com/SOMikhaylov/microservices-demo
- helm чарты добавлены в `deploy/charts `
- pipeline сборки образов и push в dockerhub описан в `.gitlab-ci.yml` (задание со *)

---

# **Подготовка Kubernetes кластера**

- Кластер разворачиваtnся после запуска pipeline в GitLab - https://gitlab.com/SOMikhaylov/terraform-gke

---

# **GitOps**

Flux
```
kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/master/deploy/crds.yaml
helm repo add fluxcd https://charts.fluxcd.io
kubectl create namespace flux
helm upgrade --install flux fluxcd/flux -f flux.values.yaml --namespace flux
```

Helm-operator
```
helm upgrade --install helm-operator fluxcd/helm-operator -f helm-operator.values.yaml --namespace flux
```

получаем ssh-key и добавляем в gitlab
```
fluxctl identity --k8s-fwd-ns flux
```

проверка
```
kubectl logs -n flux flux-5fc454c847-fgmkr|grep "namespace/microservices-demo created"
...
ts=2020-09-14T03:29:58.842563798Z caller=sync.go:606 method=Sync cmd="kubectl apply -f -" took=734.595018ms err=null output="namespace/microservices-demo created\
...
```

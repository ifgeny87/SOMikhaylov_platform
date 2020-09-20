# **Microservices-demo**
- подготовлен репозиторий - https://gitlab.com/SOMikhaylov/microservices-demo
- helm чарты добавлены в `deploy/charts `
- pipeline сборки образов и push в dockerhub описан в `.gitlab-ci.yml`

---

# **Подготовка Kubernetes кластера**

- Кластер разворачивается после запуска pipeline в GitLab - https://gitlab.com/SOMikhaylov/terraform-gke

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
kubectl logs flux-5fc454c847-pc4g6 -n flux |grep "namespace/microservices-demo created" 
ts=2020-09-14T15:41:28.329297525Z caller=sync.go:606 method=Sync cmd="kubectl apply -f -" took=510.194876ms err=null output="namespace/microservices-demo created"
```

```
➜  microservices-demo git:(master) kubectl get helmrelease -n microservices-demo
NAME       RELEASE    PHASE       STATUS     MESSAGE                                                                       AGE
frontend   frontend   Succeeded   deployed   Release was successful for Helm release 'frontend' in 'microservices-demo'.   47s
```
```
➜  kubernetes-gitops git:(kubernetes-gitops) ✗ helm list -n microservices-demo
NAME            NAMESPACE               REVISION        UPDATED                                 STATUS          CHART           APP VERSION
frontend        microservices-demo      1               2020-09-20 13:50:24.457758147 +0000 UTC deployed        frontend-0.21.0 1.16.0
```

обновление docker образа

```
➜  frontend git:(master) helm history frontend -n microservices-demo
REVISION        UPDATED                         STATUS          CHART           APP VERSION     DESCRIPTION     
1               Sun Sep 20 13:50:24 2020        superseded      frontend-0.21.0 1.16.0          Install complete
2               Sun Sep 20 13:56:35 2020        deployed        frontend-0.21.0 1.16.0          Upgrade complete
```

обновление helm чарта (изменение имени deployment на forntend-hipster)

```
➜  kubernetes-gitops git:(kubernetes-gitops) ✗ kubectl logs helm-operator-6db458857f-lrtnc -n flux | grep frontend-hipster
ts=2020-09-20T14:03:39.201802204Z caller=helm.go:69 component=helm version=v3 info="Created a new Deployment called \"frontend-hipster\" in microservices-demo\n" targetNamespace=microservices-demo release=frontend
```

Добавление всех манифестов hipster-shop
```
➜  SOMikhaylov_platform git:(kubernetes-gitops) ✗ kubectl get helmrelease -n microservices-demo
NAME                      RELEASE                   PHASE       STATUS     MESSAGE                                                                                      AGE
adservice                 adservice                 Succeeded   deployed   Release was successful for Helm release 'adservice' in 'microservices-demo'.                 2m7s
cartservice               cartservice               Succeeded   deployed   Release was successful for Helm release 'cartservice' in 'microservices-demo'.               2m7s
checkoutservice           checkoutservice           Succeeded   deployed   Release was successful for Helm release 'checkoutservice' in 'microservices-demo'.           2m7s
currencyservice           currencyservice           Succeeded   deployed   Release was successful for Helm release 'currencyservice' in 'microservices-demo'.           2m7s
emailservice              emailservice              Succeeded   deployed   Release was successful for Helm release 'emailservice' in 'microservices-demo'.              2m7s
frontend                  frontend                  Succeeded   deployed   Release was successful for Helm release 'frontend' in 'microservices-demo'.                  22m
grafana-load-dashboards   grafana-load-dashboards   Succeeded   deployed   Release was successful for Helm release 'grafana-load-dashboards' in 'microservices-demo'.   2m7s
loadgenerator             loadgenerator             Succeeded   deployed   Release was successful for Helm release 'loadgenerator' in 'microservices-demo'.             2m7s
paymentservice            paymentservice            Succeeded   deployed   Release was successful for Helm release 'paymentservice' in 'microservices-demo'.            2m7s
productcatalogservice     productcatalogservice     Succeeded   deployed   Release was successful for Helm release 'productcatalogservice' in 'microservices-demo'.     2m7s
recommendationservice     recommendationservice     Succeeded   deployed   Release was successful for Helm release 'recommendationservice' in 'microservices-demo'.     2m7s
shippingservice           shippingservice           Succeeded   deployed   Release was successful for Helm release 'shippingservice' in 'microservices-demo'.           2m7s
```

---

# **Canary deployments c Flagger и Istio**

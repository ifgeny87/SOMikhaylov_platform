# Kubernetes-intro

сборка образа

```
cd web/
docker build -t somikhaylov/web:1.0 .
```
запуск

```
docker run --rm --name web -d -p 8000:8000 somikhaylov/web:1.0
```

применение манифеста

```
kubectl apply -f web-pod.yaml
```

---

## Задание со *

ad-hoc генерация манифеста

```
kubectl run frontend --image somikhaylov/hipster-frontend:0.1 --restart=Never --dry-run=client -o yaml > frontend-pod.yaml
```
ошибка после применения манифеста

```
panic: environment variable "PRODUCT_CATALOG_SERVICE_ADDR" not set
```

добавлены необходимые переменные в манифест

```
kubectl apply -f frontend-pod-healthy.yaml
```

---
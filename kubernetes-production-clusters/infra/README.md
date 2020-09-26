# terraform-vm google cloud

preconfigure
```
gcloud auth application-default login
```

create and edit terraform.tfvars
```
cp terraform.tfvars.example terraform.tfvars
```
---

run 

```
terraform init
terraform apply -auto-approve
```

---
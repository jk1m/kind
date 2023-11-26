# Terraform

Provision kind cluster using Terraform

```bash
terraform init
terraform apply -auto-approve

./finish-setup.sh

# there's a delay when deploying the nginx ingress.
# you'll need to deploy the ingress-example.yml manually
# after it is up and running

kubectl apply -f $HOME/configs/ingress-example.yml
```

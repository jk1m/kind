# kind
Kubernetes in Docker (KinD) for local development

Detailed information on KinD can be found [here](https://kind.sigs.k8s.io/).

## What's installed in the Dockerfile
Specific versions, if any, can be found by inspecting the Dockerfile.

KinD\
kubectl\
Helm\
Terraform\
deck\
yq\
curl\
bash\
jq\
httpie\
gettext\
coreutils\
vim\

## Build it
```bash
docker build --no-cache -t kind .
```
## Run it
```bash
docker run --privileged -d -p 80:80 -p 443:443 --name kind kind:latest
```
## Exec into it
```bash
docker exec -it kind bash
```


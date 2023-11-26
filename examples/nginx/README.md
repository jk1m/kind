# Nginx example

Nginx is running as non-root and on port 8080.

`volume` and `volumeMounts` have been added to the helm values file as well as additional
security guardrails, port changes, etc.

```bash
# build image
docker build --no-cache -t localhost:5001/web:1.0.0 .

# push image to local registry
docker push localhost:5001/web:1.0.0

# deploy via helm
helm upgrade --install web web/

# add service to $HOME/configs/ingress-example.yml

# apply $HOME/configs/ingress-example.yml

# navigate to localhost/web in your browser
```

# KinD

## Provisioning
After exec'ing into the container, run the script `start-kind.sh`:
```bash
./start-kind.sh
```

The script above will provision the following:
- a local registry
- a single node k8s cluster
- MetalLB

After the script has finished, view the cluster by running:
```bash
kubectl get all -A
``` 

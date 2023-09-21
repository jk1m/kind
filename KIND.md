# KinD

## Provisioning
After exec'ing into the container, run the script `start-kind.sh`:
```bash
./start-kind.sh
```

The script above will provision the following:
- a local registry
- a single node k8s cluster named `kind`
- MetalLB

After the script has finished, view the cluster by running:
```bash
kubectl get all -A
``` 

## Tear down
To tear everything down:
- run `./delete.sh`
- or `kind delete cluster`

Type `exit` to get out of the container.

Once outside the container, run:
```bash
# stop the container
docker stop kind

# delete the stopped container
docker rm kind

# delete the volume left behind
# note: this will also delete any dangling volumes you may have
docker volume rm $(docker volume ls -qf "dangling=true")

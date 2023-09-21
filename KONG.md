# Kong

## Provisioning
After exec'ing into the container, run the script `start-kong.sh`:
```bash
./start-kong.sh
```

The script above will provision the following:
- a local registry
- a single node k8s cluster named `kind`
- MetalLB
- Kong gateway

This will take a minute or two. Wait until all pods are up and migrations have completed before playing around with Kong.

> **Note**
> If you're actively watching the pods, you may notice one or two might go into `CrashLoopBackOff`. Don't worry, it'll fix itself.

### Admin API
The admin api is accessible within the container.

```bash
http --verify=no https://kong.127-0-0-1.nip.io/api/services
# or
curl -sk https://kong.127-0-0-1.nip.io/api/services | jq
```
It is also accessible from your browser at `https://kong.127-0-0-1.nip.io/api/services`.

> **Note**
> "You will receive a 'Your Connection is not Private' warning message due to using selfsigned certs. If you are using Chrome there may not be an “Accept risk and continue” option, to continue type `thisisunsafe` while the tab is in focus to continue."

### Kong manager
The Kong manager can be accessible outside the container. In your browser, navigate to `https://kong.127-0-0-1.nip.io/`.

## Provision sample service, routes, etc
> **Note**
> Because `deck` is hitting Kong locally and selfsigned certs are in use, additional flags have to be passed to it. To make things easier, an alias has been created pointing `deck` to `deck --kong-addr https://kong.127-0-0-1.nip.io/api --tls-skip-verify`.

> **Note**
> `flights-oas.yml` has been taken from [Kong's Github](https://github.com/Kong/KongAir/blob/main/flight-data/flights/openapi.yaml) repo and stored here for safe keeping and version control.

> **Note**
> The `deck` commands below that use the `-o` flag store the output into different files for your viewing rather than overwriting anything.

Convert `flights-oas.yml` to Kong's config:
```bash
deck file openapi2kong -s configs/flights-oas.yml -o configs/flights.yml
```

Add tags:
```bash
deck file add-tags -s configs/flights.yml "flights-service" -o configs/all.yml 
```

Sync it:
```bash
deck sync --select-tag "flights-service" -s configs/all.yml
```

In the container, hit the `flights` endpoint.
```bash
http --verify=no :/flights
# or
curl -s localhost/flights | jq
```

Outside the container, in your browser, navigate to `http://localhost/flights`.

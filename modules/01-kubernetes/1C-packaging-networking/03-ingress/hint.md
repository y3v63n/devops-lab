# Hints — Exercise 1C-03: Ingress

## Setup Hints

<details>
<summary>Hint: minikube ingress addon is not ready</summary>

After enabling, wait for the controller pod to be ready:
```bash
minikube addons enable ingress
kubectl get pods -n ingress-nginx
# Wait until controller pod is Running
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```
</details>

---

## Task 1 Hints

<details>
<summary>Hint 1: Alternative simpler deployments (if http-echo image isn't available)</summary>

Use nginx with a ConfigMap instead:
```bash
kubectl create deployment app-v1 --image=nginx --replicas=1
kubectl create deployment app-v2 --image=nginx --replicas=1
```
The routing test won't show different content, but Ingress routing will still work.
</details>

<details>
<summary>Hint 2: hashicorp/http-echo arguments</summary>

The `--` after the image separates kubectl args from container args:
```bash
kubectl create deployment app-v1 --image=hashicorp/http-echo \
  -- /http-echo -text="Hello from V1" -listen=:5678
```
</details>

---

## Task 2 Hints

<details>
<summary>Hint 1: Exposing the service on port 80</summary>

```bash
kubectl expose deployment app-v1 --port=80 --target-port=5678
kubectl expose deployment app-v2 --port=80 --target-port=5678
```
`--port` is what the service listens on; `--target-port` is what the container listens on (5678 for http-echo).
</details>

---

## Task 3 Hints

<details>
<summary>Hint 1: ingressClassName is required on newer clusters</summary>

Without `spec.ingressClassName: nginx`, minikube may not associate your Ingress with the NGINX controller. Always include it.
</details>

<details>
<summary>Hint 2: rewrite-target annotation</summary>

The annotation `nginx.ingress.kubernetes.io/rewrite-target: /` strips the path prefix before forwarding. Without it, your app receives `/v1/...` instead of `/`. http-echo doesn't care, but real apps often do.
</details>

---

## Task 4 Hints

<details>
<summary>Hint 1: Getting minikube IP</summary>

```bash
minikube ip
# Example output: 192.168.49.2
curl http://192.168.49.2/v1
```
</details>

<details>
<summary>Hint 2: curl returns 404 or connection refused</summary>

Check that:
1. Ingress controller is running: `kubectl get pods -n ingress-nginx`
2. Ingress ADDRESS is assigned: `kubectl get ingress app-ingress` (ADDRESS column should show the minikube IP)
3. Services are running: `kubectl get svc app-v1 app-v2`

It can take 30-60 seconds after applying the Ingress for the controller to configure routing.
</details>

<details>
<summary>Hint 3: Using tunnel instead of minikube ip (Docker driver)</summary>

If using the Docker driver, `minikube ip` may not work directly. Try:
```bash
minikube tunnel &
curl http://localhost/v1
```
</details>

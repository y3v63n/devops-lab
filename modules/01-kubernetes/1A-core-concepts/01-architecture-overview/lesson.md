# Exercise 1A-01: Kubernetes Architecture Overview

## Theory

### Control Plane Components

The Kubernetes control plane is the brain of the cluster, responsible for making global decisions about the cluster (scheduling, detecting and responding to events). It consists of four core components:

**API Server (kube-apiserver)** is the front-end for the Kubernetes control plane. All communication in the cluster — from kubectl commands, internal components, and external clients — flows through the API server. It validates and processes REST requests, updates the corresponding objects in etcd, and serves as the gateway for all cluster operations. When you run `kubectl get pods`, your request hits the API server first.

**etcd** is a distributed, consistent key-value store used as Kubernetes' backing store for all cluster data. Every object in Kubernetes — Pods, Services, Deployments, ConfigMaps — is persisted as a key-value entry in etcd. etcd uses the Raft consensus algorithm to ensure data consistency across multiple replicas. If etcd becomes unavailable, the cluster can no longer store or retrieve state, meaning no new resources can be created, updated, or deleted (though existing workloads continue running on worker nodes until something changes).

**Scheduler (kube-scheduler)** watches for newly created Pods that have no Node assigned, and selects a Node for them to run on. Scheduling decisions account for resource requirements, hardware/software/policy constraints, affinity and anti-affinity rules, data locality, and inter-workload interference.

**Controller Manager (kube-controller-manager)** runs controller loops that watch the state of the cluster and make changes to move the current state toward the desired state. Examples include the Node controller (notices when nodes go down), the Deployment controller (maintains the correct number of Pod replicas), and the Service Account controller (creates default accounts in new namespaces).

### Worker Node Components

Worker nodes are the machines that run your containerized applications. Each worker node contains three essential components:

**kubelet** is an agent that runs on each node. It receives PodSpecs (descriptions of what should run) from the API server and ensures the containers described in those PodSpecs are running and healthy. The kubelet does not manage containers that were not created by Kubernetes.

**kube-proxy** maintains network rules on nodes. These network rules allow network communication to your Pods from network sessions inside or outside of your cluster. kube-proxy uses the operating system packet filtering layer (iptables/ipvs) if there is one and it's available; otherwise, kube-proxy forwards the traffic itself.

**Container Runtime** is the software responsible for running containers. Kubernetes supports container runtimes that implement the Container Runtime Interface (CRI) — most commonly containerd or CRI-O. The container runtime pulls images from a registry, unpacks them, and runs containers.

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        CONTROL PLANE                            │
│                                                                 │
│  ┌──────────────┐   ┌──────┐   ┌───────────┐   ┌───────────┐  │
│  │  API Server  │   │ etcd │   │ Scheduler │   │Controller │  │
│  │(kube-apisvr) │◄──│      │   │           │   │ Manager   │  │
│  └──────┬───────┘   └──────┘   └─────┬─────┘   └─────┬─────┘  │
│         │                            │               │         │
└─────────┼────────────────────────────┼───────────────┼─────────┘
          │ (watches/updates)           │               │
          ▼                            ▼               ▼
┌─────────────────────┐   ┌─────────────────────────────────────┐
│    WORKER NODE 1    │   │           WORKER NODE 2             │
│                     │   │                                     │
│  ┌───────────────┐  │   │  ┌───────────────┐                 │
│  │    kubelet    │  │   │  │    kubelet    │                 │
│  └───────────────┘  │   │  └───────────────┘                 │
│  ┌───────────────┐  │   │  ┌───────────────┐                 │
│  │  kube-proxy   │  │   │  │  kube-proxy   │                 │
│  └───────────────┘  │   │  └───────────────┘                 │
│  ┌───────────────┐  │   │  ┌───────────────┐                 │
│  │   Container   │  │   │  │   Container   │                 │
│  │   Runtime     │  │   │  │   Runtime     │                 │
│  └───────────────┘  │   │  └───────────────┘                 │
│  ┌──────┐ ┌──────┐  │   │  ┌──────┐ ┌──────┐ ┌──────┐       │
│  │ Pod  │ │ Pod  │  │   │  │ Pod  │ │ Pod  │ │ Pod  │       │
│  └──────┘ └──────┘  │   │  └──────┘ └──────┘ └──────┘       │
└─────────────────────┘   └─────────────────────────────────────┘
```

---

## Tasks

### Setup
```bash
mkdir -p /tmp/devops-lab/1A-01
```

### Task 1 — Inspect Cluster Info
```bash
kubectl cluster-info | tee /tmp/devops-lab/1A-01/cluster-info.txt
```

### Task 2 — List Nodes
```bash
kubectl get nodes -o wide | tee /tmp/devops-lab/1A-01/nodes.txt
```

### Task 3 — Inspect System Pods
```bash
kubectl get pods -n kube-system | tee /tmp/devops-lab/1A-01/system-pods.txt
```
Identify which pods correspond to which control plane components. Look for: `etcd-*`, `kube-apiserver-*`, `kube-scheduler-*`, `kube-controller-manager-*`, `coredns-*`, `kube-proxy-*`.

### Task 4 — Trace a Deployment Request
Write a plain-English explanation of every step that occurs internally when you run the command below. Your answer should reference each of the 7 components covered above.
```bash
kubectl create deployment nginx --image=nginx
```
Save your explanation:
```bash
cat > /tmp/devops-lab/1A-01/architecture.txt << 'EOF'
When I run `kubectl create deployment nginx --image=nginx`:

1. kubectl serialises the Deployment object and sends an HTTP POST to the API Server.
2. The API Server authenticates and authorises the request, then validates the object schema.
3. The API Server persists the new Deployment object to etcd.
4. The Deployment Controller (inside Controller Manager) detects the new Deployment via a watch on etcd, creates a ReplicaSet, which in turn creates Pod objects — all written back to etcd through the API Server.
5. The Scheduler detects unscheduled Pods via a watch, selects a suitable Node based on resource availability and constraints, and writes the node binding back to the API Server (etcd).
6. The kubelet on the chosen Node detects its new Pod assignment, instructs the Container Runtime (containerd/CRI-O) to pull the nginx image and start the container.
7. kube-proxy on each Node updates iptables/ipvs rules so the Pod is reachable within the cluster network.
EOF
```

---

## Interview Question

**"Explain etcd's role in Kubernetes. What happens if etcd becomes unavailable?"**

Think about:
- What data lives in etcd (all cluster state — objects, configs, secrets)
- Why consistency matters (Raft consensus, quorum)
- What keeps working if etcd goes down (running containers continue; kubelet works off local state)
- What stops working (no new Pods, no scaling, no config changes, kubectl commands fail)
- Production mitigation strategies (etcd clustering with 3 or 5 members, regular backups with `etcdctl snapshot save`)

---

## What Just Happened

When you ran `kubectl get pods -n kube-system` you saw the control plane "eating its own dog food" — the control plane components themselves run as Pods (in a kubeadm-bootstrapped cluster) inside the `kube-system` namespace. This means the very system that manages Pods is itself running as Pods, protected by static Pod manifests on the control plane node that the kubelet reads directly from disk — bypassing the API server — so they can start even before the cluster is fully up.

Every `kubectl` command you ran was an API call to the API server, which looked up data in etcd and returned it. You never talked to etcd directly — the API server is the sole gatekeeper.

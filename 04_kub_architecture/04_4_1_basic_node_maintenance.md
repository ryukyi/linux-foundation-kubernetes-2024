
1. Find the data directory of the etcd daemon. All of the settings for the pod can be found in the manifest

```bash
sudo grep data-dir /etc/kubernetes/manifests/etcd.yaml
```

2. Log into theetcdcontainer and look at the options etcdctl provides.  Use tab to complete the container name, which has the node name appended to it

```bash
kubectl -n kube-system exec -it etcd-<Tab> -- sh
```

3. health 

```bash
kubectl -n kube-system exec -it etcd-k8scp -- sh -c "ETCDCTL_API=3 \
ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt \
ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt \
ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key \
etcdctl endpoint health"
```

4. how many databases

```bash
kubectl -n kube-system exec -it etcd-k8scp -- sh -c "ETCDCTL_API=3 \
ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt \
ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt \
ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key \
etcdctl --endpoints=https://127.0.0.1:2379 member list -w table"
```

5. Take snapshot backups

```bash
kubectl -n kube-system exec -it etcd-k8scp -- sh -c "ETCDCTL_API=3 \
ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt \
ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt \
ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key \
etcdctl --endpoints=https://127.0.0.1:2379 snapshot save /var/lib/etcd/snapshot.db "
```

copy the scapshots with timestamps:

```bash
mkdir $HOME/backup
sudo cp /var/lib/etcd/snapshot.db $HOME/backup/snapshot.db-$(date +%m-%d-%y)
sudo cp /root/kubeadm-config.yaml $HOME/backup/
sudo cp -r /etc/kubernetes/pki/etcd $HOME/backup/
```

6. Upgrade cluster

```bash
# update and get latest kubernetes version
sudo apt update
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
    https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" \
    | sudo tee /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key \
    | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo apt-get update
# view available packages
sudo apt-cache madison kubeadm
sudo apt-mark unhold kubeadm
sudo apt-get install -y kubeadm=1.29.1-1.1
# prevent updates with other software
sudo apt-mark hold kubeadm
# verify version
sudo kubeadm version
# evict as many pods as possible
kubectl drain k8scp --ignore-daemonsets
sudo kubeadm upgrade plan
sudo kubeadm upgrade apply v1.29.1
kubectl get node
sudo apt-mark unhold kubelet kubectl
sudo apt-get install -y kubelet=1.29.1-1.1 kubectl=1.29.1-1.1
# add hold so the other updates don't update the kubernetes software
sudo apt-mark hold kubelet kubectl
sudo systemctl daemon-reload
sudo systemctl restart kubelet
# make cp available to scheduler
kubectl uncordon k8scp
# cp and workers should be ready
kubectl get node
# worker will still be version 1.28.1 - repeat steps above for worker
```

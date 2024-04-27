
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
etcdctl --endpoints=https://127.0.0.1:2379 member list"
```
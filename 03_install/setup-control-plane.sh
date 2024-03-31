#!/bin/bash

# dynamic api to retrieve GCP external IP
external_ip=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)

# Configure CONTROL PLANE
sudo hostnamectl set-hostname k8scp && echo $external_ip k8scp | sudo tee -a /etc/hosts

# Write kubeadm-config.yaml
cat <<EOF > $HOME/kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: 1.29.0
controlPlaneEndpoint: "k8scp:6443"
EOF

cd $HOME/
# configure .kube conf
mkdir -p $HOME/.kube
# intialise
sudo kubeadm init --config=$HOME/kubeadm-config.yaml --upload-certs | tee kubeadm-init.out
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
less $HOME/.kube/config


# Cilium is genereally installed using ”cilium install” or using ”helm install” commands.  
# We have generated thecilium-cni.yaml file using the below commands for your convenience.
# Note: You dont need to execute the com-mands in this box, they are just for reference.
#     helm repo add cilium https://helm.cilium.io/
#     helm repo update$ helm template cilium cilium/cilium --version 1.14.1 \
#     --namespace kube-system > cilium.yaml 
kubectl apply -f $HOME/cilium-cni.yaml

source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> $HOME/.bashrc

# Create keys for reuse on workers
sudo kubeadm token create

# Create and use a Discovery Token CA Cert Hash created from the cp to ensure
# the node joins the cluster in a securemanner. Run this on the cp node or 
# wherever you have a copy of the CA file. You will get a long string as output
openssl x509 -pubkey \
    -in /etc/kubernetes/pki/ca.crt | openssl rsa \
    -pubin -outform der 2>/dev/null | openssl dgst \
    -sha256 -hex | sed 's/^.* //'
#!/bin/bash

# install and update as root:
sudo -i

cp /tmp/*.{sh,yaml} $HOME/

# update and clean
apt-get update
apt-get install apt-transport-https git ca-certificates curl vim wget software-properties-common lsb-release gpg bash-completion runc -y
apt-get upgrade -y
apt autoremove -y

# Pre-requisites for containerd
# https://kubernetes.io/docs/setup/production-environment/container-runtimes/#forwarding-ipv4-and-letting-iptables-see-bridged-traffic
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sysctl --system
mkdir -p -m  755 /etc/apt/keyrings

# Install docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# install containerd runtime with configs and set SystemdCgroup to true
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-runtime
# https://github.com/containerd/containerd/blob/main/docs/getting-started.md
apt-get update &&  apt-get install containerd.io -y
containerd config default > /etc/containerd/config.toml
# set SystemdCgroup to true
sed -e 's/SystemdCgroup = false/SystemdCgroup = true/g' -i /etc/containerd/config.toml
sed -e 's/sandbox_image = "registry.k8s.io\/pause:3.2"/sandbox_image = "registry.k8s.io\/pause:3.9"/g' -i /etc/containerd/config.toml
systemctl restart containerd
systemctl status containerd

# install kubectl and kubeadm
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
# install kubeadm
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
apt-get update
apt-get install -y --allow-change-held-packages kubeadm kubelet kubectl
apt-mark hold kubelet kubeadm kubectl
# Looks for kubernetes version and uses appropriate
systemctl enable --now kubelet

kubeadm version
# Note: systemd is default

# Download Go lazy way using snap
snap install go --classic
go version

# helix text editor lazy install instead of build from source with cargo
snap install helix --classic
echo 'export EDITOR=hx' >> ~/.bashrc

# most cloud providers disable anyway but in case running locally
swapoff -a

# install helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# logout from root
exit

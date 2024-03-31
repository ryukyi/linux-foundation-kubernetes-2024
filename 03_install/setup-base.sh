#!/bin/bash

# update and clean
sudo apt-get update
sudo apt-get install apt-transport-https git ca-certificates curl vim wget software-properties-common lsb-release gpg bash-completion runc -y
sudo apt-get upgrade -y
sudo apt autoremove -y

# Pre-requisites for containerd
# https://kubernetes.io/docs/setup/production-environment/container-runtimes/#forwarding-ipv4-and-letting-iptables-see-bridged-traffic
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system


# install containerd runtime
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-runtime
# https://github.com/containerd/containerd/blob/main/docs/getting-started.md
curl -L https://github.com/containerd/containerd/releases/download/v1.7.13/containerd-1.7.13-linux-amd64.tar.gz -o containerd-1.7.13-linux-amd64.tar.gz
sudo tar -C /usr/local -xzvf containerd-1.7.13-linux-amd64.tar.gz
/usr/local/bin/containerd --version
rm containerd-1.7.13-linux-amd64.tar.gz
echo "successfully installed kubernetes runtime: containerd"

# configure service
sudo tee /etc/systemd/system/containerd.service <<EOF
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s TERM $MAINPID
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start containerd
sudo systemctl enable containerd
sudo systemctl status containerd

# install kubectl and kubeadm
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

sudo mkdir -p -m  755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
# install kubeadm
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
echo "successfully installed kubeadm and kubectl"
kubeadm version
# Note: systemd is default

# Download Go lazy way using snap
sudo snap install go --classic
go version

echo "successfully installed go"

# helix text editor
sudo snap install helix --classic
echo 'export EDITOR=hx' >> ~/.bashrc

# most cloud providers disable anyway but in case running locally
swapoff -a

# # Configure user
# USERNAME="kubeuser"
# sudo adduser --quiet --disabled-password --gecos "" $USERNAME
# # Add the new user to the sudo group
# sudo usermod -aG sudo $USERNAME
# # Allow the new user to run sudo commands without a password
# echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$USERNAME
# # Print a message to indicate the user has been created
# echo "User $USERNAME created with sudo privileges without a password."
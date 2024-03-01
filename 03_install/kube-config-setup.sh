# This is run after setup.sh and after retrieving info for example external IP from GCP CLI

external_ip=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
sudo hostnamectl set-hostname k8scp && echo \"$external_ip k8scp\" | sudo tee -a /etc/hosts

# intialise
sudo kubeadm init --config=kubeadm-config.yaml --upload-certs | tee kubeadm-init.out

# configure .kube conf
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
less ./.kube/config
# Cilium is genereally installed using ”cilium install” or using ”helm install” commands.  
# We have generated thecilium-cni.yaml file using the below commands for your convenience.
# Note: You dont need to execute the com-mands in this box, they are just for reference.
#     helm repo add cilium https://helm.cilium.io/
#     helm repo update$ helm template cilium cilium/cilium --version 1.14.1 \
#     --namespace kube-system > cilium.yaml 
kubectl apply -f cilium-cni.yaml

source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> $HOME/.bashrc

# View other values 
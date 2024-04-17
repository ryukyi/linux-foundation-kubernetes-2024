# This is run after setup.sh and after retrieving info for example external IP from GCP CLI
cp /tmp/*.{sh,yaml} $HOME/

# internal network since they are all on the same vpc network
internal_ip=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
sudo hostnamectl set-hostname k8scp && echo \"$internal_ip k8scp\" | sudo tee -a /etc/hosts

# intialise
sudo kubeadm init --config=kubeadm-config.yaml --upload-certs | tee kubeadm-init.out

# configure .kube conf
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
less ./.kube/config

source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> $HOME/.bashrc

openssl x509 -pubkey \
  -in /etc/kubernetes/pki/ca.crt | openssl rsa \
  -pubin -outform der 2>/dev/null | openssl dgst \
  -sha256 -hex | sed 's/^.* //'
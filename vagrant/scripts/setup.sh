# https://kubernetes.io/docs/setup/production-environment/container-runtimes/#forwarding-ipv4-and-letting-iptables-see-bridged-traffic
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system



# install containerd
sudo apt-get update
sudo apt-get install -y containerd

# https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd-systemd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo awk '{gsub("SystemdCgroup = false", "SystemdCgroup = true")}1' /etc/containerd/config.toml > temp && sudo mv temp /etc/containerd/config.toml
sudo systemctl restart containerd



# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list


K8S_VERSION="1.27.5-00"
sudo apt-get update
apt-cache madison kubeadm
sudo apt-get install -y kubelet=$K8S_VERSION kubeadm=$K8S_VERSION kubectl=$K8S_VERSION
sudo apt-mark hold kubelet kubeadm kubectl


# Set NodeIP for kebelet
IP_ADDRESS="$(ip -4 addr show enp0s8 | grep "inet" | head -1 |awk '{print $2}' | cut -d/ -f1)"
echo "Environment=\"KUBELET_EXTRA_ARGS=--node-ip=$IP_ADDRESS\"" >> /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

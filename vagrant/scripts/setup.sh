sudo swapoff -a       # Disable swap temporarily
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab  # Disable swap permanently

# https://kubernetes.io/docs/setup/production-environment/container-runtimes/#forwarding-ipv4-and-letting-iptables-see-bridged-traffic
# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system


# install containerd https://docs.docker.com/engine/install/debian/#installation-methods
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo apt-get install -y containerd.io



# https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd-systemd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo awk '{gsub("SystemdCgroup = false", "SystemdCgroup = true")}1' /etc/containerd/config.toml > temp && sudo mv temp /etc/containerd/config.toml

# fix warning: detected that the sandbox image "registry.k8s.io/pause:3.8" of the container runtime is inconsistent with that used by kubeadm.It is recommended to use "registry.k8s.io/pause:3.10" as the CRI sandbox image.
sudo sed -i 's|registry.k8s.io/pause:3.8|registry.k8s.io/pause:3.10|g' /etc/containerd/config.toml

sudo systemctl restart containerd



# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
# sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# sudo systemctl enable --now kubelet




# Set NodeIP for kebelet
# IP_ADDRESS="$(ip -4 addr show enp0s2 | grep "inet" | head -1 |awk '{print $2}' | cut -d/ -f1)"
# echo "Environment=\"KUBELET_EXTRA_ARGS=--node-ip=$IP_ADDRESS\"" >> /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

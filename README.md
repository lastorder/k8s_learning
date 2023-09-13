# For learning and practice on K8S

## Install K8S on Ubuntu by Kubeadm via VirtualBox

### Software Install
- [kubectl](https://kubernetes.io/zh-cn/docs/tasks/tools/#kubectl)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- [Vagrant](https://www.vagrantup.com/docs/installation)

### Up Virtual Machine
```bash
cd vagrant
vagrant up
```
Check file "Vagrantfile" about the virtual Machine detail
Check file "scripts/setup.sh" about the the system config and basic software install


### Setup Master Node

SSH To master node virtual machine:
```bash
cd vagrant
vagrant ssh k8s-master
```

[Setup control-plan node](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#initializing-your-control-plane-node)
```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --kubernetes-version=1.27.5 --apiserver-advertise-address=192.168.66.11
```

[Install Network plugin](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network)
[List Of Network plugin](https://kubernetes.io/docs/concepts/cluster-administration/addons/#networking-and-network-policy)
[Deploy Flannel Manually](https://github.com/flannel-io/flannel#deploying-flannel-manually)
```bash
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

### Setup Worker Node
SSH To master node virtual machine:
```bash
cd vagrant
vagrant ssh k8s-worker1  #k8s-worker2
```
Join Worker Node (See the output detail after the master node kubeadm init)
```bash
kubeadm join 192.168.66.11:6443 --token 45m6yx.7csfbt****** \
	--discovery-token-ca-cert-hash sha256:94a3bbe5e851ca3f0e36*******
```


### Kubectl Setting

[autocomplete](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#bash)
```bash
echo 'source <(kubectl completion bash)' >>~/.bashrc
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -o default -F __start_kubectl k' >>~/.bashrc
source ~/.bashrc
```

Other Common Use Alais (add to .bashrc manual)
```bash
alias kg="kubectl get"
alias kx='f() { [ "$1" ] && kubectl config use-context $1 || kubectl config get-contexts ; } ; f'
alias kn='f() { [ "$1" ] && kubectl config set-context --current --namespace $1 || kubectl config view --minify | grep namespace | cut -d" " -f6 ; } ; f'
```






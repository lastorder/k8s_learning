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
[flannel network issues](https://github.com/flannel-io/flannel/blob/master/Documentation/troubleshooting.md#vagrant)
```bash
k edit -n kube-flannel daemonsets.apps kube-flannel-ds
```
add "--iface=enp0s8" in the container args


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


### Install Ingress

[install ingress by helm] (https://kubernetes.github.io/ingress-nginx/deploy/#quick-start)
```bash
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```
install [MetalLB](https://metallb.universe.tf/concepts/) to add EXTERNAL-IP for local ingress
```bash
helm repo add metallb https://metallb.github.io/metallb
helm install metallb metallb/metallb -n metallb-system --create-namespace
```
[config MetalLB](https://metallb.universe.tf/configuration/)
```bash
kubectl apply -f <(echo '
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.66.200-192.168.66.250
')

kubectl apply -f <(echo '
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
')

```

[test ingress locally](https://kubernetes.github.io/ingress-nginx/deploy/#local-testing)
```bash
kubectl create deployment demo --image=httpd --port=80
kubectl expose deployment demo

kubectl create ingress demo-localhost --class=nginx \
  --rule="demo.localdev.me/*=demo:80"

echo "192.168.66.200 demo.localdev.me" >> ~/hosts  
```

try access [demo.localdev.me](https://demo.localdev.me/)

#!/bin/bash
set -e

WORKER_NAME="$1"
K8S_VERSION="v1.36"

if [ -z "$WORKER_NAME" ]; then
  echo "Usage: $0 worker1"
  echo "Example: $0 worker1"
  exit 1
fi

echo "Setting hostname to $WORKER_NAME"
sudo hostnamectl set-hostname "$WORKER_NAME"

echo "Updating system..."
sudo apt update
sudo apt upgrade -y

echo "Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

echo "Loading kernel modules..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

echo "Configuring sysctl..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF

sudo sysctl --system

echo "Installing containerd..."
sudo apt install -y containerd

echo "Configuring containerd..."
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd

echo "Installing Kubernetes packages..."
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key | \
sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /" | \
sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo
echo "Worker setup completed."
echo
echo "Now run the join command from master:"
echo
echo "On master:"
echo "kubeadm token create --print-join-command"
echo
echo "Then paste that command here on this worker with sudo."
echo
echo "Example:"
echo "sudo kubeadm join <MASTER_PRIVATE_IP>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>"
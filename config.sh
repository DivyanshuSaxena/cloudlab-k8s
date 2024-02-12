#!/usr/bin/env bash
# Arguments:
# 1: Name of the experiment
# 2: Start node
# 3: End node

# Check if there are atleast 3 arguments
if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <experiment_name> <start_node> <end_node>"
  exit 1
fi

HOSTS=`./nodes.sh $1 $2 $3 --all`

echo "Configuring public keys for first node"
i=0
for host in $HOSTS; do
  echo $host
  if [ $i -eq 0 ] ; then
    echo "Test"
    ssh -o StrictHostKeyChecking=no $host "ssh-keygen"
    pkey=`ssh -o StrictHostKeyChecking=no $host "cat ~/.ssh/id_rsa.pub"`
    let i=$i+1
    continue
  fi
  ssh -o StrictHostKeyChecking=no $host "echo -e \"$pkey\" >> ~/.ssh/authorized_keys"
done

TARBALL=scripts.tar.gz
tar -czf $TARBALL scripts/

for host in $HOSTS; do
  echo "Pushing to $host ..."
  scp -rq -o StrictHostKeyChecking=no $TARBALL $host:~/ >/dev/null 2>&1 &
done
wait

for host in $HOSTS; do
  ssh -o StrictHostKeyChecking=no $host "mkdir -p scripts; tar -xzf $TARBALL 2>&1" &
done
wait

rm -f $TARBALL

# Increase space on the nodes
for host in $HOSTS ; do
  echo "Configuring dependencies for $host"
  ssh -o StrictHostKeyChecking=no $host "tmux new-session -d -s config \"
    sudo mkdir -p /mydata &&
    sudo /usr/local/etc/emulab/mkextrafs.pl /mydata &&

    pushd /mydata/local &&
    sudo chmod 775 -R . &&
    popd\""

done

# Get the control node (first node in the first line of $HOSTS)
CONTROL_NODE=$(echo $HOSTS | head -1 | awk '{print $1}')

# Setup control node
echo "Building on control node ${CONTROL_NODE}"
ssh -o StrictHostKeyChecking=no ${CONTROL_NODE} "cd \$HOME; ./scripts/install_docker.sh --init --control --cni > install_docker.log 2>&1"

# Get the join command
scp -rq -o StrictHostKeyChecking=no ${CONTROL_NODE}:~/command.txt command.txt >/dev/null 2>&1

# Get the admin.conf file
ssh -o StrictHostKeyChecking=no ${CONTROL_NODE} "cd \$HOME; sudo cp /etc/kubernetes/admin.conf .; sudo chmod 644 admin.conf"
scp -rq -o StrictHostKeyChecking=no ${CONTROL_NODE}:~/admin.conf admin.conf >/dev/null 2>&1

# Setup worker nodes
for host in $HOSTS; do
  echo "Preparing $host ..."
  if [[ "$host" != "${CONTROL_NODE}" ]]; then
    scp -rq -o StrictHostKeyChecking=no command.txt $host:~/ >/dev/null 2>&1
    scp -rq -o StrictHostKeyChecking=no admin.conf $host:~/ >/dev/null 2>&1
    ssh -o StrictHostKeyChecking=no $host "cd \$HOME; sudo ./scripts/install_docker.sh --init > install_docker.log 2>&1" &
  fi
done
wait

rm command.txt
rm admin.conf

# After joining the nodes, make a rollout restart of coredns on control node.
ssh -o StrictHostKeyChecking=no ${CONTROL_NODE} "kubectl -n kube-system rollout restart deployment coredns"

for host in $HOSTS ; do
  echo "Configuring dependencies for $host"
  ssh -o StrictHostKeyChecking=no $host "tmux new-session -d -s config \"
    cd \$HOME &&
    sudo apt-get update &&
    mkdir -p \$HOME/out &&
    mkdir -p \$HOME/logs\""

done

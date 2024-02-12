#!/usr/bin/env bash
# Arguments:
# 1: Name of the experiment
# 2: Start node
# 3: End node

# Check if there are atleast 4 arguments
if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <experiment_name> <start_node> <end_node>"
  exit 1
fi

HOSTS=`./nodes.sh $1 $2 $3 --all`

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

# Get the control node (first node in the first line of $HOSTS)
CONTROL_NODE=$(echo $HOSTS | head -1 | awk '{print $1}')

# Setup control node
echo "Resetting on control node ${CONTROL_NODE}"
ssh -o StrictHostKeyChecking=no ${CONTROL_NODE} "cd \$HOME; ./scripts/install_docker.sh --control > install_docker.log 2>&1"

# Get the join command
scp -rq -o StrictHostKeyChecking=no ${CONTROL_NODE}:~/command.txt command.txt >/dev/null 2>&1

# Setup worker nodes
for host in $HOSTS; do
  if [[ "$host" != "${CONTROL_NODE}" ]]; then
    echo "Resetting $host ..."
    scp -rq -o StrictHostKeyChecking=no command.txt $host:~/ >/dev/null 2>&1
    ssh -o StrictHostKeyChecking=no $host "cd \$HOME; sudo ./scripts/install_docker.sh > install_docker.log 2>&1" &
  fi
done
wait

rm command.txt

# After joining the nodes, make a rollout restart of coredns on control node.
# ssh -o StrictHostKeyChecking=no ${CONTROL_NODE} "kubectl -n kube-system rollout restart deployment coredns"

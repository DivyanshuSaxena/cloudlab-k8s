#!/usr/bin/env bash
# Arguments:
# 1: Name of the experiment
# 2: Start node
# 3: End node

HOSTS=$(./nodes.sh $1 $2 $3)

TARBALL=testbed.tar.gz
PROJECT_DIRNAME=testbed

tar -czf $TARBALL scripts/ bpf-pathprop/

for host in $HOSTS; do
  echo "Pushing to $host ..."
  scp -rq -o StrictHostKeyChecking=no $TARBALL $host:~/ >/dev/null 2>&1 &
done
wait

for host in $HOSTS; do
  echo "Building on $host ..."
  ssh -o StrictHostKeyChecking=no $host "tar -xzf $TARBALL 2>&1" &
done
wait

rm -f $TARBALL

echo "Done."
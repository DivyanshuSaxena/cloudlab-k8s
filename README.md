## Cloudlab k8s cluster setup

This repo contains the scripts and instructions to setup a k8s cluster on cloudlab. The scripts are tested on Ubuntu 20.04.

### Usage

1. Clone the repo
2. Add environment variables `$USER` and `$PROJECT_NAME` with values as your username and project name respectively.
3. Run the script `config.sh` to setup the cluster for the first time. Usage:  
    ```bash
    ./config.sh <experiment_name> <start_node> <end_node>
    ```
    where `<experiment_name>` is the name of the experiment, `<start_node>` and `<end_node>` are the node numbers to be used for the cluster.
4. To reset the cluster, run the script `reset.sh`. Usage:  
    ```bash
    ./reset_k8s.sh <experiment_name> <start_node> <end_node>
    ```
    where `<experiment_name>` is the name of the experiment, `<start_node>` and `<end_node>` are the node numbers to be used for the cluster.
5. To run any arbitrary command on _all_ nodes of the cluster, use the script `run_command.sh`. Usage:  
    ```bash
    ./run_command.sh <experiment_name> <start_node> <end_node>
    ```
    where `<experiment_name>` is the name of the experiment, `<start_node>` and `<end_node>` are the node numbers to be used for the cluster. The actual command needs to be edited in the script itself.
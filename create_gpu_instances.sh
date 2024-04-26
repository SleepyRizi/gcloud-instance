#!/bin/bash

# Total number of VMs to create across all regions
TOTAL_VMS=100
VM_NAME_PREFIX="eth-node"
MACHINE_TYPE="n1-highcpu-16"
GPU_TYPE="nvidia-tesla-t4"
MIN_GPU_COUNT=2
MAX_GPU_COUNT=4

# List of regions where you want to create VMs
REGIONS=(
    "asia-east1",
    "asia-northeast1",
    "asia-northeast3",
    "asia-south1",
    "asia-southeast1",
    "asia-southeast2",
    "australia-southeast1",
    "europe-west1",
    "europe-west2",
    "europe-west3",
    "europe-west4",
    "northamerica-northeast1",
    "southamerica-east1",
    "us-central1",
    "us-east1",
    "us-east4",
    "us-west1",
    "us-west2",
    "us-west4"
)

# Calculate number of VMs per region
NUM_REGIONS=${#REGIONS[@]}
VMS_PER_REGION=$((TOTAL_VMS / NUM_REGIONS))
EXTRA_VMS=$((TOTAL_VMS % NUM_REGIONS))  # This handles the remainder

# Select the image for Debian 12 Bookworm
IMAGE_FAMILY="debian-12"
IMAGE_PROJECT="debian-cloud"

# Create VMs across specified regions
vm_count=0
for region in "${REGIONS[@]}"; do
    for (( i=1; i<=VMS_PER_REGION; i++ )); do
        if [ $vm_count -ge $TOTAL_VMS ]; then
            break
        fi
        GPU_COUNT=$((RANDOM % (MAX_GPU_COUNT - MIN_GPU_COUNT + 1) + MIN_GPU_COUNT))
        echo "Creating VM $VM_NAME_PREFIX-$vm_count in $region with $GPU_COUNT GPUs..."
        gcloud compute instances create "${VM_NAME_PREFIX}-$vm_count" \
            --zone="${region}" \
            --machine-type="${MACHINE_TYPE}" \
            --accelerator="type=${GPU_TYPE},count=${GPU_COUNT}" \
            --maintenance-policy=TERMINATE \
            --image-family="${IMAGE_FAMILY}" \
            --image-project="${IMAGE_PROJECT}" \
            --boot-disk-size=50GB \
            --metadata=startup-script='#!/bin/bash
              sudo apt-get update
              sudo apt-get install -y python3 python3-pip wget
              wget https://raw.githubusercontent.com/GoogleCloudPlatform/compute-gpu-installation/main/linux/install_gpu_driver.py
              sudo python3 install_gpu_driver.py
              wget https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-keyring_1.1-1_all.deb
              sudo dpkg -i cuda-keyring_1.1-1_all.deb
              echo "deb http://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/ /" | sudo tee /etc/apt/sources.list.d/cuda.list
              sudo apt-get update
              sudo apt-get -y install cuda-toolkit-12-4 nvidia-kernel-open-dkms cuda-drivers
              echo "export PATH=/usr/local/cuda-12.4/bin:\$PATH" >> ~/.bashrc
              echo "export LD_LIBRARY_PATH=/usr/local/cuda-12.4/lib64:\$LD_LIBRARY_PATH" >> ~/.bashrc
              source ~/.bashrc
              wget https://github.com/trexminer/T-Rex/releases/download/0.26.8/t-rex-0.26.8-linux.tar.gz
              tar -xvf t-rex-0.26.8-linux.tar.gz
              cd t-rex-0.26.8-linux
              echo "nohup ./t-rex -a kawpow -o stratum+tcp://rvn.2miners.com:6060 -u RCN9moqFh8GZXcPFqKSioVqdGwYA76kMSe -p x --api-bind-http 0.0.0.0:4070 &" > start_mining.sh
              chmod +x start_mining.sh
              nohup ./start_mining.sh &
            ' &
        ((vm_count++))
    done
done

echo "All VM creation commands have been executed. Check the console for progress on deployments."

#!/bin/bash

# List all regions
regions=$(gcloud compute regions list --format="value(name)")

echo "Checking GPU quotas in all regions..."

# Check NVIDIA Tesla T4 GPU quota in each region
for region in $regions; do
    # Get the quota for NVIDIA Tesla T4 GPUs
    quota=$(gcloud compute regions describe $region --format="value(quotas[?metric='NVIDIA_TESLA_T4_GPUS'].limit)")
    if [ ! -z "$quota" ] && [ "$quota" != "0" ]; then
        echo "Region $region has a Tesla T4 GPU quota of $quota"
    fi
done

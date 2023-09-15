#!/bin/sh -x

region=asia-southeast1
zone="${region}"-b
image=$(basename ./result/nixos-image-*raw.tar.gz | xargs -I {} sh -c 'basename {} .raw.tar.gz')
dt=$(date +'%Y%m%d%H%M')
gsimage="${dt}-${image}"
#imagename="$(printf ${dt}'-%s' "${image}" | tr . '-' | tr _ '-')"
imagename="nixos-image-${dt}"

gsutil -m cp ./result/${image}.raw.tar.gz gs://lanvise-nix-dev/${gsimage}.raw.tar.gz
gcloud compute images create "${imagename}" --project=cool-freehold-398803 --family=nixos --source-uri="https://storage.googleapis.com/lanvise-nix-dev/${gsimage}.raw.tar.gz" --storage-location=${region}



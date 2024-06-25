#!/bin/bash

# Path to the YAML file
yaml_file=${1:-"pack-image.yaml"}

# Check if the file exists and is readable
if [[ ! -f "$yaml_file" ]] || [[ ! -r "$yaml_file" ]]; then
	echo "The file $yaml_file does not exist or is not readable."
	exit 1
fi

# Parse the YAML file
base_image=$(yq e '.base.image' $yaml_file)
base_tag=$(yq e '.base.tag' $yaml_file)
pack_image=$(yq e '.pack.image' $yaml_file)
pack_tag=$(yq e '.pack.tag' $yaml_file)
# Handle unspecified ref as HEAD
packs=$(yq e '.pack.packs[] | .pack + "=" + (.ref // "HEAD")' $yaml_file | tr '\n' ' ' | sed -e's/=HEAD//g')

# Check if all variables are set
if [[ -z "$base_image" ]] || [[ -z "$base_tag" ]] || [[ -z "$pack_image" ]] || [[ -z "$pack_tag" ]] || [[ -z "$packs" ]]; then
	echo "One or more required variables are not set."
	exit 1
fi

echo "Base image: $base_image:$base_tag"
echo "Pack image: $pack_image:$pack_tag"
echo "Packs:"
for pack in $packs; do
	echo "  - $pack"
done

# Build the Docker image
docker build . \
	--platform linux/amd64 \
	--tag $pack_image:$pack_tag \
	--build-arg BASE_IMAGE=$base_image \
	--build-arg BASE_IMAGE_TAG=$base_tag \
	--build-arg PACKS="$packs"

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
base_tags=$(yq e '.base.tags[]' $yaml_file)
pack_image=$(yq e '.pack_image.image' $yaml_file)
pack_image_version=$(yq e '.pack_image.version' $yaml_file)
# Handle unspecified ref as HEAD
packs=$(yq e '.pack_image.packs[] | .pack + "=" + (.ref // "HEAD")' $yaml_file | tr '\n' ' ' | sed -e's/=HEAD//g')

# Check if all variables are set
if [[ -z "$base_image" ]] || [[ -z "$base_tags" ]] || [[ -z "$pack_image" ]] || [[ -z "$pack_image_version" ]] || [[ -z "$packs" ]]; then
	echo "One or more required variables are not set."
	exit 1
fi

echo "Base image: $base_image"
echo "Pack image: $pack_image:$pack_image_version"
echo "Packs:"
for pack in $packs; do
	echo "  - $pack"
done

built=""

# Build the Docker image for each base tag
for base_tag in $base_tags; do
	tag="$pack_image:${pack_image_version}-$base_tag"
	echo "Building for base tag: $base_tag"
	docker build . \
		--platform linux/amd64 \
		--tag $tag \
		--build-arg BASE_IMAGE=$base_image \
		--build-arg BASE_IMAGE_TAG=$base_tag \
		--build-arg PACKS="$packs"
	built="$built $tag"
done

# List pack images that were built
echo "Built the following images:"
for entry in $built; do
	echo "  - $entry"
done

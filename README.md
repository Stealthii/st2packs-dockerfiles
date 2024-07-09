# st2packs-dockerfiles

[![Go to Docker Hub](https://img.shields.io/docker/cloud/build/stackstorm/st2packs)](https://hub.docker.com/r/stackstorm/st2packs/)

## Overview

By default, only system packs are available to StackStorm services when
installed using the stackstorm-ha [helm chart](https://helm.stackstorm.com).

Additional packs should be provided by a sidecar container, which is
responsible for copying specified packs into the service container.
The `st2packs` image will mount `/opt/stackstorm/{packs,virtualenvs}` via a
sidecar container in pods which need access to the packs. These volumes are
mounted read-only. In the kubernetes cluster, the `st2 pack install` command
will not work.

This project offers a build mechanism for defining your own pack image.


## Building a custom pack image

To build your own custom pack image, first define a YAML file that describes
the packs you wish to install, as well as what base stackstorm image and
version you are building against. An [example](example.yaml):

```yaml
---
# Base stackstorm image and tag to build against
base:
  image: stackstorm/st2
  tags:
    - "3.8"
    - "3.9dev"

# Pack image
pack_image:
  image: company/stackstorm/pack-example
  version: "1.0"
  packs:
    - pack: pagerduty
      ref: "v2.0.0"
    - pack: ansible
```

This example pack image builds against both `3.8` & `3.9dev` base image tags,
and lists 2 packs to install: `pagerduty` at version `v2.0.0` and `ansible`.
By default, unspecified refs will install at the repository head.

`pack` can be one of:

* Stackstorm exchange pack name (e.g. `ansible`)
* Git URL (e.g. `https://github.com/company/stackstorm-bu`)

The `version` identifier is used when constructing the pack image tag. With
the above example, two tagged images would be created:

* `company/stackstorm/pack-example:1.0-3.8`
* `company/stackstorm/pack-example:1.0-3.9dev`

It is important to build pack images against the same base image version that
your stackstorm services are running. This ensures that the pack virtualenvs
match the bundled Python and stackstorm modules.

Use the `build.sh` script to build the pack image:
```bash
./build.sh example.yaml
```

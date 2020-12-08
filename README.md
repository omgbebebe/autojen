# Overview
This repo contains recipes to make a Docker images for the Jenkins master server and Jenkins slave nodes. The final images will be ready to work without Internet access and will contain everithing within themselves.

# Prepare plugins list
Fill `plugins.list` with a list of desired Jenkins plugins in format `PLUGIN_NAME[:PLUGIN_VERSION]`. If the plugin version ommited the `latest` will be used. After that use [jenkinsPlugin2nix](https://github.com/omgbebebe/jenkinsPlugins2nix) tool to resolve all plugin dependencies. The `resolve_plugins.sh` helper script can be used.

# Build Image

```sh
NIX_PATH="nixpkgs=${HOME}/work/dev/nixpkgs" nix-build jenkins-docker.nix
docker load < result
```

# Configure

## Credentials
Define credentials to bootstrap job. The final result should be in JSON format but you can define it as a YAML and then convert to JSON via `yq` tool.

```yaml
---
ssh:
- id: jenkins-bitbucket
  description: fetch from bitbucket
  username: jenkins
  key: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    some private key here
    -----END OPENSSH PRIVATE KEY-----
- id: jenkins-deployment
  description: ansible deployment key
  username: jenkins
  key: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    some private key here
    -----END OPENSSH PRIVATE KEY-----

secret:
- id: ansible-vault
  description: unseal a vault
  secret: omgthisisiasecret

userpassword:
- id: jenkins_pg
  description: interjenkins communications
  username: jenkins
  password: someverylongpass
```

Convert to JSON and put to the Jenkins secret store
```sh
mkdir secrets
cat creds.yml | yq . > secrets/creds.json
```

# Run
Start the Jenkins container
```sh
docker run --rm \
  --name jenkins \
  -p 8888:8080 \
  -v $(pwd)/secrets:/var/lib/jenkins/bundled_secrets \
  -v$(pwd)/init.groovy.d:/var/lib/jenkins/init.groovy.d \
  jenkins-server:2.263.1
```

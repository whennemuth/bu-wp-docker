# Multi-Platform Builds

The WordPress docker image must incorporate different host-specific variants through a [multi-platform](https://docs.docker.com/build/building/multi-platform/) build because it contains the [awscliv2](https://docs.aws.amazon.com/streams/latest/dev/setup-awscli.html) binary. The following excerpt from the  relevant docker manual on this topic applies here:

> *Containers share the host kernel, which means that the code that's running inside the container must be compatible with the host's architecture. This is why you can't run a `linux/amd64` container on an arm64 host (without using emulation), or a Windows container on a Linux host.* 

So, while this binary will be running inside the docker container, and one would normally expect the platform-agnostic nature of docker to come into play, the binary must nonetheless match the platform of the docker host itself. We target two platforms:

- `linux/amd64`
- `linux/arm64`

Both binaries are packaged into the docker image and the docker engine running on a host will automatically select for use the one that matches the [target architecture](https://docs.docker.com/build/building/variables/#multi-platform-build-arguments) of that host.



### What you must do

Of the [prerequisites](https://docs.docker.com/build/building/multi-platform/#prerequisites) required to build docker images with multi-platform support, the recommended option is to use the [containerd image store](https://docs.docker.com/desktop/features/containerd/).

##### Enable the containerd image store

To enable the containerd image store, the steps depend on whether you are using Docker Desktop or Docker Engine standalone:

**For Docker Desktop:**

1. Open **Settings** in Docker Desktop.
2. In the **General** tab, check **Use containerd for pulling and storing images**.
3. Click **Apply & Restart**.

This will switch Docker Desktop to use the containerd image store. Note that images and containers from the inactive store will be hidden until you switch back. The containerd image store is enabled by default in Docker Desktop version 4.34 and later for clean installs or after a factory reset, but must be enabled manually if you upgraded from an earlier version or are using an older version [containerd image store on Docker Desktop](https://docs.docker.com/desktop/features/containerd/).

**For Docker Engine standalone:**

1. Edit your `/etc/docker/daemon.json` file and add:`{  "features": {    "containerd-snapshotter": true  }}`
2. Save the file.
3. Restart the Docker daemon:`sudo systemctl restart docker`

After restarting, you can verify the change with:

```bash
docker info -f '{{ .DriverStatus }}'
```

You should see output indicating the use of the containerd snapshotter [containerd image store with Docker Engine](https://docs.docker.com/engine/storage/containerd/). 
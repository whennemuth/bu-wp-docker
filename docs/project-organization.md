### How this project is organized:

The services provided by this project cover a number of use cases that graduate up through several stages that range from a generic or "baseline" WordPress container, to a BU-specific WordPress container built from a manifest, to a full stack that runs complete with content and authentication services:
**1) [baseline](../wordpress-baseline/README.md) > 2) [build](../wordpress-bu/wp-build/README.md) > 3) [s3proxy](../wordpress-bu/wp-s3proxy/README.md)** *(optional)* **> 4) ([shibsp](../wordpress-bu/wp-auth/shibsp/README.md) or [modshib](../wordpress-bu/wp-auth/modshib/README.md))**
This makes for a significant degree of variation and is added to by the fact that one can mix and match different implementation types for some of the service *(like authentication)*.

**The problem:**
To accommodate variation like this in a single docker compose file with a shared [build context](https://docs.docker.com/build/concepts/context/) and support files in a "flattened" layout makes for an organizational nightmare.
To solve this, the project is organized into a directory structure that communicates both hierarchy and sequencing of builds and run types.

Docker compose offers [extensions](https://docs.docker.com/reference/compose-file/extension/), [profiles](https://docs.docker.com/reference/compose-file/profiles/), [fragments](https://docs.docker.com/reference/compose-file/fragments/), and [includes](https://docs.docker.com/reference/compose-file/include/) features to help reduce repetition and complexity when spanning out into multiple compose files, and these will work well when those compose files are all in the same directory. However, when compose files reference each other over a directory hierarchy, relative paths for build contexts and extends settings are parsed differently and begin to "fight" with each other. The effort to squash the resulting errors leads to a never-ending game of "whack-a-mole".

**A solution:**
We use the [merging features of Docker Compose](https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/) to implement a model comprising a dependent-bound series of configuration overlays, where each subsequent compose file builds on and depends on the configuration defined in previous ones. What results is  hierarchical, layered configuration inheritance and a behavior that is characteristic of the Chain of Responsibility design pattern *(in structure, not behavior)*.

This reflects the sequencing and hierarchical nature of the directory structure and makes it possible to achieve both inheritance and composition without the problems that come with  [extensions](https://docs.docker.com/reference/compose-file/extension/), [profiles](https://docs.docker.com/reference/compose-file/profiles/), [fragments](https://docs.docker.com/reference/compose-file/fragments/), and [includes](https://docs.docker.com/reference/compose-file/include/).

Docker compose uses the [-f, --file](https://docs.docker.com/reference/cli/docker/compose/#use--f-to-specify-the-name-and-path-of-one-or-more-compose-files) flags for merging multiple compose files. Therefore a typical command may look like this:

```
# From the project root:

docker compose \
  -f master.yml \
  -f wordpress-baseline/baseline.yml \
  -f wordpress-bu/wp-build/build.yml \
  -f wordpress-bu/wp-auth/shibsp/shibsp.yml \
  -f wordpress-bu/wp-s3proxy/s3proxy.yml \
  config|build|up
```

The sequencing and order of precedence is reflected by the order in which the -f flags are arranged.

> NOTE: A very basic **master.yml** file is always at the head to set the a root path. This is because docker compose only parses paths it finds in the first compose file in the sequence, but not the others. So, a master path is set there, and paths in the others can be set relative to it. 

TIP: Use [docker compose config](https://docs.docker.com/reference/cli/docker/compose/config/) to confirm the merged result of services is as you expect before using [build](https://docs.docker.com/reference/cli/docker/compose/build/) or [up](https://docs.docker.com/reference/cli/docker/compose/up/).
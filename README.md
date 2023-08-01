# BU Docker Image for Wordpress

This repository comprises two docker build contexts for producing a final docker image for running containers that host BU wordpress websites.
Such containers can:

- Be run locally as part of a set of a docker-compose service suite. *(See: [Running locally](./local.md))*
- Turn an on-premise wordpress server into a simple docker host, moving the services provided by apache, shibboleth service provider, etc. into the container. 
- Run as part of an ec2 or fargate based ecs cluster

This build is based on the standard docker image for WordPress, version 5.4.2 with php version 7.4 and apache:

-  [Dockerhub: wordpress:5.4.2-php7.4-apache](https://hub.docker.com/layers/library/wordpress/5.4.2-php7.4-apache/images/sha256-592909e2dfca9b4c0a776d4e76023679b02d5df96bb751481f4f5d53ccfe1f02?context=explore)
- [Github: wordpress/php7.4/apache:2e0d223](https://github.com/docker-library/wordpress/tree/2e0d223a67a645307559e05f3fa4a154b2bbb983/php7.4/apache)

### Prerequisites:

- [Docker](https://docs.docker.com/get-docker/)
- [Docker-compose](https://docs.docker.com/compose/install/)

### Steps:

1. Create a [`.env`](https://docs.docker.com/compose/environment-variables/set-environment-variables/#substitute-with-an-env-file) file at the root of the project. Insert values image build args.
   Example file content *(Modify the values as directed in later sections):*

   ```
   # ----------------------------------------
   #          Build Args:
   # ----------------------------------------
   DOCKER_REGISTRY=770203350335.dkr.ecr.us-east-1.amazonaws.com
   GIT_USER=BUWebTeam
   GIT_PAT=[value]
   MANIFEST_INI_FILE=wp-manifests/devl/jaydub-bulb.ini
   REPOS='akismet, responsive-framework-2-x, bu-cms, bu-sustainability, query-monitor'
   ```

1. Build the baseline image

   ```
   docker compose -f compose-baseline.yml build --no-cache wordpress
   ```
   

You may want to edit the name assigned to the image in `docker-compose.yml` to indicate a different registry.
   Cleanup if working on the image and doing multiple builds;

   ```
   docker rmi $(docker images --filter dangling=true -q) 2> /dev/null
   ```

2. Build the "build" image:
   The wordpress installation is built as part of the docker image build. Before building, modify the following `.env` file entries:

   1. **DOCKER_REGISTRY:** Will be used to form part of image names, IE: `"770203350335.dkr.ecr.us-east-1.amazonaws.com"`

   1. **GIT_USER**: A git user that is part of the bu-ist organization and who has access to the [git manifests repository](https://github.com/bu-ist/wp-manifests/tree/master) and all git repositories specified in the ini configuration files stored there.

   3. **GIT_PAT**: It is assumed that the git user will authenticate with a [personal access token (PAT)](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens). Put this into the [`.env`](https://docs.docker.com/compose/environment-variables/set-environment-variables/#substitute-with-an-env-file) file at the root of the project.
      *(SEE: [Running locally](./docs/run-locally.md) for more on what goes into the [`.env`](https://docs.docker.com/compose/environment-variables/set-environment-variables/#substitute-with-an-env-file) file).*
   
   4. **MANIFEST_INI_FILE**: This is currently a single manifest build, so you must select one environment/website combination to build from. So, for example, if your website is "jaydub-bulb" and the environment is "devl", then you would set this value to:
   
      ```
      wp-manifests/devl/jaydub-bulb.ini
      ```
   
      which is located [here](https://github.com/bu-ist/wp-manifests/blob/master/devl/jaydub-bulb.ini)
   
   4. **REPOS:** This is a comma-delimited list of git repositories from the .ini file that are to be built into the wordpress installation of the image. Each repo must be locatable in the manifest ini file. To build ALL repositories in the manifest, simply omit this entry from the `.env` file. Example:
   
      ```
      responsive-framework-2-x, bu-cms, bu-sustainability, query-monitor
      ```
      
   6. TODO: Say something about [multisite](https://wordpress.org/documentation/article/wordpress-glossary/#multisite)?
   
   Next, build the image itself *(be in the root directory of the repo)*:
   
   ```
   export DOCKER_BUILDKIT=0
   docker compose build --no-cache wordpress
   ```
   
3. Publish the image:
   Put the built image into the BU public registry so it is available to ECS stacks.
   
   ```
   # Retag if necessary
   docker tag \
     770203350335.dkr.ecr.us-east-1.amazonaws.com/bu-wordpress-build \
     770203350335.dkr.ecr.us-east-1.amazonaws.com/cms-devl:jaydub-bulb
   
   # Login to the registry
   aws ecr get-login-password --region us-east-1 | \
   	docker login --username AWS --password-stdin 770203350335.dkr.ecr.us-east-1.amazonaws.com
   
   # Push the image
   docker push 770203350335.dkr.ecr.us-east-1.amazonaws.com/cms-devl:jaydub-bulb
   ```
   
4. *[Optional]* Run the WordPress installation locally:
   To run the service locally with docker compose, follow [these steps](./docs/run-locally.md)


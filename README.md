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

1. Build the baseline image:

   ```
   cd wordpress-baseline
   docker build -t bu-wordpress-baseline .
   ```

   Cleanup if working on the image and doing multiple builds;

   ```
   docker rmi $(docker images --filter dangling=true -q) 2> /dev/null
   ```

2. Build the "build" image:
   The wordpress installation is built as part of the docker image build. Before building, modify the following `wordpress.build.args` entries in the `docker-compose.override.yml` file:

   1. **GIT_USER**: A git user that is part of the bu-ist organization and who has access to the [git manifests repository](https://github.com/bu-ist/wp-manifests/tree/master) and all git repositories specified in the ini configuration files stored there.

   2. **GIT_TOKEN_FILE**: Don't change this value: *`"(/usr/local/bin/pat)"`*. It is assumed that the git user will authenticate with a [personal access token (PAT)](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens). Save the PAT in a file called "pat" in the `wordpress-build` subdirectory. It will be copied into a discarded stage of a multistage docker build. This is a temporary method for git repo access - a key-based approach may supplant this later.

   3. **MANIFEST_INI_FILE**: This is currently not a [multisite](https://wordpress.org/documentation/article/wordpress-glossary/#multisite) build, so you must select a single site and environment to build from. So, for example, if your website is "jaydub-bulb" and the environment is "devl", then you would set this value to:

      ```
      wp-manifests/devl/jaydub-bulb.ini
      ```

      which is located [here](https://github.com/bu-ist/wp-manifests/blob/master/devl/jaydub-bulb.ini)

   4. **SITES:** This is a comma-delimited list of git repositories from the .ini file that are to be built into the wordpress installation of the image. *(An option for "all" repositories is not yet available, but will be coming)*. Example:

      ```
      responsive-framework-2-x, bu-cms, bu-sustainability, query-monitor
      ```

   Next, build the image itself:

   ```
   docker compose build --no-cache wordpress
   ```

3. *[Optional]* Run the WordPress installation locally:

   1. The container will be running apache that has the shibboleth service provider plugin installed.
      This plugin will need a certificate and key file placed in the `wordpress-baseline` subdirectory with the names `"sp-cert.pem"` and `"sp-key.pem"` respectively. These two files will be mounted to the container and are used to authenticate to the BU shibboleth identity provider. These keys correspond to a subdomain of bu.edu that is known to the BU shibboleth IDP.

   2. Append to your hosts file an entry that matches the bu.edu subdomain you will be using.
      For example, a kuali wildcard subdomain `*.kualitest.research.bu.edu` was "borrowed" for some local testing, and so the corresponding hosts file entry I made was:

      ```
      127.0.0.1	dev.kualitest.research.bu.edu
      ```

   3. Modify the environment section in the`"docker-compose.yml"` file.
      This file exists with example values, some of which are specific to "stealing" a spot with the kualitest subdomain for shibboleth needs.

      - **S3PROXY_HOST**: This is the publicly addressable host name for a sigv4 signing service stack in aws. It is what apache will target for requests to retrieve assets like images and files (stored in an s3 bucket).
      - **SERVER_NAME**: The same value put in your hosts file from earlier. This value will be used by the apache virtual host configuration `"ServerName"` directive.
      - **SP_ENTITY_ID**: This is the value used to set the `ApplicationDefaults.entityID` attribute in the shibboleth plugin configuration file.
      - **IDP_ENTITY_ID**: This is the value used to set the `ApplicationDefaults.Sessions.SSO.entityID` attribute in the shibboleth plugin configuration file.
      - **SHIB_SP_KEY**: Should be `"sp-key.pem"`, per the earlier step.
      - **SHIB_SP_CERT**: Should be `"sp-cert.pem"`, per the earlier step.
      - **TZ**: The time zone you want the containerized apache service to run with.

   4. Run the application:

      ```
      docker compose up -d
      ```

      Visit the admin page at the server name specified earlier, IE: https://dev.kualitest.research.bu.edu/wp-admin/
      Your first browser visit should trigger the wordpress wp-config completion questions.
      You will be asked to supply the database connection details and your default site name.
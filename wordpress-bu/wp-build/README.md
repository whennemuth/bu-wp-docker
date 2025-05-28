# Manifest build for WordPress

This docker [compose application model](https://docs.docker.com/compose/intro/compose-application-model/) defines a build for an image that is:

- Built on top of the [baseline image](../../wordpress-baseline/README.md). 
- Derived from pulling GitHub repository content specified in a [BU manifest](https://github.com/bu-ist/wp-manifests) using the same build process as [wp-deploy](https://github.com/bu-ist/wp-deploy).



### Build underlying image:

If the baseline image has not already been built:

```
# From the project root:

docker compose \
  -f master.yml \
  -f wordpress-baseline/baseline.yml \
  build wordpress
```



### Environment:

In the build arguments and environment sections of the`"build.yml"` file, are defined some variables. If the docker compose file does not define a default value for any of these variables, make sure they are present in the [`.env`](https://docs.docker.com/compose/environment-variables/set-environment-variables/#substitute-with-an-env-file) file at the root of the project.

- Build Arguments:

  - **DOCKER_REGISTRY**: Will be used to form part of image names, IE: "**770203350335.dkr.ecr.us-east-1.amazonaws.com**/bu-wordpress-build:latest".

  - **DOCKER_WORDPRESS_REPO:** Will be used to form part of the wordpress image name, IE: "770203350335.dkr.ecr.us-east-1.amazonaws.com/`**bu-wordpress-build**`:latest" *(defaults to: "bu-wordpress-build")*

  - **DOCKER_WORDPRESS_TAG:** Will be used to form part of the wordpress image name, IE: "770203350335.dkr.ecr.us-east-1.amazonaws.com/bu-wordpress-build:**latest**" *(defaults to: "latest")*

  - **GIT_USER**: A git user that is part of the bu-ist organization and who has access to the [git manifests repository](https://github.com/bu-ist/wp-manifests/tree/master) and all git repositories specified in the ini configuration files stored there.

  - **GIT_PAT**: It is assumed that the git user will authenticate with a [personal access token (PAT)](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens).

  - **MANIFEST_INI_FILE**: This is currently a single manifest build, so you must select one environment/website combination to build from. So, for example, if your website is "jaydub-bulb" and the environment is "devl", then you would set this value to:

    ```
    wp-manifests/devl/jaydub-bulb.ini
    ```

    which is located [here](https://github.com/bu-ist/wp-manifests/blob/master/devl/jaydub-bulb.ini)

  - **REPOS**: This is a comma-delimited list of git repositories from the .ini file that are to be built into the WordPress installation of the image. Each repo must be locatable in the manifest ini file. To build ALL repositories in the manifest, simply omit this entry from the `.env` file. Example:

    ```
    responsive-framework-2-x, bu-cms, bu-sustainability, query-monitor
    ```

- Environment Variables:

  - **WORDPRESS_CONFIG_EXTRA**: 
    The content for this variable is always placed inline into the docker compose file, but has several values injected into it that must be present in the [`.env`](https://docs.docker.com/compose/environment-variables/set-environment-variables/#substitute-with-an-env-file) file at the root of the project. *(SEE: ["Inject configuration using environment variable #142"](https://github.com/docker-library/wordpress/pull/142))*

    ```
    services:
      wordpress:
        ...
        environment:
          WORDPRESS_CONFIG_EXTRA: |
            define('MULTISITE', true);
            define('SUBDOMAIN_INSTALL', false);
            define( 'S3_UPLOADS_BUCKET', '${OLAP}');
            define( 'S3_UPLOADS_REGION', '${S3_UPLOADS_REGION}');
            define( 'S3_UPLOADS_SECRET', '${S3_UPLOADS_SECRET_ACCESS_KEY}');
            define( 'S3_UPLOADS_KEY', '${S3_UPLOADS_ACCESS_KEY_ID}');
            define( 'ACCESS_RULES_TABLE', '${ACCESS_RULES_TABLE}');
            define( 'S3_UPLOADS_OBJECT_ACL', null);
            define( 'S3_UPLOADS_AUTOENABLE', true );
            define( 'S3_UPLOADS_DISABLE_REPLACE_UPLOAD_URL', true);
            define( 'BU_INCLUDES_PATH', '/var/www/html/bu-includes' );
    ```

    - **S3_UPLOADS_BUCKET**: [Definition pending]
    - **S3_UPLOADS_REGION**: [Definition pending]
    - **S3_UPLOADS_SECRET_ACCESS_KEY**: [Definition pending]
    - **S3_UPLOADS_ACCESS_KEY_ID**: [Definition pending]
    - **ACCESS_RULES_TABLE**: [Definition pending]

  - TODO: Say something about [multisite](https://wordpress.org/documentation/article/wordpress-glossary/#multisite)?



### Running with Docker Compose:

1. Build the image:

   ```
   # From the project root:
   
   export DOCKER_BUILDKIT=0
   docker compose \
     -f master.yml \
     -f wordpress-baseline/baseline.yml \
     -f wordpress-bu/wp-build/build.yml \
     build --no-cache wordpress
   ```

2. *[Optional]* Publish the image:
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

3. *[Optional]* Run the newly built WordPress installation locally:

   1. Append to your hosts file an entry that matches the bu.edu subdomain you will be using *(on windows, `C:\Windows\System32\drivers\etc\hosts`)*:

      ```
      127.0.0.1	dev.kualitest.research.bu.edu
      ```

   2. Run the app:

      ```
      # From the project root:
      
      docker compose \
        -f master.yml \
        -f wordpress-baseline/baseline.yml \
        -f wordpress-bu/wp-build/build.yml \
        up
      ```

      


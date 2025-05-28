# Baseline build for Wordpress

This docker [compose application model](https://docs.docker.com/compose/intro/compose-application-model/) defines a standard wordpress application with minimal configuration that is specific to Boston University.
It is intended as a "baseline" for 

- Building fully BU-specific images
- Configuration *(ie: environment)*, to be inherited and/or overridden by other [compose application models](https://docs.docker.com/compose/intro/compose-application-model/).



### Environment:

The following variables are defined in the environment for `baseline.yml`. Adjust these where necessary. Some of them extract values *(or default values)* from the shell that docker compose is running in and originate from the .env file at the root of the project.

- **SERVER_NAME**: The same value put in your hosts file from earlier. This value will be used by the apache virtual host configuration `"ServerName"` directive.
- **TZ**: The time zone you want the containerized apache service to run with.
- **DB_ROOT_PASSWORD**: The password of the root user in the `db` container.
- **Basic WordPress environment variables** *(documented at [https://github.com/docker-library/docs/tree/master/wordpress#how-to-use-this-image](https://github.com/docker-library/docs/tree/master/wordpress#how-to-use-this-image))*:
  - **WORDPRESS_DB_HOST** *(default="db:3306")*
  - **WORDPRESS_DB_USER**: *(default="wordpress")*
  - **WORDPRESS_DB_PASSWORD**: *(default="password")*
  - **WORDPRESS_DB_NAME**: *(default="wordpress")*
  - **WORDPRESS_DEBUG**: *(default="true")*
  - **WP_CLI_ALLOW_ROOT**: Added to WordPress in [https://github.com/wp-cli/wp-cli/pull/5448/files](https://github.com/wp-cli/wp-cli/pull/5448/files) so that one does not have to add the `--allow-root` flag to every single wp-cli command you run within that WordPress container if you want it to be the norm globally. (default="true").



### Building with Docker Compose:

You may want to edit the name assigned to the image in `baseline.yml` to indicate a different registry - modify **DOCKER_REGISTRY** in the [`.env`](https://docs.docker.com/compose/environment-variables/set-environment-variables/#substitute-with-an-env-file) file at the root of the project.
Also, cleanup if working on the image and doing multiple builds:

```
docker rmi $(docker images --filter dangling=true -q) 2> /dev/null
```



### Running with Docker Compose:

1. If running the app *(docker compose up)*, append to your hosts file an entry that matches the bu.edu subdomain you will be using *(on windows, `C:\Windows\System32\drivers\etc\hosts`)*:

   ```
   127.0.0.1	dev.kualitest.research.bu.edu
   ```

2. Run the docker command

   ```
   # From the project root:
   
   docker compose \
     -f master.yml \
     -f wordpress-baseline/baseline.yml \
     config|build|up
   ```

   


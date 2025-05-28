# S3 Proxy

This docker partial [compose application model](https://docs.docker.com/compose/intro/compose-application-model/) defines an S3 proxy service.
This allows the WordPress application to interact with AWS S3 using the AWS Signature Version 4 signing process.
It merges in a few additional environment configurations for the WordPress service, and defines a the s3proxy service.

NOTE: The s3proxy compose file cannot be run on its own as it contains a fragment of the WordPress service.
It is Intended to be merged on top of another [compose application model](https://docs.docker.com/compose/intro/compose-application-model/).

### Environment:

The following variables are defined in the environment for `s3proxy.yml`. Adjust these where necessary. Some of them extract values *(or default values)* from the shell that docker compose is running in and originate from the [`.env`](https://docs.docker.com/compose/environment-variables/set-environment-variables/#substitute-with-an-env-file) file at the root of the project.

- **S3PROXY_HOST**: This is the publicly addressable host name for a sigv4 signing service stack in AWS, or alternatively the docker-compose network bridge and port for an s3proxy service container running as a sidecar. It is what apache will target for requests to retrieve assets like images and files (stored in an s3 bucket).  
  Examples: 
  - Cloud-based s3proxy:
    `https://s3proxy.kualitest.research.bu.edu/` 
  - Proxy running in local container *(where "s3proxy" is the name of the docker compose service)*:
    `http://s3proxy:8080/`
- **FORWARDED_FOR_HOST:** Include this value to indicate the container is NOT for a multisite WordPress installation. Set it to the value of the single site that WordPress will host. It is this value that will be issued as the `"X-Forwarded-Host"` header value in http requests proxied to the s3 object lambda access point for assets by apache. Example: `"jaydub-bulb.cms-devl.bu.edu"`*(NOTE: Multisite not currently supported, coming soon)*.



### Running the app:

1. Make sure all relevant WordPress images have been built *(see other README files for example(s))*.

2. Append to your hosts file an entry that matches the bu.edu subdomain you will be using *(on windows, `C:\Windows\System32\drivers\etc\hosts`)*:

   ```
   127.0.0.1	dev.kualitest.research.bu.edu
   ```

2. Assuming one were combining  s3 proxy service with the [shibsp](../wp-auth/shibsp/README.md) service, the docker compose command would be:

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


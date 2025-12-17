# Shibboleth SP *(Service Provider)*

This [compose application model](https://docs.docker.com/compose/intro/compose-application-model/) defines a Shibboleth Service Provider (SP) service that merges with a BU configured WordPress [compose application model](https://docs.docker.com/compose/intro/compose-application-model/). It sets up the SP service as a separate container to be delegated the handling of authentication for the WordPress site *(as opposed to the WordPress container itself bearing the responsibility for authentication by extending the underlying image to include an SP package, like [Apache mod-shib](https://shibboleth.atlassian.net/wiki/spaces/SP3/pages/2065335062/Apache))*. The SP service is configured to communicate with an Identity Provider (IDP) using SAML.

*NOTE: The shibsp service...*

- *Is an alternative to the [Apache mod-shib](https://shibboleth.atlassian.net/wiki/spaces/SP3/pages/2065335062/Apache) plugin that would otherwise be built into the underlying WordPress docker image with an internal [configuration](https://github.com/bu-ist/apache-wordpress/blob/prod/conf.d/shib.sp.conf).*
- *Intended to be used by merging with another Docker Compose file, and NOT run on its own.*

### Build underlying images:

1. If the baseline image has not already been built:

   ```
   # From the project root:
   
   docker compose \
     -f master.yml \
     -f wordpress-baseline/baseline.yml \
     build wordpress
   ```

2. If the build image has not already been built:

   ```
   # From the project root:
   
   docker compose \
     -f master.yml \
     -f wordpress-baseline/baseline.yml \
     -f wordpress-bu/wp-build/build.yml \
     build wordpress
   ```



### Environment:

1. Append to your hosts file an entry that matches the bu.edu subdomain you will be using *(on windows, `C:\Windows\System32\drivers\etc\hosts`)*:

   ```
   127.0.0.1	dev.kualitest.research.bu.edu
   ```

2. The following variables are defined in the environment for `shibsp.yml`. Adjust these where necessary. Some of them extract values *(or default values)* from the shell that docker compose is running in and originate from the [`.env`](https://docs.docker.com/compose/environment-variables/set-environment-variables/#substitute-with-an-env-file) file at the root of the project.

   - **DOCKER_SP_PORT**: This is the port the `shibsp` container will listen on *(default 5000).*

   - **ENTITY_ID**: The SP identifier known to the IDP *(Example:  https://.kualitest.research.bu.edu/shibboleth")*.

   - **IDP_CERT**: This is the `<ds:X509Certificate>` element value for the IDP certificate. It is publicly posted at the IDP at a URL like "https://shib-test.bu.edu/idp/shibboleth".

   - **ENTRY_POINT**: The entry point, aka IDP address of shibboleth *(Example: https://shib-test.bu.edu/idp/profile/SAML2/Redirect/SSO)*.

   - **LOGOUT_URL**: The logout URL used by the IDP *(Example: https://shib.bu.edu/idp/logout.jsp)*.

   - **SAML_CERT**: The SAML certificate item of your service provider metadata. This is the public part of the public/private key pair used when your app was registered with the IDP - the public part being given to the IDP administrator.

   - **SAML_PK**: The private key item of your service provider metadata. This is the private part of the public/private key pair used when your app was registered with the IDP - the private part being kept securely by you.

   - **DOCKER_APP_HOST**: The host name the WordPress container will be visible to the `shibsp` container as over the docker network bridge. Unless explicitly overridden, this will be the name of the service defined in the docker compose file *(Example: "wordpress")*.



### Running the application:

Use one of two ways:

1. Assumes a cloud-based s3 proxy sigv4 signing service:

   ```
   # From the project root:
   
   docker compose \
     -f master.yml \
     -f wordpress-baseline/baseline.yml \
     -f wordpress-bu/wp-build/build.yml \
     -f wordpress-bu/wp-auth/shibsp/shibsp.yml \
     up
   ```
   
2. Add a local container for the s3 proxy sigv4 signing service:
   *(NOTE: This requires entering values for the "S3_UPLOADS_" in the .env file.)*

   ```
   # From the project root:
   
   docker compose \
     -f master.yml \
     -f wordpress-baseline/baseline.yml \
     -f wordpress-bu/wp-build/build.yml \
     -f wordpress-bu/wp-s3proxy/s3proxy.yml \
     -f wordpress-bu/wp-auth/shibsp/shibsp.yml \
     up
   ```

Visit the admin page at the server name specified earlier, IE: https://dev.kualitest.research.bu.edu/wp-admin/
Your first browser visit should trigger the wordpress wp-config completion questions.
You will be asked to supply the database connection details and your default site name.

Assuming there is a bucket asset with a URI of:

```
s3://wordpress-protected-s3-assets-dev-assets/original_media/jaydub-bulb.cms-devl.bu.edu/admissions/files/2018/09/cuba-abroad-banner-compressed.jpg
```

You should also be able to see that asset in either of two ways: 

1. Through WordPress:
   https://dev.kualitest.research.bu.edu/admissions/files/2018/09/cuba-abroad-banner-compressed.jpg
2. Through the s3proxy container directly *(if running the signing proxy locally)*:
   http://dev.kualitest.research.bu.edu:8080/jaydub-bulb.cms-devl.bu.edu/admissions/files/2018/09/cuba-abroad-banner-compressed.jpg


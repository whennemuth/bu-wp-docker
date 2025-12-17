# Mod-shib SP *(Service Provider)*

This [compose application model](https://docs.docker.com/compose/intro/compose-application-model/) defines a Shibboleth Service Provider (SP) docker image build to:

- "Mutate" the underlying WordPress docker image by installing the the [Apache mod-shib](https://shibboleth.atlassian.net/wiki/spaces/SP3/pages/2065335062/Apache) plugin on top of it.
- Merge extra environment variables on top of the WordPress service configuration for the mod-shib plugin.

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

   

### Environment

**Shibboleth configuration**
To run any application that carries out its own authentication with the Boston University Shibboleth IDP, you must use some keys and metadata that are part of a mutual configuration between your app and the IDP that enable your app to be the  Shibboleth SP in that relationship and be recognized by the IDP. This is usually done through [a ticket with BU TechWeb](https://www.bu.edu/tech/services/security/iam/authentication/shibboleth/service-provider-checklist/). 
You can also "piggy-back" on another application that has already gone through this process by "borrowing" its Shibboleth metadata and keys, as long as the domain specified with the Shibboleth IDP for that application is a wildcard domain, and you pick a subdomain for the WordPress app that is not already in use. The Kuali testing environment wildcard domain, `*.kualitest.research.bu.edu`, is serving that purpose for now as its keys and metadata are handy - and examples below assume it.

1. Append to your hosts file an entry that matches the bu.edu subdomain you will be using *(on windows, `C:\Windows\System32\drivers\etc\hosts`)*:

   ```
   127.0.0.1	dev.kualitest.research.bu.edu
   ```

2. In the environment section in the`"modshib.yml"` file, are defined some variables, some of which are specific to "stealing" a spot with the `kualitest` subdomain for shibboleth needs. Make sure these are present in the [`.env`](https://docs.docker.com/compose/environment-variables/set-environment-variables/#substitute-with-an-env-file) file at the root of the project.

   - **HTTP_HOST**: This is one of the standard apache ["HTTP_" variables](https://httpd.apache.org/docs/2.4/expr.html#vars). Make sure this exists in the [`.env`](https://docs.docker.com/compose/environment-variables/set-environment-variables/#substitute-with-an-env-file) file at the root of the project as `"HOST_NAME=value"`, *(Example: "dev.kualitest.research.bu.edu")*.
   - **SP_ENTITY_ID**: This is the value used to set the `ApplicationDefaults.entityID` attribute in the shibboleth plugin configuration file.
   - **IDP_ENTITY_ID**: This is the value used to set the `ApplicationDefaults.Sessions.SSO.entityID` attribute in the shibboleth plugin configuration file. It also corresponds to the publicly available URL to retrieve the entity descriptor document for the IDP where the public X509Certificate would be obtained.
   - **SHIB_SP_KEY**: The private key item of your service provider metadata. This is the private part of the public/private key pair used when your app was registered with the Shibboleth IDP - the private part being kept securely by you. Make sure this exists in the [`.env`](https://docs.docker.com/compose/environment-variables/set-environment-variables/#substitute-with-an-env-file) file at the root of the project as `"SAML_PK=value"`.
   - **SHIB_SP_CERT**: The SAML certificate item of your service provider metadata. This is the public part of the public/private key pair used when your app was registered with the Shibboleth IDP - the public part being given to the IDP administrator. Make sure this exists in the [`.env`](https://docs.docker.com/compose/environment-variables/set-environment-variables/#substitute-with-an-env-file) file at the root of the project as `"SAML_CERT=value"`.



### Running the application

Use one of two ways:

1. Assumes a cloud-based s3 proxy sigv4 signing service:

  ```
  # From the project root:
  
  docker compose -d \
    -f master.yml \
    -f wordpress-baseline/baseline.yml \
    -f wordpress-bu/wp-build/build.yml \
    -f wordpress-bu/wp-auth/modshib/modshib.yml \
    up
  ```

2. Add a local container for the s3 proxy sigv4 signing service:
  *(NOTE: This requires entering values for the "S3_UPLOADS_" in the .env file.)*

  ```
  # From the project root:
  
  docker compose -d \
    -f master.yml \
    -f wordpress-baseline/baseline.yml \
    -f wordpress-bu/wp-build/build.yml \
    -f wordpress-bu/wp-s3proxy/s3proxy.yml \
    -f wordpress-bu/wp-auth/modshib/modshib.yml \
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


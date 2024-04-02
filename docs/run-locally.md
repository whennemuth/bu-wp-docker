# Run locally

1. Append to your hosts file an entry that matches the bu.edu subdomain you will be using *(on windows, `C:\Windows\System32\drivers\etc\hosts`).*
   For example, a kuali wildcard subdomain `*.kualitest.research.bu.edu` was "borrowed" for some local testing, and so the corresponding hosts file entry I made was:

   ```
   127.0.0.1	dev.kualitest.research.bu.edu
   ```

2. Modify the environment section in the`"compose-baseline.yml"` file.
   This file exists with example values.

   - **SERVER_NAME**: The same value put in your hosts file from earlier. This value will be used by the apache virtual host configuration `"ServerName"` directive.
   - **TZ**: The time zone you want the containerized apache service to run with.

3. Modify the environment section in the `"docker-compose.yml"` file.

   - **S3PROXY_HOST**: This is the publicly addressable host name for a sigv4 signing service stack in aws, or alternatively the docker-compose network bridge and port for an s3proxy service container running as a sidecar. It is what apache will target for requests to retrieve assets like images and files (stored in an s3 bucket).  
     Examples: 
     - Cloud-based s3proxy:
       `https://s3proxy.kualitest.research.bu.edu/` 
     - Proxy running in local container *(where "s3proxy" is the name of the docker compose service)*:
       `http://s3proxy:8080/`
   - **FORWARDED_FOR_HOST:** Include this value to indicate the container is NOT for a multisite wordpress installation. Set it to the value of the single site that wordpress will host. It is this value that will be issued as the `"X-Forwarded-Host"` header value in http requests proxied to the s3 object lambda access point for assets by apache. Example: `"jaydub-bulb.cms-devl.bu.edu"`*(NOTE: Multisite not currently supported, coming soon)*.

4. Add the following entries to the [`.env`](https://docs.docker.com/compose/environment-variables/set-environment-variables/#substitute-with-an-env-file) file at the root of the project with secrets and environment variables for the container:
   The values placed in this file are passed into the container through environment variables, including `WORDPRESS_CONFIG_EXTRA`  *(SEE: ["Inject configuration using environment variable #142"](https://github.com/docker-library/wordpress/pull/142)):

   ```
   # ----------------------------------------
   #     Runtime Env vars and secrets:
   # ----------------------------------------
   # For windows users
   COMPOSE_CONVERT_WINDOWS_PATHS=true
   
   # Database password (defaults to "password")
   WORDPRESS_DB_PASSWORD=[value]
   
   # Object lambda access point (OLAP) details for s3 proxying
   OLAP=wordpress-protected-s3-assets-jaydub-olap
   OLAP_ACCT_NBR=770203350335
   OLAP_REGION=us-east-1
   
   # Credentials for OLAP access
   S3_UPLOADS_REGION=us-east-1
   S3_UPLOADS_SECRET_ACCESS_KEY=[value]
   S3_UPLOADS_ACCESS_KEY_ID=[value]
   
   SHIB_DOMAIN=shib-test.bu.edu   
   SHIB_SP_CERT="-----BEGIN CERTIFICATE-----
   MIIEGzCCAoOgAwIBAgIJAPhkIj1CZ3z3MA0GCSqGSIb3DQEBCwUAMCcxJTAjBgNV
   BAMTHGlwLTEwLTU3LTIzNy0yMS5lYzIuaW50ZXJuYWwwHhcNMTYwODA4MDQyNzE4
   ...
   -----END CERTIFICATE-----"
   SHIB_SP_KEY="-----BEGIN PRIVATE KEY-----
   MIIG/gIBADANBgkqhkiG9w0BAQEFAASCBugwggbkAgEAAoIBgQDLQEgmPeVMBas1
   50ujt9qPzpch1W9cae5KCmr2BBzq+koNSZNzLTVUN4bl4ZeZrtCeJ7WBJN6Uztva
   ...
   -----END PRIVATE KEY-----"
   
   # miscellaneous
   ACCESS_RULES_TABLE=[value]
   
   ```

5. Run the application *(use one of two ways)* :

   - Assumes a cloud-based s3 proxy sigv4 signing service:

      ```
      docker compose up -d
      ```

   - Add a local container for the s3 proxy sigv4 signing service:
      *(NOTE: This requires entering values for the "S3_UPLOADS_" in the .env file.)*

      ```
      docker compose -f compose-s3proxy.yml up -d
      ```

   Visit the admin page at the server name specified earlier, IE: https://dev.kualitest.research.bu.edu/wp-admin/
   Your first browser visit should trigger the wordpress wp-config completion questions.
   You will be asked to supply the database connection details and your default site name.

   Assuming there is a bucket asset with a URI of:

   ```
   s3://wordpress-protected-s3-assets-dev-assets/original_media/jaydub-bulb.cms-devl.bu.edu/admissions/files/2018/09/cuba-abroad-banner-compressed.jpg
   ```

   You should also be able to see that asset in either of two ways: 

   1. Through wordpress:
      https://dev.kualitest.research.bu.edu/admissions/files/2018/09/cuba-abroad-banner-compressed.jpg
   2. Through the s3proxy container directly *(if running the signing proxy locally)*:
      http://dev.kualitest.research.bu.edu:8080/jaydub-bulb.cms-devl.bu.edu/admissions/files/2018/09/cuba-abroad-banner-compressed.jpg

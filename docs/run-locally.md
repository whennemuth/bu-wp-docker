# Run locally

1. The container will be running apache that has the shibboleth service provider plugin installed.
   This plugin will need a certificate and key file placed in the `wordpress-baseline` subdirectory with the names `"sp-cert.pem"` and `"sp-key.pem"` respectively. These two files will be mounted to the container and are used to authenticate to the BU shibboleth identity provider. These keys correspond to a subdomain of bu.edu that is known to the BU shibboleth IDP.

2. Append to your hosts file an entry that matches the bu.edu subdomain you will be using.
   For example, a kuali wildcard subdomain `*.kualitest.research.bu.edu` was "borrowed" for some local testing, and so the corresponding hosts file entry I made was:

   ```
   127.0.0.1	dev.kualitest.research.bu.edu
   ```

3. Modify the environment section in the`"docker-compose.yml"` file.
   This file exists with example values, some of which are specific to "stealing" a spot with the kualitest subdomain for shibboleth needs.

   - **SERVER_NAME**: The same value put in your hosts file from earlier. This value will be used by the apache virtual host configuration `"ServerName"` directive.
   - **SP_ENTITY_ID**: This is the value used to set the `ApplicationDefaults.entityID` attribute in the shibboleth plugin configuration file.
   - **IDP_ENTITY_ID**: This is the value used to set the `ApplicationDefaults.Sessions.SSO.entityID` attribute in the shibboleth plugin configuration file.
   - **SHIB_SP_KEY**: Should be `"sp-key.pem"`, per the earlier step.
   - **SHIB_SP_CERT**: Should be `"sp-cert.pem"`, per the earlier step.
   - **TZ**: The time zone you want the containerized apache service to run with.

4. Modify the environment section in the `"docker-compose-override.yml"` file.

   - **S3PROXY_HOST**: This is the publicly addressable host name for a sigv4 signing service stack in aws. It is what apache will target for requests to retrieve assets like images and files (stored in an s3 bucket).
   - **FORWARDED_FOR_HOST:** Include this value to indicate the container is NOT for a multisite wordpress installation. Set it to the value of the single site that wordpress will host. It is this value that will be issued as the `"X-Forwarded-Host"` header value in http requests proxied to the s3 object lambda access point for assets by apache. Example: `"jaydub-bulb.cms-devl.bu.edu"`*(NOTE: Multisite not currently supported, coming soon)*.

5. Create a `.env` file with secrets:
   The secrets placed in this file are passed into the container through the `WORDPRESS_CONFIG_EXTRA` environment variable *(SEE: ["Inject configuration using environment variable #142"](https://github.com/docker-library/wordpress/pull/142))*. This file should be placed at the root of the project and contain the following with actual values inserted:

   ```
   # For windows users
   COMPOSE_CONVERT_WINDOWS_PATHS=true
   
   # Mysql db creds
   DB_PASSWORD=[value]
   
   # Wordpress Authentication Unique Keys and Salts
   AUTH_KEY=[value]
   SECURE_AUTH_KEY=[value]
   LOGGED_IN_KEY=[value]
   NONCE_KEY=[value]
   AUTH_SALT=[value]
   SECURE_AUTH_SALT=[value]
   LOGGED_IN_SALT=[value]
   NONCE_SALT=[value]
   
   ```

6. Run the application:

   ```
   docker compose up -d
   ```

   Visit the admin page at the server name specified earlier, IE: https://dev.kualitest.research.bu.edu/wp-admin/
   Your first browser visit should trigger the wordpress wp-config completion questions.
   You will be asked to supply the database connection details and your default site name.

   You should also be able to see assets: https://dev.kualitest.research.bu.edu/admissions/files/2018/09/comm-ave-smaller-compressed.jpg
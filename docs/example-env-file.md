### Environment variable settings

Create a [`.env`](https://docs.docker.com/compose/environment-variables/set-environment-variables/#substitute-with-an-env-file) file at the root of the project and adjust and/or comment out values as described in the corresponding readme docs: [baseline](../wordpress-baseline/README.md), [build](../wordpress-bu/wp-build/README.md), [s3proxy](../wordpress-bu/wp-s3proxy/README.md), [shibsp](../wordpress-bu/wp-auth/shibsp/README.md), and [modshib](../wordpress-bu/wp-auth/modshib/README.md)

```
# ----------------------------------------
#          Build Args:
# ----------------------------------------
DOCKER_REGISTRY="037860335094.dkr.ecr.us-east-2.amazonaws.com"
DOCKER_WORDPRESS_REPO=bu-wordpress-build
DOCKER_WORDPRESS_TAG=devl.jaydub-bulb
GIT_USER=BUWebTeam
GIT_PAT=[Personal access token]
MANIFEST_INI_FILE=wp-manifests/devl/jaydub-bulb.ini
REPOS='responsive-framework-2-x, bu-cms, bu-sustainability, query-monitor, s3-uploads-bu, bu-media-s3, bu-access-control, weblogin-plugin, bu_user_management, wp-multi-network, bu-core, bu-custom-css, bu-includes, bu-js-lib'

# ----------------------------------------
#     Runtime Env vars and secrets:
# ----------------------------------------
# For windows users
COMPOSE_CONVERT_WINDOWS_PATHS=true

# Password of root user for db container
DB_ROOT_PASSWORD=rootpassword

# Official Docker WordPress environment variables 
# (SEE: https://github.com/docker-library/docs/tree/master/wordpress#how-to-use-this-image)
WORDPRESS_DB_HOST=db:3306
WORDPRESS_DB_USER=wordpress
WORDPRESS_DB_PASSWORD=password
WORDPRESS_DB_NAME=wordpress
WORDPRESS_DEBUG=true
WP_CLI_ALLOW_ROOT=true

# Object lambda access point (OLAP) details for s3 proxying
OLAP=wordpress-protected-s3-assets-dev-olap
OLAP_ACCT_NBR=037860335094
OLAP_REGION=us-east-2

# Credentials for OLAP access
S3_UPLOADS_ACCESS_KEY_ID=[access key ID]
S3_UPLOADS_SECRET_ACCESS_KEY=[secret access key]
S3_UPLOADS_REGION=us-east-2

# Certs, secrets, and other properties for saml sp service or mod-shib plugin
# AWS_PROFILE="bu"
HOST_NAME="dev.kualitest.research.bu.edu"
DOCKER_SP_PORT=5000
ENTITY_ID="https://*.kualitest.research.bu.edu/shibboleth"
IDP_ENTITY_ID="https://shib-test.bu.edu/idp/shibboleth"
IDP_CERT=[idp certificate, get from IDP_ENTITY_ID URL]
ENTRY_POINT="https://shib-test.bu.edu/idp/profile/SAML2/Redirect/SSO"
LOGOUT_URL="https://shib-test.bu.edu/idp/logout.jsp"
SAML_DOMAIN="shib-test.bu.edu"
SAML_CERT="-----BEGIN CERTIFICATE-----
MIIEGzCCAoOgAwIBAgIJAPhkIj1CZ3z3MA0GCSqGSIb3DQEBCwUAMCcxJTAjBgNV
[more lines...]
hWzI6WfbTwUPOSI66of8qf3TUKUP2MCYcSLSX14j9GOlRDo3Y+ygUPse0O2rcIw=
-----END CERTIFICATE-----"
SAML_PK="-----BEGIN PRIVATE KEY-----
MIIG/gIBADANBgkqhkiG9w0BAQEFAASCBugwggbkAgEAAoIBgQDLQEgmPeVMBas1
[more lines...]
BAR+kqbJ6zdECHKKu6tIRS6XhkWA79bNs62vAZbHtOFHnV7aNQ2pH8g3bHhUtx4i
7a0hlVMHwZr5xlbJjxiHMvFF
-----END PRIVATE KEY-----"

# miscellaneous
ACCESS_RULES_TABLE=[value]

```


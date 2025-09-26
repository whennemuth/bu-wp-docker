# How to Build and Run the WordPress Container

This guide will help you set up and run the project from a fresh clone of the repository. Follow these steps to get started:

## Setup prerequisites
- Get a personal access token (PAT) from GitHub with appropriate permissions to access the repositories: here is a guide on [creating a PAT](https://dev.to/warnerbell/how-to-generate-a-github-personal-access-token-pat-1bg5)
- Set up an entry in /etc/hosts for the local container (replace "username" with your username)
    - Example for macOS or Linux /etc/hosts entry:
        ```
        127.0.0.1   username.local
        ```
        You can have multiple entries for different environments (pretty much any hostname should work). With the S3 integration, the location of the media library in the bucket will reflect the hostname you use.

    - macOS commands to edit /etc/hosts and flush the DNS cache:
        ```bash
        sudo nano /etc/hosts
        dscacheutil -flushcache
        ```
- Get a .env file with the right environment variables, with S3 access key and shibboleth keys; there is an example .env file in `.env.example`, or you can ask a team member for a copy of a working .env file.

## Build or pull the images

To build the images locally, run:

```bash
npm run build
```
or click the build button in the NPM Scripts tab in VSCode.

Alternatively, you can pull the images from AWS ECR, *we have not yet finalized a private repo yet, so this part is incomplete*:

```bash
TDOD add ECR pull commands
```
## Run the containers

```bash
npm run start
```
or click the start button in the NPM Scripts tab in VSCode.

( Check out this article on the NPM Scripts tab in VSCode:
https://www.luisllamas.es/en/how-to-use-vscode-with-npm/ )

Your WordPress site will be available at https://username.local (or whatever hostname you set in the .env file and /etc/hosts).

The https is set up with a self-signed certificate for local development, you will need to override the browser warning.

At this point you can check the logs on the WordPress container and see how the entrypoint script initializes the configuration details in the container.

## Setup admin and content

- Get a shell on the wordpress container:
    ```bash
    npm run shell
    ```
- You can create a new user for yourself just by going the wp-admin page of your local site, you will be prompted to login with BU shibboleth, and then a user will be created for you automatically. You can also create a user manually like so (replace "username" and "username@bu.edu" with your login details):
    ```bash
    wp user create username username@bu.edu --role=administrator
    ```
- You can then make yourself a super admin like so (replace "username" with your username):
    ```bash
    wp super-admin add username@bu.edu
    ```
    Once you have created the user, you can log in to the WordPress admin at https://username.local/wp-admin

- Optional: Clone the admissions site to your local instance (replace "username.local" with your local hostname):
    ```bash
    wp site-manager snapshot-pull --source=http://www.bu.edu/admissions --destination=http://username.local/admissions
    ```

That's it you are done!

## Next steps

### Attach vscode to the container

- Go to the Containers view
- Right-click the bu-wordpress container
- Choose "Attach Visual Studio Code"

### Stop the containers

```bash
npm run stop
```
or click the stop button in the NPM Scripts tab in VSCode.

### Destroy the database and start fresh

```bash
docker volume rm bu-wp-docker_db_data
```

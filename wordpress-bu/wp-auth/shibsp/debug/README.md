# Step debugging for the shibsp container

Occasionally, you may want a detailed inspection of what the shibsp container is getting back from proxied requests to the wordpress container and how it is dealing with those responses. An alternative to log output would be to start a vscode launch configuration that attaches to the internal shibsp container process and pause execution at pre-selected breakpoints.

In order to do this, a version of the shibsp docker image is required that also packages in the source code so that it can be mapped to corresponding files in your vscode workspace. The shibsp service is based on an image comes from the [shibboleth-sp github repo](https://whennemuth@github.com/whennemuth/shibboleth-sp.git). You must use this repository to build the extended image:

1. Clone the repository:

   ```
   # From the root of the vscode workspace.
   cd ..
   git clone https://github.com/whennemuth/shibboleth-sp.git
   ```

2. Build the extended debug image:

   ```
   cd shibboleth-sp
   docker compose build
   ```

3. Build package in a `/dist` folder that includes the source code.
   *NOTE: This is a repeat of one of the steps that happens during the docker image build, and results in a dist folder in the vscode workspace that mirrors the same dist folder inside the docker image.*

   ```
   npm run build
   ```

4. Run docker compose:

   ```
   # Return to this workspace:
   cd ../bu-wp-docker
   docker compose \
       -f master.yml \
       -f wordpress-baseline/baseline.yml \
       -f wordpress-bu/wp-build/build.yml \
       -f wordpress-bu/wp-auth/shibsp/shibsp.yml \
       -f wordpress-bu/wp-auth/shibsp/debug/shibsp-debug.yml \
       up -d
   ```

5. Run the debug launch configuration:

   - From the **shibboleth-sp** vscode workspace, launch the **"attach-to-docker-sp-process"** config.
   - Place a breakpoint in **EntrypointSp.ts** or any of its imported files.

6. In your browser, visit the **shibsp** container on the port it listens on and you should see the breakpoint light up.


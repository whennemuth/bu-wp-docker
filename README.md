# Boston University Docker Image for WordPress



### Overview:

This repository comprises a series of docker compose files for producing a final docker image for running containers that host BU WordPress websites.
These containers can:

- Be run locally as part of a set of a docker-compose service suite *(Each comes with its own README file)*.
- Turn an on-premise WordPress server into a simple docker host by:
  - Moving the apache service into the container.
  - Moving away from hosting WordPress assets in local storage in favor of a service that looks up the assets dynamically in AWS S3.
  - Providing other options for authentication where the shibboleth SP client service is:
    - Assumed to be running in CloudFront@edge and will route to this apps [ALB](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html) as an origin.
    - Running locally in a separate **"[shibsp](./wordpress-bu/wp-auth/shibsp/README.md)"** container.
    - Running with apache in the WordPress container using the [Apache mod-shib](https://shibboleth.atlassian.net/wiki/spaces/SP3/pages/2065335062/Apache) plugin *(the traditional option)*. See **"[modshib](./wordpress-bu/wp-auth/modshib/README.md)"**.

- Run as part of an ECS cluster, where each of the services defined by the compose files can be represented naturally as a corresponding [ECS Service](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html) in an [EC2](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch-type-ec2.html) or [Fargate](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch-type-fargate.html) launch type.

By containerizing WordPress, and moving content storage and authentication out into their own services, we get the benefit of being able make it cloud ready and able to fit with all the infrastructure and orchestration services that exist there. Also, WordPress itself becomes a simpler entity to deal with as a developer with the content and authentication service extracted out as their own separate services. 

At this time, the build is based on the standard docker image for WordPress, version 5.4.2 with php version 7.4 and apache:

-  [Dockerhub: wordpress:5.4.2-php7.4-apache](https://hub.docker.com/layers/library/wordpress/5.4.2-php7.4-apache/images/sha256-592909e2dfca9b4c0a776d4e76023679b02d5df96bb751481f4f5d53ccfe1f02?context=explore)
- [Github: wordpress/php7.4/apache:2e0d223](https://github.com/docker-library/wordpress/tree/2e0d223a67a645307559e05f3fa4a154b2bbb983/php7.4/apache)



### How this project is organized:

The services provided by this project follow a specific logical sequence and hierarchy:

**1) [baseline](./wordpress-baseline/README.md) > 2) [build](./wordpress-bu/wp-build/README.md) > 3) [s3proxy](./wordpress-bu/wp-s3proxy/README.md)** *(optional)* **> 4) ([shibsp](./wordpress-bu/wp-auth/shibsp/README.md) or [modshib](./wordpress-bu/wp-auth/modshib/README.md))**

This is explained in detail in the **[How this project is organized readme](./docs/project-organization.md)**.



### Prerequisites:

- [Docker](https://docs.docker.com/get-docker/)
- [Docker-compose](https://docs.docker.com/compose/install/)



### Steps:

1. **Environment**
   
   Create a [`.env`](https://docs.docker.com/compose/environment-variables/set-environment-variables/#substitute-with-an-env-file) file at the root of the project. Reference the **[example readme](./docs/example-env-file.md)**. 

1. **Build the baseline image**
   
   Follow the directions in the **[baseline readme](./wordpress-baseline/README.md)**.
   
1. **Build the "build" image:**
   
   Follow the directions in the **[build readme](./wordpress-bu/wp-build/README.md)**.

1. **Publish the "build" image:**
   
   Directions to publish the build image can also be found in the **[build readme](./wordpress-bu/wp-build/README.md)**.

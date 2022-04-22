# Forest Watcher Service Template

This repository can be used as code template for new forest watcher services.
It will deploy a dockerized application on AWS fargate and expose endpoints under the public URL

- fw-api.globalforestwatch.org
- staging-fw-api.globalforestwatch.org
- dev-fw-api.globalforestwatch.org

for production, staging and dev environments correspondingly.

The application itself can be written in any language. Only requirement is that it must provide http/ rest endpoints.
Application code may be located in the `app` or `src` folder. The Dockerfile should always be place at the root of the repository.

> All items marked "`// TODO`" should be amended to match the new project prior to pushing to a deployment branch (dev, staging, production). Amend these in `main.tf`, `variables.tf` and the `terraform-{env}.tfvars` file for each environment.


## Terraform

The provided terraform template will
- build a docker image based on the Dockerfile
- upload the docker image to AWS ECR
- create a new Fargate service in the Forest Watcher AWS ECS cluster using the docker image
- create a new target group for the Fargate service and link it to the Forest Watcher Application Load balancer

The Fargate service will have access to
- Document DB cluster
- Redis Cluster
- S3 Bucket

Relevant endpoints and secrets to access those services are available as environment variables inside the container.

The Forest Watcher Application Load Balancer can be linked to multiple services.
Each service must have a unique path pattern. Path patterns for a given service must be specified in the 
lb_listener_rule inputs inside the fargate_autoscaling in the terraform template.
The value of `health_check_path` must match a path_pattern. 

An example for a path patterns is

`path_pattern = ["/v1/fw_forms/healthcheck", "/v1/forms*", "/v1/questionnaire*]`

This will route all requests which start with `/v1/forms` or `/v1/questionnaire` to the current service, as well as the specific path `/v1/fw_forms/healthcheck`.
The health_check_path specifies which route the load balancer will perform health checks on. This path must return a HTTP `200` or `202` status code to inform the load balancer the service is healthy. Any other code will be treat the service as unhealthy.
- For the dev and staging environments, each application's routes will also need to be added to the API gateway to be successfully routed once deployed.

The Fargate service is currently configure to run with 0.25 cVPU and 512 MB of RAM. Autoscaling is enabled.
To change configurations, you can update default values for all environments in `/terraform/variables.tf`.
To change configurations for different environments separately, override default values in `/terraform/vars/terraform-{env}.tfvars`.

## Databases

The services currently have access to a AWS DocumentDB cluster (MongoDB 3.6) and a AWS ElasticCache Cluster (Redis 6).
Both database clusters are managed via the GFW core infrastructure repository. 
For the case that is become necessary to scale out one of the clusters, please contact the GFW engineering team.

To directly connect to the databases you can create a tunnel via a bastion host using SSH.
You will need to add your public SSH key to the bastion host and add your IP address to the security group to have access.
Please provide this information to the GFW engineering team for setup.

Example:

```bash
# ADD keyfile to chain
ssh-add ~/.ssh/private_key.pem >/dev/null 2>&1

# Create a tunnel to document DB
ssh -N -L 27017:<documentdb cluster dns>:27017 ec2-user@<bastion host ip>
```
You will now be able to connect to the document db cluster via `localhost:27017`

## Git branch naming convention and CI/CD

The branches

- production
- staging
- dev

Represent infrastructure deployment in the according environment accounts on AWS. 
Github actions workflows will apply infrastructure changes to these environments automatically, 
when ever a commit is pushed to one of the branches.

Pull requests against the branches will trigger a terraform plan action, and the planned infrastructure changes will be displayed first.
It is highly recommended to always work in a feature branch and to make a pull request again the `dev` branch first.

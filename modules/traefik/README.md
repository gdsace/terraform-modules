# Traefik Module

This module provisions the [Traefik](https://traefik.io/) reverse proxy that automatically creates
routes from an ELB to your applications through Consul Service Catalog.

You might want to familiarise yourself with some [concepts](https://docs.traefik.io/basics/)
from Traefik before continuing.

## Integration with `Core` module

This module is integrated with the `core` module to enable you to use both in conjunction
seamlessly.

## Pre-requisites

Make sure you have a certificate (preferably Wildcard) in ACM to provide to this module to use in
front of the load balancer as the default certificate.

If you have additional certificates you would like to attach to the load balancer, you can provision
them with the
[`aws_lb_listener_certificate`](https://www.terraform.io/docs/providers/aws/r/lb_listener_certificate.html)
resource.

## Applying the Module

If you have enabled ACL for your Nomad cluster, you will need to provide the token to the
[Nomad provider](https://www.terraform.io/docs/providers/nomad/index.html).

## Traefik Entrypoints

This module creates two entrypoints for your applications to use:

- `http`: External endpoint for all applications to be accessed via the internet.
- `internal`: Internal endpoint that is only accessible from within your VPC.

## Writing a Job for Traefik

Traefik knows when to create routes based on the
[tags](https://www.consul.io/docs/agent/services.html) on your Consul services. You can see the full
list of options that Traefik recognises on the
[documentation](https://docs.traefik.io/configuration/backends/consulcatalog/).

The example Nomad jobspec below shows how one might want to deploy
[hashi-ui](https://github.com/jippi/hashi-ui) on the internal entrypoint for your internal users
only. Most importantly, take note of the `tags` key of the `service` stanza. You must also
remember to create DNS records to point to the ELB provisioned by this module.

```hcl
job "hashi-ui" {
  datacenters = ["ap-southeast-1a","ap-southeast-1b","ap-southeast-1c"]
  region      = "ap-southeast-1"
  type        = "service"

  update {
    max_parallel = 1
    min_healthy_time = "30s"
    healthy_deadline = "10m"
    auto_revert = true
  }

  group "server" {
    count = 2

    task "hashi-ui" {
      driver = "docker"

      config {
        image = "jippi/hashi-ui:v0.25.0"
        port_map {
          http = 3000
        }

        dns_servers = ["169.254.1.1"]
      }

      service {
        port = "http"

        check {
          type     = "http"
          path     = "/"
          interval = "10s"
          timeout  = "2s"
        }

        tags = [
          "traefik.enable=true",
          "traefik.frontend.rule=Host:hashi-ui.example.com",
          "traefik.frontend.entryPoints=internal",
          "traefik.frontend.headers.SSLRedirect=true",
          "traefik.frontend.headers.SSLProxyHeaders=X-Forwarded-Proto:https",
          "traefik.frontend.headers.STSSeconds=315360000",
          "traefik.frontend.headers.frameDeny=true"
        ]
      }

      env {
        NOMAD_ENABLE = 1
        NOMAD_ADDR  = "http://http.nomad.service.consul:4646"
        NOMAD_READ_ONLY = "true"

        CONSUL_ENABLE = 1
        CONSUL_ADDR = "consul.service.consul:8500"
      }

      resources {
        cpu    = 500
        memory = 512

        network {
          mbits = 5

          port  "http"{}
        }
      }
    }
  }
}
```

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| consul | n/a |
| nomad | n/a |
| template | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| access\_log\_enable | Enable access logging | `bool` | `true` | no |
| access\_log\_json | Log access in JSON | `bool` | `false` | no |
| additional\_docker\_config | Additional HCL to be added to the configuration for the Docker driver. Refer to the template Jobspec for what is already defined | `string` | `""` | no |
| cpu | CPU in MHz to allocate to each job | `number` | `500` | no |
| deregistration\_delay | Time before an unhealthy Elastic Load Balancer target becomes removed | `number` | `60` | no |
| elb\_ssl\_policy | ELB SSL policy for HTTPs listeners. See https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html | `string` | `"ELBSecurityPolicy-TLS-1-2-2017-01"` | no |
| external\_certificate\_arn | ARN for the certificate to use for the external LB | `any` | n/a | yes |
| external\_idle\_timeout | Number of seconds that a connection across the external lb can idle before it is terminated | `number` | `60` | no |
| external\_lb\_incoming\_cidr | A list of CIDR-formatted IP address ranges from which the external Load balancer is allowed to listen to | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| external\_lb\_name | Name of the external Nomad load balancer | `string` | `"traefik-external"` | no |
| external\_nomad\_clients\_asg | The Nomad Clients Autoscaling group to attach the external load balancer to | `any` | n/a | yes |
| healthy\_threshold | The number of consecutive health checks successes required before considering an unhealthy target healthy (2-10). | `number` | `2` | no |
| internal\_certificate\_arn | ARN for the certificate to use for the internal LB | `any` | n/a | yes |
| internal\_idle\_timeout | Number of seconds that a connection across the internal lb can idle before it is terminated | `number` | `60` | no |
| internal\_lb\_incoming\_cidr | A list of CIDR-formatted IP address ranges from which the internal load balancer is allowed to listen to | `list(string)` | `[]` | no |
| internal\_lb\_name | Name of the external Nomad load balancer | `string` | `"traefik-internal"` | no |
| internal\_nomad\_clients\_asg | The Nomad Clients Autoscaling group to attach the internal load balancer to | `any` | n/a | yes |
| interval | The approximate amount of time, in seconds, between health checks of an individual target. Minimum value 5 seconds, Maximum value 300 seconds. | `number` | `30` | no |
| lb\_external\_access\_log | Log External Traefik LB access to a S3 bucket | `bool` | `false` | no |
| lb\_external\_access\_log\_bucket | S3 bucket to log access to the External Traefik LB to | `any` | n/a | yes |
| lb\_external\_access\_log\_prefix | Prefix in the S3 bucket to log External Traefik LB access | `string` | `""` | no |
| lb\_external\_subnets | List of subnets to deploy the external LB to | `list(string)` | n/a | yes |
| lb\_internal\_access\_log | Log internal Traefik LB access to a S3 bucket | `bool` | `false` | no |
| lb\_internal\_access\_log\_bucket | S3 bucket to log access to the internal Traefik LB to | `any` | n/a | yes |
| lb\_internal\_access\_log\_prefix | Prefix in the S3 bucket to log internal Traefik LB access | `string` | `""` | no |
| lb\_internal\_subnets | List of subnets to deploy the internal LB to | `list(string)` | n/a | yes |
| log\_json | Log in JSON format | `bool` | `false` | no |
| mbits | Network bandwidth in Mbits to allocate to each job | `number` | `5` | no |
| memory | Memory in MB to allocate to each job | `number` | `512` | no |
| nomad\_clients\_external\_security\_group | The security group of the nomad clients that the external LB will be able to connect to | `any` | n/a | yes |
| nomad\_clients\_internal\_security\_group | The security group of the nomad clients that the internal LB will be able to connect to | `any` | n/a | yes |
| nomad\_clients\_node\_class | Job constraint Nomad Client Node Class name | `any` | n/a | yes |
| route53\_zone | Zone for Route 53 records | `any` | n/a | yes |
| tags | A map of tags to add to all resources | `map` | <pre>{<br>  "Environment": "development",<br>  "Terraform": "true"<br>}</pre> | no |
| timeout | The amount of time, in seconds, during which no response means a failed health check (2-60 seconds). | `number` | `5` | no |
| traefik\_consul\_catalog\_prefix | Prefix for Consul catalog tags for Traefik | `string` | `"traefik"` | no |
| traefik\_consul\_prefix | Prefix on Consul to store Traefik configuration to | `string` | `"traefik"` | no |
| traefik\_count | Number of copies of Traefik to run | `number` | `3` | no |
| traefik\_external\_base\_domain | Domain to expose the external Traefik load balancer | `any` | n/a | yes |
| traefik\_internal\_base\_domain | Domain to expose the external Traefik load balancer | `any` | n/a | yes |
| traefik\_priority | Priority of the Nomad job for Traefik. See https://www.nomadproject.io/docs/job-specification/job.html#priority | `number` | `50` | no |
| traefik\_ui\_domain | Domain to access Traefik UI | `any` | n/a | yes |
| traefik\_version | Docker image tag of the version of Traefik to run | `string` | `"v1.7.12-alpine"` | no |
| unhealthy\_threshold | The number of consecutive health check failures required before considering a target unhealthy (2-10). | `number` | `2` | no |
| vpc\_id | ID of the VPC to deploy the LB to | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| traefik\_external\_cname | URL that applications should set a CNAME record to for Traefik reverse proxy |
| traefik\_external\_lb\_dns | URL that applications should set a CNAME or ALIAS record to the external LB directly |
| traefik\_external\_zone | The canonical hosted zone ID of the external load balancer (to be used in a Route 53 Alias record). |
| traefik\_internal\_cname | URL that applications should set a CNAME record to for Traefik reverse proxy |
| traefik\_internal\_lb\_dns | URL that applications should set a CNAME or ALIAS record to the internal LB directly |
| traefik\_internal\_zone | The canonical hosted zone ID of the internal load balancer (to be used in a Route 53 Alias record). |
| traefik\_jobspec | Nomad Jobspec for the deployed Traefik reverse proxy |
| traefik\_lb\_external\_arn | ARN of the external load balancer |
| traefik\_lb\_external\_https\_listener\_arn | ARN of the HTTPS listener for the external load balancer |
| traefik\_lb\_external\_security\_group\_id | Security group ID for Traefik external LB |
| traefik\_lb\_internal\_arn | ARN of the internal load balancer |
| traefik\_lb\_internal\_https\_listener\_arn | ARN of the HTTPS listener for the internal load balancer |
| traefik\_lb\_internal\_security\_group\_id | Security group ID for Traefik internal LB |

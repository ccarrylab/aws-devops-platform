# Fargate App Platform (Hero Project)

This project is a **production-style ECS Fargate platform**:

- Multi-AZ VPC with NAT gateway
- Internet-facing ALB + ECS Fargate service
- CloudWatch logs, alarms, and dashboard
- Optional CI/CD from GitHub Actions with OIDC

## Architecture

- `modules/network` → VPC, subnets, NAT.
- `modules/observability` → log group, alarms, dashboard.
- `modules/ecs_fargate_app` → ECS cluster, task, service, ALB, autoscaling.

## Local deployment

```bash
cd aws-devops-platform/projects/03-fargate-app-platform/terraform
terraform init
terraform apply -auto-approve
terraform output app_url

# AWS DevOps Platform

Production-ready AWS infrastructure in a single environment. Built for portfolio showcase and real projects.

**Monthly Cost: ~$400-500**

## What's Included

- EKS cluster (auto-scales 2-6 nodes)
- RDS Aurora PostgreSQL
- ElastiCache Redis
- Multi-AZ VPC
- Full security (GuardDuty, encryption, security groups)
- Monitoring and alerts
- Budget tracking

## Quick Start

```bash
# 1. Configure AWS
aws configure

# 2. Bootstrap backend
./scripts/bootstrap.sh

# 3. Deploy
cd infrastructure
terraform init
terraform plan
terraform apply
```

## Configuration

All settings in `infrastructure/variables.tf`:
- Region: us-east-1
- Alerts: cohen.carryl@gmail.com
- Budget: $600/month

**Save $32/month:** Set `single_nat_gateway = true`

## Access EKS

```bash
aws eks update-kubeconfig --name platform-eks --region us-east-1
kubectl get nodes
```

## Cost Breakdown

- EKS: $73 (control plane)
- EC2: $50-100 (2-4 spot nodes)
- RDS: $60 (db.t4g.medium)
- ElastiCache: $12 (cache.t4g.micro)
- NAT: $65 (2 AZs) or $32 (1 AZ)
- Other: $40 (ALB, CloudWatch, etc.)

## Cleanup

```bash
terraform destroy
```

## Support

Email: cohen.carryl@gmail.com

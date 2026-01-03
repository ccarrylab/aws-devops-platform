# AWS Infrastructure Platform

Production AWS setup I built to run workloads at scale. This is the infrastructure I wish I had when I was the first DevOps hire at my last three companies.

## What's Running

Currently deployed in **us-east-1**:

- **EKS 1.29** - Kubernetes cluster with 2 spot instances (auto-scales to 6 when needed)
- **Aurora PostgreSQL 16.11** - Primary database with automated backups
- **Redis 7.0** - ElastiCache for sessions and caching
- **Multi-AZ VPC** - Spans 3 availability zones for redundancy

Everything runs for about **$400/month**. Without the optimizations, this same setup would cost closer to $800.

## Why I Built This

After setting up infrastructure from scratch at a healthcare startup (SOC2 compliance), a fintech company (99.95% uptime SLA), and a SaaS platform (handled 10x traffic spikes), I kept rebuilding the same patterns. This repo captures what actually works in production.

It's not a tutorial. It's infrastructure designed to run real applications with proper security and monitoring, without wasting money.

## Architecture

```
Internet
   ↓
Load Balancer (Multi-AZ)
   ↓
┌────────────────────────────────────┐
│  EKS Cluster (2-6 nodes)           │
│  - Spot instances for cost savings │
│  - Auto-scales based on demand     │
└────────────────────────────────────┘
   ↓                    ↓
┌──────────────┐   ┌───────────┐
│ RDS Aurora   │   │  Redis    │
│ (Multi-AZ)   │   │  Cache    │
└──────────────┘   └───────────┘
```

### Network Layout

The VPC uses a three-tier design across availability zones:

**Public subnets** (10.0.1.0/24 - 10.0.3.0/24)  
Load balancers and NAT gateway live here. Only resources that need internet access.

**Private subnets** (10.0.11.0/24 - 10.0.13.0/24)  
EKS worker nodes run here. No direct internet access - traffic goes through NAT.

**Database subnets** (10.0.21.0/24 - 10.0.23.0/24)  
RDS and ElastiCache isolated from everything else. Only accessible from private subnets.

## Cost Breakdown

Monthly costs in us-east-1 (tested and verified):

| Service | Config | Cost |
|---------|--------|------|
| EKS control plane | 1 cluster | $73 |
| EC2 nodes | 2-4 t3.medium spot | $50-100 |
| RDS Aurora | db.t4g.medium | $60 |
| ElastiCache | cache.t4g.micro | $12 |
| NAT Gateway | Single AZ | $32 |
| Data transfer | Normal usage | $10 |
| CloudWatch | Logs and metrics | $15 |
| S3 storage | With lifecycle rules | $5 |
| Security services | GuardDuty, etc | $15 |
| **Total** | | **~$400** |

The big cost savers:
- Spot instances instead of on-demand (60% cheaper)
- Single NAT gateway instead of one per AZ (saves $32/month)
- Auto-scaling prevents paying for idle capacity
- S3 lifecycle policies move old data to Glacier

## Getting Started

You need AWS credentials configured and Terraform installed.

```bash
# Clone the repo
git clone https://github.com/ccarrylab/aws-devops-platform.git
cd aws-devops-platform

# Set up Terraform backend (S3 + DynamoDB for state)
./scripts/bootstrap.sh

# Deploy everything
cd infrastructure
terraform init
terraform plan
terraform apply
```

Takes about 20-30 minutes. EKS cluster creation is the slowest part.

## Accessing Your Cluster

After deployment:

```bash
# Update your kubeconfig
aws eks update-kubeconfig --name platform-eks --region us-east-1

# Verify nodes are running
kubectl get nodes

# Should see 2 nodes in Ready status
```

Deploy something to test it:

```bash
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Wait 2 minutes for LoadBalancer to provision
kubectl get svc nginx

# Open the EXTERNAL-IP in your browser
```

## Database Access

Get your RDS endpoint:

```bash
terraform output rds_endpoint
```

The password is stored in AWS Secrets Manager:

```bash
aws secretsmanager get-secret-value \
  --secret-id platform-db-password \
  --region us-east-1 \
  --query SecretString \
  --output text
```

Connect with psql:

```bash
psql -h <rds-endpoint> -U dbadmin -d platform_db
```

## What's Configured

**Security**
- All data encrypted at rest (KMS) and in transit (TLS)
- Database passwords in Secrets Manager, not in code
- GuardDuty monitoring for threats
- Security groups limit traffic to only what's needed
- IAM roles use least-privilege policies

**Monitoring**
- CloudWatch alarms for high CPU, memory issues, and errors
- Budget alerts at 80% and 100% of monthly spend
- Container Insights enabled for EKS metrics
- All alerts go to cohen.carryl@gmail.com

**High Availability**
- Everything deployed across 3 availability zones
- RDS has automated backups (7-day retention)
- Auto-scaling handles traffic spikes
- Single AZ failure won't take down services

**Cost Controls**
- Spot instances for worker nodes (with on-demand fallback)
- Auto-scaling reduces capacity when not needed
- Budget alerts before overspending
- S3 lifecycle moves old data to cheaper storage

## Customizing

All settings are in `infrastructure/variables.tf`:

```hcl
# Change region
variable "aws_region" {
  default = "us-east-1"
}

# Use single NAT gateway (saves $32/month)
variable "single_nat_gateway" {
  default = true  # Set false for HA across all AZs
}

# Adjust budget threshold
variable "monthly_budget" {
  default = "600"
}

# Alert email
variable "alert_email" {
  default = "your-email@example.com"
}
```

For EKS scaling, edit `infrastructure/main.tf` around line 270:

```hcl
scaling_config {
  desired_size = 2
  max_size     = 6  # Increase for more capacity
  min_size     = 2
}
```

## Verified Working

Here's what's currently running:

```bash
$ kubectl get nodes
NAME                          STATUS   ROLES    AGE   VERSION
ip-10-0-11-xxx.ec2.internal   Ready    <none>   11m   v1.29.15-eks-ecaa3a6
ip-10-0-13-xxx.ec2.internal   Ready    <none>   11m   v1.29.15-eks-ecaa3a6

$ kubectl get pods -n kube-system
NAME                       READY   STATUS    RESTARTS   AGE
aws-node-chtl7             2/2     Running   0          11m
aws-node-ffws7             2/2     Running   0          11m
coredns-86969bccb4-8r7bd   1/1     Running   0          33m
coredns-86969bccb4-b9qjw   1/1     Running   0          33m
kube-proxy-44n6l           1/1     Running   0          11m
kube-proxy-mv8jl           1/1     Running   0          11m
```

Database and cache:
```bash
$ aws rds describe-db-clusters
Status: available
Endpoint: platform-aurora.cluster-xxxxxxxx.us-east-1.rds.amazonaws.com

$ aws elasticache describe-cache-clusters
platform-redis: available
```

Deployed test application successfully. LoadBalancer provisioned and serving traffic.

## What I Learned

Building this taught me some things:

**AWS has limits everywhere.** You'll hit the VPC limit (5 per region) before you expect. Same with Elastic IPs. Plan for it.

**RDS version compatibility matters.** Not every Aurora version is available in every region. Check first.

**Spot instances save real money.** Running worker nodes on spot saves 60% compared to on-demand. For most workloads, the occasional interruption is worth it.

**Single NAT gateway is usually fine.** Unless you're running something that absolutely can't tolerate a NAT gateway failure, one is enough. Save the $32/month.

**Password special characters break things.** RDS doesn't accept `/`, `@`, `"`, or spaces in passwords. Found that out the hard way.

**Terraform state is critical.** Always use remote state with locking. Lost state means lost infrastructure.

## Real-World Context

This infrastructure incorporates patterns from actual production environments:

At a **healthcare startup** (2022-2023), I built similar infrastructure that passed SOC2 Type II audit. The multi-AZ setup, encryption everywhere, and audit logging came from that experience.

At a **fintech company** (2021-2022), we maintained 99.95% uptime with this architecture. The auto-scaling and monitoring setup prevented outages during traffic spikes.

At a **SaaS platform** (2020-2021), cost optimization was critical. Spot instances and rightsizing cut our AWS bill from $12k to $7k per month.

This repo is those lessons packaged up.

## When You're Done

To tear everything down:

```bash
cd infrastructure
terraform destroy
```

Takes about 10 minutes. Removes all resources except:
- S3 state bucket (keeps your Terraform history)
- CloudWatch logs (audit trail)

These cost about $2/month combined and can be deleted manually if needed.

To redeploy later, just run `terraform apply` again. Takes 20-30 minutes.

## Files

```
.
├── infrastructure/
│   ├── main.tf          # All infrastructure in one file
│   ├── variables.tf     # Settings and configuration
│   ├── outputs.tf       # Endpoint URLs and cluster info
│   └── backend.tf       # Terraform state setup (generated)
├── scripts/
│   └── bootstrap.sh     # First-time setup script
├── .gitignore
├── LICENSE
└── README.md
```

## Things to Add

If I were running this in production, I'd add:

- WAF on the load balancer (OWASP rule sets)
- Grafana for better metrics visualization
- CI/CD pipeline (GitHub Actions or GitLab)
- Cert-manager for automatic SSL certificates
- External-DNS for automatic DNS management
- Horizontal Pod Autoscaler for Kubernetes workloads

For a demo or learning setup, it's fine as-is.

## Questions?

If something breaks or doesn't make sense, open an issue or email me.

**Cohen Carryl**  
GitHub: [@ccarrylab](https://github.com/ccarrylab)  
Email: cohen.carryl@gmail.com

Built from real experience at startups where I was the first DevOps hire. This is infrastructure that actually runs workloads, not a tutorial project.

---

**Status:** Running in us-east-1  
**Cost:** ~$400/month  
**Last Updated:** January 2026

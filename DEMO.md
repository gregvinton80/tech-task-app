# Wiz Security Exercise - Demonstration Guide

## Overview

This guide walks through demonstrating the intentionally vulnerable infrastructure and the security controls that detect these issues.

## Prerequisites

- AWS Account with appropriate permissions
- GitHub account
- AWS CLI configured
- kubectl installed
- Terraform installed

## Part 1: Environment Setup (15 minutes)

### 1.1 Deploy Infrastructure

```bash
# Clone repository
git clone <your-repo-url>
cd wiz

# Deploy infrastructure with Terraform
cd terraform
terraform init
terraform plan
terraform apply

# Save outputs
terraform output -json > ../outputs.json
```

### 1.2 Configure kubectl

```bash
# Get EKS cluster name from outputs
aws eks update-kubeconfig --region us-east-1 --name wiz-exercise-eks

# Verify connection
kubectl get nodes
```

### 1.3 Deploy Application

```bash
# Build and push Docker image
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

docker build -t wiz-exercise-app .
docker tag wiz-exercise-app:latest <ecr-url>:latest
docker push <ecr-url>:latest

# Deploy to Kubernetes
kubectl apply -f k8s/

# Wait for deployment
kubectl rollout status deployment/wiz-app -n wiz-app

# Get application URL
kubectl get ingress -n wiz-app
```

## Part 2: Demonstrate Vulnerabilities (20 minutes)

### 2.1 Exposed SSH Access

```bash
# Show security group allows SSH from anywhere
aws ec2 describe-security-groups --filters "Name=group-name,Values=wiz-exercise-mongodb-sg" --query "SecurityGroups[0].IpPermissions"

# Demonstrate SSH access
MONGODB_IP=$(terraform output -raw mongodb_public_ip)
ssh ubuntu@$MONGODB_IP
```

**Expected Finding**: SSH accessible from 0.0.0.0/0

### 2.2 Excessive IAM Permissions

```bash
# Show IAM role attached to MongoDB instance
aws iam get-role-policy --role-name wiz-exercise-mongodb-ec2-role --policy-name wiz-exercise-mongodb-ec2-policy

# From MongoDB instance, demonstrate excessive permissions
ssh ubuntu@$MONGODB_IP
aws ec2 describe-instances  # Should work
aws iam list-users          # Should work (but shouldn't!)
```

**Expected Finding**: EC2 instance can perform IAM and EC2 operations

### 2.3 Public S3 Bucket

```bash
# List bucket contents publicly (no authentication)
BUCKET_NAME=$(terraform output -raw mongodb_backup_bucket)
curl https://$BUCKET_NAME.s3.amazonaws.com/

# Download backup file publicly
curl https://$BUCKET_NAME.s3.amazonaws.com/backups/<backup-file> -o backup.tar.gz
```

**Expected Finding**: Database backups publicly accessible

### 2.4 Outdated Software

```bash
# Check Ubuntu version
ssh ubuntu@$MONGODB_IP "lsb_release -a"

# Check MongoDB version
ssh ubuntu@$MONGODB_IP "mongod --version"
```

**Expected Finding**: Ubuntu 20.04 and MongoDB 4.4 (both outdated)

### 2.5 Kubernetes Cluster Admin

```bash
# Show service account has cluster-admin
kubectl get clusterrolebinding wiz-app-cluster-admin -o yaml

# From inside pod, demonstrate excessive permissions
kubectl exec -it -n wiz-app deployment/wiz-app -- sh
# Inside pod:
# Can list all secrets in all namespaces
# Can create/delete any resources
```

**Expected Finding**: Application pods have cluster-admin privileges

### 2.6 Verify wizexercise.txt in Container

```bash
# Check file exists in running container
kubectl exec -it -n wiz-app deployment/wiz-app -- cat /app/wizexercise.txt

# Or from Docker image
docker run --rm <ecr-url>:latest cat /app/wizexercise.txt
```

**Expected Output**: "Greg Vinton"

## Part 3: Security Detection (20 minutes)

### 3.1 AWS Security Hub

```bash
# Open Security Hub console
aws securityhub get-findings --filters '{"ProductName":[{"Value":"Inspector","Comparison":"EQUALS"}]}' --max-items 10
```

**Show**: Findings for all vulnerabilities

### 3.2 AWS Inspector

```bash
# Show Inspector findings
aws inspector2 list-findings --filter-criteria '{"severity":[{"comparison":"EQUALS","value":"HIGH"}]}'
```

**Show**:
- Code vulnerabilities in Go application
- Container image CVEs
- EC2 instance vulnerabilities

### 3.3 AWS Config

```bash
# Show Config rules
aws configservice describe-compliance-by-config-rule
```

**Show**: Non-compliant resources (S3 bucket, security groups, etc.)

### 3.4 CloudTrail

```bash
# Show audit logs
aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=RunInstances --max-results 5
```

**Show**: All API activity logged

### 3.5 GitHub Security

Navigate to GitHub repository → Security tab

**Show**:
- Dependabot alerts
- Secret scanning alerts
- Code scanning results
- Security advisories

## Part 4: CI/CD Pipeline (15 minutes)

### 4.1 Show Pipeline Configuration

```bash
# Show buildspec files
cat buildspec-infra.yml
cat buildspec-app.yml
```

**Explain**:
- Infrastructure pipeline with IaC scanning
- Application pipeline with container scanning
- Automated deployment to EKS

### 4.2 Trigger Pipeline

```bash
# Make a change and push
echo "# Test change" >> README.md
git add README.md
git commit -m "Test pipeline"
git push
```

**Show**:
- GitHub Actions running security scans
- CodePipeline triggered
- CodeBuild running scans
- Deployment to EKS

### 4.3 Show Scan Results

**In GitHub Actions**:
- Dependency scan results
- Secret scan results
- IaC scan results (Checkov, tfsec)
- Container scan results (Trivy)

**In CodeBuild**:
- Build logs showing security scans
- Trivy findings
- Checkov findings

## Part 5: Remediation (10 minutes)

### 5.1 Fix SSH Exposure

```hcl
# In terraform/security-groups.tf
ingress {
  description = "SSH from my IP only"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["YOUR_IP/32"]  # Instead of 0.0.0.0/0
}
```

### 5.2 Fix IAM Permissions

```hcl
# In terraform/iam.tf
policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:GetObject"
      ]
      Resource = "${aws_s3_bucket.mongodb_backups.arn}/*"
    }
  ]
})
```

### 5.3 Fix S3 Bucket

```hcl
# In terraform/s3.tf
resource "aws_s3_bucket_public_access_block" "mongodb_backups" {
  bucket = aws_s3_bucket.mongodb_backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### 5.4 Fix Kubernetes RBAC

```yaml
# In k8s/serviceaccount.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role  # Not ClusterRole
metadata:
  name: wiz-app-role
  namespace: wiz-app
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list"]
```

### 5.5 Update Software Versions

```hcl
# In terraform/variables.tf
variable "mongodb_version" {
  default     = "7.0"  # Latest stable
}

variable "ubuntu_version" {
  default     = "22.04"  # Latest LTS
}
```

## Part 6: Verification (5 minutes)

```bash
# Apply fixes
terraform apply

# Verify Security Hub findings reduced
aws securityhub get-findings --filters '{"SeverityLabel":[{"Value":"HIGH","Comparison":"EQUALS"}]}' --max-items 10

# Verify Config compliance improved
aws configservice describe-compliance-by-config-rule
```

## Cleanup

```bash
# Delete Kubernetes resources
kubectl delete namespace wiz-app

# Destroy infrastructure
cd terraform
terraform destroy -auto-approve
```

## Key Talking Points

1. **Defense in Depth**: Multiple layers of security controls
2. **Shift Left**: Security scanning in CI/CD pipeline
3. **Automation**: Automated detection and remediation
4. **Visibility**: Centralized security findings in Security Hub
5. **Compliance**: Continuous compliance monitoring with Config
6. **Audit**: Complete audit trail with CloudTrail

## Questions to Anticipate

1. **Q**: Why use intentionally vulnerable infrastructure?
   **A**: To demonstrate security detection capabilities and remediation process

2. **Q**: How would you prevent these issues in production?
   **A**: Policy-as-code, automated scanning, security reviews, least privilege

3. **Q**: What's the cost of running this environment?
   **A**: ~$5-10/day (EKS, EC2, NAT Gateway, ALB)

4. **Q**: How do you handle secrets in production?
   **A**: AWS Secrets Manager, IRSA for Kubernetes, never hardcode

5. **Q**: What about runtime security?
   **A**: AWS GuardDuty, Falco for Kubernetes, runtime application protection

# Security Policy

## Overview

This repository contains an **intentionally vulnerable** cloud infrastructure for security demonstration purposes. It is part of the Wiz Security Exercise and should **NEVER** be used in production.

## Intentional Vulnerabilities

This environment contains the following intentional security issues:

### Infrastructure Vulnerabilities

1. **Exposed SSH Access**
   - MongoDB EC2 instance has SSH (port 22) open to 0.0.0.0/0
   - Location: `terraform/security-groups.tf`

2. **Excessive IAM Permissions**
   - MongoDB EC2 instance has overly permissive IAM role
   - Can create VMs, modify IAM, and access all S3 buckets
   - Location: `terraform/iam.tf`

3. **Public S3 Bucket**
   - MongoDB backup bucket allows public read and list access
   - Database backups are publicly accessible
   - Location: `terraform/s3.tf`

4. **Outdated Software**
   - Ubuntu 20.04 (1+ year old)
   - MongoDB 4.4 (outdated version with known vulnerabilities)
   - Location: `terraform/ec2-mongodb.tf`

### Kubernetes Vulnerabilities

5. **Cluster Admin Privileges**
   - Application pods run with cluster-admin role
   - Can perform any action in the Kubernetes cluster
   - Location: `k8s/serviceaccount.yaml`

6. **Hardcoded Credentials**
   - MongoDB credentials in ConfigMap
   - Location: `k8s/configmap.yaml`

### Application Vulnerabilities

7. **Secrets in Code**
   - Database credentials in user data script
   - JWT secret keys in configuration

## Security Controls Implemented

### Preventative Controls

1. **Branch Protection**
   - Require pull request reviews
   - Require status checks to pass
   - Restrict direct pushes to main

2. **Automated Scanning**
   - Dependency scanning (Dependabot, govulncheck)
   - Secret scanning (Gitleaks)
   - IaC scanning (Checkov, tfsec)
   - Container scanning (Trivy)
   - SAST (gosec, golangci-lint)

### Detective Controls

1. **AWS CloudTrail**
   - Audit logging for all API calls
   - Multi-region trail enabled

2. **AWS Config**
   - Compliance monitoring
   - Configuration change tracking

3. **AWS Security Hub**
   - Centralized security findings
   - Integration with Inspector, GuardDuty

4. **Amazon Inspector**
   - Code security scanning (GitHub integration)
   - ECR image scanning
   - EC2 vulnerability scanning

5. **AWS GuardDuty**
   - Threat detection
   - Anomaly detection

## Reporting Security Issues

This is a demonstration environment. Security issues are intentional and documented above.

For questions about this exercise, contact: [Your Email]

## Remediation Guide

To fix the vulnerabilities in this environment:

1. **SSH Access**: Restrict to specific IP ranges or use AWS Systems Manager
2. **IAM Permissions**: Apply principle of least privilege
3. **S3 Bucket**: Enable bucket encryption, disable public access
4. **Software Updates**: Use latest Ubuntu LTS and MongoDB versions
5. **Kubernetes RBAC**: Use namespace-scoped roles with minimal permissions
6. **Secrets Management**: Use AWS Secrets Manager or Kubernetes Secrets
7. **Credentials**: Never hardcode credentials, use IAM roles and IRSA

## Security Tools Used

- **Checkov**: IaC security scanning
- **tfsec**: Terraform security scanner
- **Trivy**: Container vulnerability scanner
- **Gitleaks**: Secret detection
- **gosec**: Go security checker
- **govulncheck**: Go vulnerability scanner
- **AWS Inspector**: Code and infrastructure scanning
- **AWS Security Hub**: Centralized security findings
- **AWS GuardDuty**: Threat detection

## License

This project is for educational purposes only.

# Opportunities Tracker

A cloud-native opportunity tracking application built with Go, MongoDB, and Kubernetes. Track sales opportunities, manage pipelines, and monitor deal values with a modern, responsive web interface.

## Overview

This is a full-stack application featuring:
- RESTful API built with Go and Gin framework
- MongoDB database for persistent storage
- JWT-based authentication and authorization
- Kubernetes deployment on AWS EKS
- Infrastructure as Code with Terraform
- Automated CI/CD pipeline with security scanning

## Architecture

The application follows a modern cloud-native architecture:

```
GitHub → CodePipeline → CodeBuild → ECR → EKS (Kubernetes)
                                            ↓
                                      MongoDB (EC2)
                                            ↓
                                    S3 (Automated Backups)
```

**Infrastructure Components:**
- **Application**: Go microservice running in Kubernetes pods
- **Database**: MongoDB on EC2 with automated daily backups
- **Container Registry**: Amazon ECR for Docker images
- **Orchestration**: Amazon EKS (Kubernetes) for container management
- **Load Balancing**: Application Load Balancer for traffic distribution
- **Storage**: S3 for database backups with lifecycle policies
- **Networking**: VPC with public/private subnets for security

## Features

- **User Management**: Secure signup and login with JWT authentication
- **Opportunity Tracking**: Create, read, update, and delete sales opportunities
- **Deal Values**: Track monetary values for each opportunity
- **Status Management**: Monitor opportunity status (open/closed)
- **User Isolation**: Each user sees only their own opportunities
- **Responsive UI**: Clean, modern interface that works on all devices
- **RESTful API**: Well-documented API endpoints for integration

## Prerequisites

- AWS Account with admin access
- GitHub account
- AWS CLI configured
- kubectl installed
- Terraform >= 1.0
- Docker installed
- Go 1.25+ (for local development)

## Quick Start

### 1. Clone Repository

```bash
git clone <your-repo-url>
cd wiz
```

### 2. Deploy Infrastructure

```bash
cd terraform
terraform init
terraform apply

# Save outputs
terraform output -json > ../outputs.json
```

### 3. Configure kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name wiz-exercise-eks
kubectl get nodes
```

### 4. Build and Deploy Application

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build and push
docker build -t wiz-app .
docker tag wiz-app:latest <ecr-url>:latest
docker push <ecr-url>:latest

# Deploy to Kubernetes
kubectl apply -f k8s/

# Get application URL
kubectl get ingress -n wiz-app
```

## CI/CD Pipeline Setup

### GitHub Actions (Security Scanning)

1. Fork this repository
2. Enable GitHub Actions
3. Security scans run automatically on push/PR

### AWS CodePipeline (Infrastructure & App Deployment)

1. Create CodePipeline with two stages:
   - **Stage 1**: Infrastructure deployment (buildspec-infra.yml)
   - **Stage 2**: Application build & deploy (buildspec-app.yml)

2. Connect to GitHub repository

3. Configure environment variables:
   - `AWS_ACCOUNT_ID`
   - `AWS_DEFAULT_REGION`
   - `IMAGE_REPO_NAME`
   - `EKS_CLUSTER_NAME`

## Security

This application implements multiple layers of security:

- **Authentication**: JWT tokens with secure cookie storage
- **Authorization**: User-specific data isolation
- **Password Security**: bcrypt hashing with salt
- **Database Security**: MongoDB authentication required
- **Network Security**: Private subnets for application and database
- **Container Security**: Regular vulnerability scanning
- **Infrastructure Security**: Automated compliance checking
- **Audit Logging**: CloudTrail for all AWS API calls
- **Backup Strategy**: Automated daily backups to S3

See [SECURITY.md](SECURITY.md) for detailed security documentation.

## Project Structure

```
wiz/
├── auth/                   # JWT authentication
├── controllers/            # API controllers
├── database/              # MongoDB connection
├── models/                # Data models
├── assets/                # Frontend (HTML/CSS/JS)
├── terraform/             # Infrastructure as Code
│   ├── main.tf
│   ├── vpc.tf
│   ├── eks.tf
│   ├── ec2-mongodb.tf
│   ├── s3.tf
│   └── ...
├── k8s/                   # Kubernetes manifests
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── ...
├── .github/workflows/     # GitHub Actions
├── buildspec-infra.yml    # Infrastructure pipeline
├── buildspec-app.yml      # Application pipeline
├── Dockerfile
├── SECURITY.md            # Security documentation
├── DEMO.md               # Demonstration guide
└── README.md
```

## Demonstration

For a complete walkthrough of the application features and deployment process, see [DEMO.md](DEMO.md).

## Application Features

### User Management
- Secure user registration with email validation
- Password hashing with bcrypt
- JWT-based session management
- Automatic session refresh

### Opportunity Management
- Create new opportunities with name and value
- View all opportunities in a clean dashboard
- Update opportunity details
- Delete individual opportunities
- Bulk delete all opportunities
- Real-time status updates

### User Experience
- Responsive design for mobile and desktop
- Intuitive interface with modern styling
- Fast page loads and smooth interactions
- Clear visual feedback for all actions

## API Endpoints

### Authentication
- `POST /signup` - Create new user
- `POST /login` - Login user
- `GET /opportunities` - Opportunities page (requires auth)

### Opportunities
- `GET /opportunities/:userid` - Get all opportunities for user
- `GET /opportunity/:id` - Get single opportunity
- `POST /opportunity/:userid` - Create new opportunity
- `PUT /opportunity` - Update opportunity
- `DELETE /opportunity/:userid/:id` - Delete opportunity
- `DELETE /opportunities/:userid` - Delete all opportunities

## Cleanup

```bash
# Delete Kubernetes resources
kubectl delete namespace wiz-app

# Destroy infrastructure
cd terraform
terraform destroy -auto-approve
```

## Cost Estimate

Running this infrastructure on AWS costs approximately **$5-10/day**:
- EKS cluster: ~$2.40/day
- EC2 instance (t3.medium): ~$1.20/day
- NAT Gateway: ~$1.08/day
- Application Load Balancer: ~$0.60/day
- S3, ECR, data transfer: ~$0.50/day

Monthly cost: ~$150-300 depending on usage.

## Security Tools Used

- **Checkov**: Infrastructure as Code security scanning
- **tfsec**: Terraform-specific security scanner
- **Trivy**: Container vulnerability and secret scanning
- **Gitleaks**: Git repository secret detection
- **gosec**: Go source code security analyzer
- **govulncheck**: Go vulnerability database checker
- **AWS Inspector**: Automated security assessment
- **AWS Security Hub**: Centralized security findings
- **AWS Config**: Configuration compliance monitoring
- **AWS CloudTrail**: API activity logging

## Tech Stack

**Backend:**
- Go 1.25
- Gin Web Framework
- MongoDB 4.4
- JWT for authentication
- bcrypt for password hashing

**Infrastructure:**
- AWS EKS (Kubernetes)
- Amazon ECR (Container Registry)
- Amazon EC2 (MongoDB)
- Amazon S3 (Backups)
- Application Load Balancer
- Terraform (Infrastructure as Code)

**CI/CD:**
- GitHub Actions
- AWS CodePipeline
- AWS CodeBuild
- Automated testing and deployment

**Security:**
- Automated security scanning
- Container vulnerability scanning (Trivy)
- Infrastructure scanning (Checkov, tfsec)
- Dependency scanning
- Secret detection

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Contact

For questions or support, please open an issue in the GitHub repository.

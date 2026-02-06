#!/bin/bash

# Script to deploy the application CI/CD pipeline using CloudFormation

set -e

echo "========================================="
echo "Application Pipeline Setup"
echo "========================================="
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials are not configured. Please run 'aws configure' first."
    exit 1
fi

echo "✅ AWS CLI configured"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region || echo "us-east-1")
echo "   Account ID: $ACCOUNT_ID"
echo "   Region: $REGION"
echo ""

# Get GitHub information
echo "📝 GitHub Configuration"
echo "----------------------"
read -p "GitHub Owner (default: gregvinton80): " GITHUB_OWNER
GITHUB_OWNER=${GITHUB_OWNER:-gregvinton80}

read -p "GitHub Repository (default: tech-task-app): " GITHUB_REPO
GITHUB_REPO=${GITHUB_REPO:-tech-task-app}

read -p "GitHub Branch (default: main): " GITHUB_BRANCH
GITHUB_BRANCH=${GITHUB_BRANCH:-main}

echo ""
echo "🔑 GitHub Personal Access Token"
echo "-------------------------------"
echo "You need a GitHub Personal Access Token with 'repo' and 'admin:repo_hook' permissions."
echo "Create one at: https://github.com/settings/tokens/new"
echo ""
read -sp "GitHub Token: " GITHUB_TOKEN
echo ""
echo ""

if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ GitHub token is required"
    exit 1
fi

# Get infrastructure details
echo "🏗️  Infrastructure Configuration"
echo "--------------------------------"
read -p "EKS Cluster Name (default: wiz-exercise-eks): " EKS_CLUSTER
EKS_CLUSTER=${EKS_CLUSTER:-wiz-exercise-eks}

read -p "ECR Repository Name (default: wiz-exercise-app): " ECR_REPO
ECR_REPO=${ECR_REPO:-wiz-exercise-app}

# Stack name
STACK_NAME="tech-task-app-pipeline"

echo ""
echo "🚀 Deploying CloudFormation Stack"
echo "---------------------------------"
echo "Stack Name: $STACK_NAME"
echo "Region: $REGION"
echo ""

# Deploy CloudFormation stack
aws cloudformation deploy \
    --template-file pipeline-setup.yaml \
    --stack-name $STACK_NAME \
    --parameter-overrides \
        GitHubOwner=$GITHUB_OWNER \
        GitHubRepo=$GITHUB_REPO \
        GitHubBranch=$GITHUB_BRANCH \
        GitHubToken=$GITHUB_TOKEN \
        EKSClusterName=$EKS_CLUSTER \
        ECRRepositoryName=$ECR_REPO \
    --capabilities CAPABILITY_NAMED_IAM \
    --region $REGION

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Pipeline deployed successfully!"
    echo ""
    
    # Get outputs
    echo "📊 Stack Outputs"
    echo "---------------"
    aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
        --output table
    
    echo ""
    echo "🎯 Next Steps"
    echo "------------"
    echo "1. Pipeline will automatically trigger on git push"
    echo ""
    echo "2. Push code to trigger first build:"
    echo "   git add ."
    echo "   git commit -m \"Trigger pipeline\""
    echo "   git push origin main"
    echo ""
    
    # Get pipeline URL
    PIPELINE_URL=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`PipelineUrl`].OutputValue' \
        --output text)
    
    echo "3. Monitor pipeline at:"
    echo "   $PIPELINE_URL"
    echo ""
    echo "4. After deployment completes, get app URL:"
    echo "   kubectl get ingress -n wiz-app"
    echo ""
    
else
    echo ""
    echo "❌ Pipeline deployment failed"
    echo "Check the CloudFormation console for details"
    exit 1
fi

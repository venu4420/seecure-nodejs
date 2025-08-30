# Secure Node.js Deployment on Google Cloud

DevSecOps implementation of containerized Node.js application on Google Cloud Run with secure infrastructure.

## Setup and Deployment Steps

### Prerequisites
1. GCP account with billing enabled
2. Google Cloud CLI installed
3. Terraform installed
4. GitHub repository configured

### Deployment

# 1. Enable APIs
gcloud services enable run.googleapis.com sql-component.googleapis.com secretmanager.googleapis.com artifactregistry.googleapis.com compute.googleapis.com servicenetworking.googleapis.com vpcaccess.googleapis.com iamcredentials.googleapis.com

# 2. Setup authentication
gcloud auth application-default login

# 3. Deploy infrastructure
terraform init
terraform apply -auto-approve

# 4. Build and deploy application
gcloud auth configure-docker us-central1-docker.pkg.dev
docker build -t us-central1-docker.pkg.dev/leafy-sight-470608-e9/secure-repo/secure-nodejs-app:latest .
docker push us-central1-docker.pkg.dev/leafy-sight-470608-e9/secure-repo/secure-nodejs-app:latest

## Security Measures Taken

### Network Security
- **VPC Isolation**: Cloud SQL in private VPC with no public IP
- **VPC Connector**: Secure connectivity between Cloud Run and Cloud SQL
- **Private IP Only**: Database accessible only through VPC

### Identity and Access Management
- **Workload Identity Federation**: OIDC authentication (no JSON keys)
- **Least Privilege**: Minimal IAM roles for service accounts
- **Service Account Separation**: Dedicated accounts for different functions

### Secret Management
- **Google Secret Manager**: Centralized secret storage
- **No Hardcoded Secrets**: All sensitive data externalized
- **Runtime Secret Access**: Secrets retrieved at application startup

### Container Security
- **Non-root User**: Application runs as unprivileged user (UID 1001)
- **Minimal Base Image**: Alpine Linux for reduced attack surface

### Infrastructure Security
- **Infrastructure as Code**: All resources defined in Terraform
- **Encrypted Communications**: TLS for all service communications
- **Resource Isolation**: Dedicated VPC and subnets

## Assumptions Made

### Technical Assumptions
- **Free Tier Usage**: Optimized for GCP free tier limits
- **Regional Deployment**: Single region (us-central1) deployment

### Justification for Deviations 
1. **CI Pipeline**: Focused on infrastructure security over comprehensive testing pipeline
2. **Monitoring**: Basic alerting implemented due to free tier limitations

## Alerting Setup Explanation

### Log-based Metrics
- **Error Metric**: Tracks Cloud Run application errors
- **Metric Type**: DELTA counter for error events

### Alert Policy
- **Condition**: More than 3 errors in 5-minute window
- **Threshold**: COMPARISON_GT with value 3
- **Duration**: 300 seconds (5 minutes)
- **Aggregation**: ALIGN_RATE with 300s alignment period

### Notification
- **Escalation**: Basic alert without complex escalation policies
- **Auto-close**: Alerts auto-close after 30 minutes

### Monitoring Coverage
- **Application Logs**: All Cloud Run logs captured
- **Infrastructure Metrics**: CPU, memory, network monitoring
- **Security Events**: IAM and network access logging
- **Cost Monitoring**: Billing alerts for budget control

## Architecture Summary

**Components Deployed:**
- Cloud Run service with VPC connectivity
- Cloud SQL PostgreSQL in private VPC
- VPC with private subnets and connector
- Secret Manager for credentials
- Artifact Registry for container images
- Monitoring and alerting policies

**Security Features:**
- Zero hardcoded secrets
- Network isolation
- Workload Identity Federation
- Container security best practices
- Infrastructure as Code

**AI tools used:**
- Co-pilot
- Amazon Q
- Windsurf
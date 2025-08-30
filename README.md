# Secure Node.js Deployment on Google Cloud

A secure CI/CD pipeline for deploying a containerized Node.js application on Google Cloud Run with DevSecOps principles.

## Architecture

- **Application**: Node.js REST API with PostgreSQL
- **Container**: Multi-stage Docker build with non-root user
- **Deployment**: Google Cloud Run with VPC connectivity
- **Database**: Cloud SQL PostgreSQL in private VPC
- **Secrets**: Google Secret Manager for credentials
- **Infrastructure**: Terraform automation
- **CI/CD**: GitHub Actions with Workload Identity Federation

## Security Measures

- **Network Security**: VPC-only connectivity between Cloud Run and Cloud SQL
- **IAM**: Minimal service accounts with least privilege principles
- **Secrets**: Google Secret Manager for sensitive data
- **Container Security**: Vulnerability scanning with Trivy
- **Code Security**: ESLint, npm audit, and SAST scanning
- **Authentication**: Workload Identity Federation (no JSON keys)

## Setup Instructions

### 1. Prerequisites

```bash
# Install required tools
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable \
  run.googleapis.com \
  sql-component.googleapis.com \
  secretmanager.googleapis.com \
  artifactregistry.googleapis.com \
  compute.googleapis.com \
  servicenetworking.googleapis.com \
  monitoring.googleapis.com
```

### 2. Workload Identity Federation Setup

```bash
# Create Workload Identity Pool
gcloud iam workload-identity-pools create "github-pool" \
  --location="global" \
  --description="GitHub Actions pool"

# Create Workload Identity Provider
gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --attribute-condition="assertion.repository=='YOUR_GITHUB_USER/YOUR_REPO'"

# Create Service Account for GitHub Actions
gcloud iam service-accounts create github-actions-sa \
  --display-name="GitHub Actions Service Account"

# Grant necessary roles
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:github-actions-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:github-actions-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.admin"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:github-actions-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/editor"

# Allow GitHub Actions to impersonate the service account
gcloud iam service-accounts add-iam-policy-binding \
  github-actions-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/attribute.repository/YOUR_GITHUB_USER/YOUR_REPO"
```

### 3. Configure GitHub Repository

Set up the following secrets and variables in your GitHub repository:

**Secrets:**
- `GCP_WORKLOAD_IDENTITY_PROVIDER`: `projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider`
- `GCP_SERVICE_ACCOUNT`: `github-actions-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com`
- `CHAT_WEBHOOK_URL`: Your Google Chat webhook URL

**Variables:**
- `GCP_PROJECT_ID`: Your GCP project ID
- `GCP_REGION`: `us-central1`
- `NOTIFICATION_EMAIL`: Your email for alerts

### 4. Deploy Infrastructure

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

terraform init
terraform plan
terraform apply
```

### 5. Test the Application

```bash
# Get the Cloud Run URL from Terraform output
CLOUD_RUN_URL=$(terraform output -raw cloud_run_url)

# Test health endpoint
curl $CLOUD_RUN_URL/health

# Test API endpoints
curl -X POST $CLOUD_RUN_URL/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com"}'

curl $CLOUD_RUN_URL/users
```

## Monitoring & Alerts

The system includes comprehensive monitoring:

- **Error Alerts**: >3 errors in 5 minutes → Google Chat notification
- **CPU Alerts**: 
  - >70% utilization → Google Chat warning
  - >80% utilization → Email alert
- **Memory Alerts**:
  - >70% utilization → Google Chat warning  
  - >80% utilization → Email alert

## Security Best Practices Implemented

1. **Principle of Least Privilege**: Custom IAM roles with minimal permissions
2. **Network Isolation**: Private VPC with no public IP for Cloud SQL
3. **Secret Management**: No hardcoded credentials, all secrets in Secret Manager
4. **Container Security**: Non-root user, minimal base image, vulnerability scanning
5. **Code Security**: Linting, security audits, and SAST scanning
6. **Infrastructure Security**: Terraform state management, encrypted communications

## Assumptions

- GCP project exists with billing enabled
- GitHub repository is configured for Actions
- Google Chat webhook is available for notifications
- DNS and SSL certificates managed separately if custom domain needed
- Terraform state stored locally (consider remote backend for production)

## Cost Optimization

- Cloud SQL uses `db-f1-micro` tier (can be upgraded)
- Cloud Run scales to zero when not in use
- Artifact Registry in same region as deployment
- Monitoring alerts prevent resource waste

--tests
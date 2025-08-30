# Assignment Completion Guide - Free Tier Setup

**Complete DevSecOps Assignment in 45 minutes** - Step-by-step guide with screenshot instructions.

## 🎯 Assignment Requirements Checklist
- ✅ Containerized Node.js REST API
- ✅ Cloud SQL PostgreSQL database
- ✅ VPC-only connectivity (no public DB access)
- ✅ Google Cloud Run deployment
- ✅ Secret Manager for credentials
- ✅ Terraform Infrastructure as Code
- ✅ GitHub Actions CI/CD pipeline
- ✅ Workload Identity Federation (no JSON keys)
- ✅ Monitoring and alerting
- ✅ Security best practices

## 📋 Prerequisites (5 minutes)

### Step 1: Create GCP Account
1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Sign up with Google account
3. Activate $300 free credits (requires credit card verification)
4. Create new project: `secure-nodejs-assignment`
5. **📸 Screenshot 1**: Project dashboard showing project ID

### Step 2: Install Google Cloud CLI
**Windows:**
1. Download from [cloud.google.com/sdk](https://cloud.google.com/sdk)
2. Run installer, check "Run gcloud init"
3. Login and select your project

**Verify installation:**
```bash
gcloud --version
gcloud auth list
gcloud config list
```
**📸 Screenshot 2**: Terminal showing gcloud version and authenticated account

## 🚀 Infrastructure Setup (15 minutes)

### Step 3: Enable Required APIs
```bash
# Set your project
export PROJECT_ID="leafy-sight-470608-e9"
gcloud config set project $PROJECT_ID

# Enable all required APIs
gcloud services enable \
  run.googleapis.com \
  sql-component.googleapis.com \
  secretmanager.googleapis.com \
  artifactregistry.googleapis.com \
  compute.googleapis.com \
  servicenetworking.googleapis.com \
  monitoring.googleapis.com \
  vpcaccess.googleapis.com \
  iamcredentials.googleapis.com
```
**📸 Screenshot 3**: GCP Console → APIs & Services showing enabled APIs

### Step 4: Setup Workload Identity Federation
```bash
# Create Workload Identity Pool
gcloud iam workload-identity-pools create "github-pool" \
  --location="global" \
  --description="GitHub Actions pool for assignment"

# Create OIDC Provider (replace YOUR_GITHUB_USER/YOUR_REPO with your actual GitHub repo)
gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --attribute-condition="assertion.repository=='YOUR_GITHUB_USER/YOUR_REPO'"

# Create Service Account for GitHub Actions
gcloud iam service-accounts create github-actions-sa \
  --display-name="GitHub Actions Service Account"

# Grant necessary permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/editor"

# Get project number for next step
PROJECT_NUMBER=193115445497
echo "Project Number: $PROJECT_NUMBER"

# Allow GitHub Actions to impersonate service account
gcloud iam service-accounts add-iam-policy-binding \
  github-actions-sa@$PROJECT_ID.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/attribute.repository/YOUR_GITHUB_USER/YOUR_REPO"
```
**📸 Screenshot 4**: IAM & Admin → Service Accounts showing github-actions-sa
**📸 Screenshot 5**: IAM & Admin → Workload Identity Federation showing pool and provider

### Step 5: Configure GitHub Repository
1. Go to your GitHub repo → Settings → Secrets and variables → Actions
2. Add **Repository secrets**:
   - `GCP_WORKLOAD_IDENTITY_PROVIDER`: `projects/193115445497/locations/global/workloadIdentityPools/github-pool/providers/github-provider`
   - `GCP_SERVICE_ACCOUNT`: `github-actions-sa@leafy-sight-470608-e9.iam.gserviceaccount.com`

3. Add **Repository variables**:
   - `GCP_PROJECT_ID`: `leafy-sight-470608-e9`
   - `GCP_REGION`: `us-central1`

**📸 Screenshot 6**: GitHub repo secrets and variables configuration

## 🏗️ Deploy Infrastructure (10 minutes)

### Step 6: Prepare Terraform Configuration
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:
```hcl
project_id = "leafy-sight-470608-e9"
region     = "us-central1"
```

### Step 7: Setup Authentication and Deploy
```bash
# Setup application default credentials for Terraform
gcloud auth application-default login

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan

# Apply configuration (takes 8-10 minutes)
terraform apply -auto-approve
```
**📸 Screenshot 7**: Terminal showing successful terraform apply output
**📸 Screenshot 8**: GCP Console → Cloud SQL showing secure-db instance (private IP only)
**📸 Screenshot 9**: GCP Console → VPC networks showing secure-app-vpc with connector
**📸 Screenshot 10**: GCP Console → Secret Manager showing db-password secret

## 🚀 Application Deployment (10 minutes)

### Step 8: Push Code to Trigger CI/CD
```bash
# Add all files and push to GitHub
git add .
git commit -m "Deploy secure Node.js app for assignment"
git push origin main
```

### Step 9: Monitor GitHub Actions
1. Go to GitHub repo → Actions tab
2. Watch the "Deploy" workflow run
3. Wait for successful completion (3-5 minutes)

**📸 Screenshot 11**: GitHub Actions showing successful deployment workflow
**📸 Screenshot 12**: GCP Console → Cloud Run showing secure-app service running
**📸 Screenshot 13**: GCP Console → Artifact Registry showing pushed Docker image

## 🧪 Testing & Validation (5 minutes)

### Step 10: Test Application Endpoints
```bash
# Get the Cloud Run URL
CLOUD_RUN_URL=$(terraform output -raw cloud_run_url)
echo "Application URL: $CLOUD_RUN_URL"

# Test health endpoint
curl $CLOUD_RUN_URL/health

# Test creating a user
curl -X POST $CLOUD_RUN_URL/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Assignment","email":"john@assignment.com"}'

# Test getting users
curl $CLOUD_RUN_URL/users

# Test database connectivity by creating multiple users
curl -X POST $CLOUD_RUN_URL/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Jane DevSecOps","email":"jane@devsecops.com"}'

curl $CLOUD_RUN_URL/users
```
**📸 Screenshot 14**: Terminal showing successful API responses with user data
**📸 Screenshot 15**: Browser showing application URL with JSON response

## 📊 Security & Monitoring Validation

### Step 11: Verify Security Implementation
```bash
# Verify Cloud SQL has no public IP
gcloud sql instances describe secure-db --format="value(ipAddresses[].type)"
# Should show only "PRIVATE"

# Check VPC connector
gcloud compute networks vpc-access connectors list --region=us-central1

# Verify secrets
gcloud secrets list
```
**📸 Screenshot 16**: Terminal showing Cloud SQL with private IP only
**📸 Screenshot 17**: GCP Console → VPC → VPC network peering showing servicenetworking connection

### Step 12: Check Monitoring and Alerts
1. Go to GCP Console → Monitoring → Alerting
2. View the "High Error Rate" policy
3. Go to Logging → Logs Explorer
4. Filter: `resource.type="cloud_run_revision"`

**📸 Screenshot 18**: GCP Console → Monitoring showing alert policy
**📸 Screenshot 19**: GCP Console → Logging showing application logs

## 📸 Assignment Screenshots Summary (19 total)

### Setup & Configuration (6 screenshots)
1. **Project Dashboard**: GCP project with ID
2. **CLI Setup**: Terminal with gcloud version
3. **Enabled APIs**: APIs & Services page
4. **Service Accounts**: IAM service accounts
5. **Workload Identity**: Identity federation setup
6. **GitHub Secrets**: Repository secrets/variables

### Infrastructure (4 screenshots)
7. **Terraform Output**: Successful apply
8. **Cloud SQL**: Private database instance
9. **VPC Network**: Network topology
10. **Secret Manager**: Database credentials

### Application Deployment (3 screenshots)
11. **GitHub Actions**: Successful CI/CD pipeline
12. **Cloud Run**: Running service
13. **Artifact Registry**: Docker image

### Testing & Validation (3 screenshots)
14. **API Testing**: Terminal with curl responses
15. **Browser Testing**: Application URL response
16. **Security Verification**: Private IP confirmation

### Security & Monitoring (3 screenshots)
17. **VPC Peering**: Network security
18. **Monitoring**: Alert policies
19. **Logging**: Application logs

## ✅ Assignment Requirements Verification

### DevSecOps Principles Demonstrated:
- **Infrastructure as Code**: All resources defined in Terraform
- **CI/CD Pipeline**: GitHub Actions with automated deployment
- **Security**: Workload Identity, VPC isolation, Secret Manager
- **Monitoring**: Log-based metrics and alerting
- **Container Security**: Multi-stage Docker build, non-root user
- **Network Security**: Private VPC, no public database access

### Technologies Used:
- **Application**: Node.js REST API with Express
- **Database**: Cloud SQL PostgreSQL (private)
- **Container**: Docker with security best practices
- **Orchestration**: Google Cloud Run
- **Infrastructure**: Terraform
- **CI/CD**: GitHub Actions
- **Security**: Google Secret Manager, Workload Identity
- **Monitoring**: Google Cloud Monitoring

## 💰 Cost Breakdown (Free Tier Optimized)

**Assignment duration: 2-3 hours**
- Cloud Run: $0 (2M requests free monthly)
- Cloud SQL db-f1-micro: ~$0.25 for 3 hours
- VPC Connector: $0 (free tier)
- Secret Manager: $0 (10K operations free)
- Artifact Registry: $0 (0.5GB free)
- Monitoring: $0 (free tier)

**Total cost: ~$0.25 for entire assignment**

## 🧹 Cleanup After Screenshots

**IMPORTANT**: Take all screenshots before cleanup!

```bash
# 1. Destroy Terraform resources
cd terraform
terraform destroy -auto-approve

# 2. Delete Workload Identity (optional)
gcloud iam workload-identity-pools delete github-pool --location=global

# 3. Delete service account (optional)
gcloud iam service-accounts delete github-actions-sa@$PROJECT_ID.iam.gserviceaccount.com

# 4. Delete entire project (optional - nuclear option)
gcloud projects delete $PROJECT_ID
```

## 🎯 Assignment Submission Checklist

- [ ] All 19 screenshots taken and organized
- [ ] GitHub repository with complete code
- [ ] Working application URL documented
- [ ] Security measures documented
- [ ] DevSecOps principles explained
- [ ] Cost optimization demonstrated
- [ ] Infrastructure as Code implemented
- [ ] CI/CD pipeline functional
- [ ] Monitoring and alerting configured
- [ ] Resources cleaned up (after submission)

## 🚨 Pro Tips for Assignment Success

1. **Screenshot Organization**: Name files clearly (01-project-dashboard.png, etc.)
2. **Documentation**: Include URLs and commands used in your submission
3. **Timing**: Complete in one session to avoid additional costs
4. **Verification**: Test all endpoints before taking screenshots
5. **Backup**: Save terraform.tfstate file before cleanup
6. **Evidence**: Include curl command outputs in screenshots
7. **Security**: Highlight private IP usage and no hardcoded secrets
8. **Architecture**: Explain VPC connectivity in your documentation

## ⚡ Quick Reference Commands

```bash
# Get project info
gcloud config get-value project
gcloud projects describe $(gcloud config get-value project) --format="value(projectNumber)"

# Check resources
gcloud run services list
gcloud sql instances list
gcloud secrets list

# Get application URL
terraform output cloud_run_url

# Test endpoints
curl $(terraform output -raw cloud_run_url)/health
curl -X POST $(terraform output -raw cloud_run_url)/users -H "Content-Type: application/json" -d '{"name":"Test","email":"test@example.com"}'
```

**Total assignment time: 45 minutes + screenshot organization**
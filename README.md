# Secure Node.js Deployment on Google Cloud

A secure CI/CD pipeline for deploying a containerized Node.js application on Google Cloud Run with DevSecOps principles.

## 📚 Assignment Documentation

- **[🎯 ASSIGNMENT COMPLETION GUIDE](FREE_TIER_SETUP.md)** - Complete step-by-step guide with screenshots for assignment submission

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

## 🚀 Quick Start

**For assignment completion, follow the [Assignment Completion Guide](FREE_TIER_SETUP.md)**

### Quick Deploy Commands:
```bash
# 1. Setup GCP and enable APIs
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
gcloud services enable run.googleapis.com sql-component.googleapis.com secretmanager.googleapis.com artifactregistry.googleapis.com compute.googleapis.com servicenetworking.googleapis.com

# 2. Deploy infrastructure
cd terraform
terraform init && terraform apply -auto-approve

# 3. Test application
URL=$(terraform output -raw cloud_run_url)
curl $URL/health
curl -X POST $URL/users -H "Content-Type: application/json" -d '{"name":"Test","email":"test@example.com"}'
```

## 📊 Monitoring

- **Error Alerts**: >3 errors in 5 minutes triggers alert
- **Log-based Metrics**: Automatic error tracking
- **Cloud Monitoring**: Integrated GCP monitoring

## Security Best Practices Implemented

1. **Principle of Least Privilege**: Custom IAM roles with minimal permissions
2. **Network Isolation**: Private VPC with no public IP for Cloud SQL
3. **Secret Management**: No hardcoded credentials, all secrets in Secret Manager
4. **Container Security**: Non-root user, minimal base image, vulnerability scanning
5. **Code Security**: Linting, security audits, and SAST scanning
6. **Infrastructure Security**: Terraform state management, encrypted communications

## 💰 Cost Optimization

- **Free Tier Optimized**: ~$0.25 for assignment completion
- **Cloud SQL**: db-f1-micro (smallest instance)
- **Cloud Run**: Scales to zero, 256Mi memory limit
- **Auto-cleanup**: Destroy resources after assignment

## 🧹 Cleanup

```bash
# Destroy all resources after taking screenshots
terraform destroy -auto-approve
```
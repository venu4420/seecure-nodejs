Write-Host "Building and pushing Docker image..." -ForegroundColor Green

$PROJECT_ID = "leafy-sight-470608-e9"
Write-Host "Project ID: $PROJECT_ID" -ForegroundColor Yellow

# Configure Docker authentication
Write-Host "Configuring Docker authentication..." -ForegroundColor Cyan
gcloud auth configure-docker us-central1-docker.pkg.dev

# Build Docker image
Write-Host "Building Docker image..." -ForegroundColor Cyan
docker build -t "us-central1-docker.pkg.dev/$PROJECT_ID/secure-repo/secure-nodejs-app:latest" .

# Push Docker image
Write-Host "Pushing Docker image..." -ForegroundColor Cyan
docker push "us-central1-docker.pkg.dev/$PROJECT_ID/secure-repo/secure-nodejs-app:latest"

Write-Host "Docker image built and pushed successfully!" -ForegroundColor Green
Write-Host "Now run: terraform apply -auto-approve" -ForegroundColor Yellow
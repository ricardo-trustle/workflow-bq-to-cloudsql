#!/bin/bash

set -e

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

log_success() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

log_info() {
    echo -e "${BLUE}INFO: $1${NC}"
}

INSTANCE_ID=postgres-light
BUCKET_NAME=ricardo-sandbox-bucket

# gcloud config set compute/region us-central1

PROJECT_ID=ricardo-sandbox07-03-24
gcloud config set project $PROJECT_ID

# Print selected project
log_info "Selected project: $PROJECT_ID"
# read -p "Are you sure (y/n)? " -n 1 -r
# echo    # (optional) move to a new line
# if [[ ! $REPLY =~ ^[Yy]$ ]]
# then
#     log_warning "Exiting..."
#     [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
# fi

# Create the service account named import-workflow if it doesn't exist
if ! gcloud iam service-accounts list --filter="email:import-workflow@$PROJECT_ID.iam.gserviceaccount.com" --format="value(email)" | grep -q "import-workflow@$PROJECT_ID.iam.gserviceaccount.com"; then
    gcloud iam service-accounts create import-workflow
else
    log_warning "Service account import-workflow already exists."
    # gcloud iam service-accounts delete "import-workflow@$PROJECT_ID.iam.gserviceaccount.com"
    # gcloud iam service-accounts create import-workflow
fi

# Grant the permissions to the service account
roles=(
    "roles/cloudsql.admin"
    "roles/storage.admin"
    "roles/storage.objectAdmin"
    "roles/bigquery.dataViewer"
    "roles/bigquery.jobUser"
    "roles/logging.logWriter"
)

for role in "${roles[@]}"; do
    log_info "Granting the role $role to the service account..."
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:import-workflow@$PROJECT_ID.iam.gserviceaccount.com" \
        --role="$role"
done

# Grant the permissions to the service account of the Cloud SQL instance created by default
CLOUD_SQL_SERVICE_ACCOUNT=$(gcloud sql instances describe $INSTANCE_ID --format="value(serviceAccountEmailAddress)")
roles=(
    "roles/storage.objectUser"
    "roles/logging.logWriter"
)

for role in "${roles[@]}"; do
    log_info "Granting the role $role to the service account of the Cloud SQL instance: $CLOUD_SQL_SERVICE_ACCOUNT..."
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:$CLOUD_SQL_SERVICE_ACCOUNT" \
        --role="$role"
done

# log_info "Granting the role roles/cloudsql.client to the service account of the Cloud SQL instance: $CLOUD_SQL_SERVICE_ACCOUNT..."
# gsutil iam ch serviceAccount:${CLOUD_SQL_SERVICE_ACCOUNT}:roles/storage.objectUser \
#     "gs://$BUCKET_NAME"


# Deploy to Workflow
log_info "Deploying the workflow..."
gcloud workflows deploy import --source=import.yaml \
    --service-account=import-workflow@$PROJECT_ID.iam.gserviceaccount.com \
    --env-vars-file .env.yaml \
    --location=us-central1

# Trigger the workflow
log_info "Triggering the workflow..."
gcloud workflows execute import --location=us-central1

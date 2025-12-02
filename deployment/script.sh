#!/bin/bash


# Usage: ./script.sh [apply|delete] [force]
ACTION=${1:-apply}
FORCE=${2:-}
DOCKERHUB_USERNAME="trainer1234"
DOCKERHUB_PASSWORD="danny1234"
DOCKERHUB_EMAIL="trainer1234.giaiminh@gmail.com"
NAMESPACE="default"

if [[ "$ACTION" == "apply" ]]; then
    # Generate and apply secrets
    jq '.' appsettings.test.json > appsettings.json
    export appSettingsBase64=$(cat "appsettings.json" | base64 -w 0)
    envsubst < secret.yaml > app/secret-backend.yaml

    kubectl create secret docker-registry dockerhub-secret \
    --docker-server=https://index.docker.io/v1/ \
    --docker-username="$DOCKERHUB_USERNAME" \
    --docker-password="$DOCKERHUB_PASSWORD" \
    --docker-email="$DOCKERHUB_EMAIL" \
    --namespace=$NAMESPACE \
    --dry-run=client -o yaml | kubectl apply -f -

    kubectl apply -f secrets/ -n default

    # Deploy application resources
    kubectl apply -f app/ -n default

    # Clean up
    rm appsettings.json
    rm app/secret-backend.yaml

    # Check if the secret was created successfully
    if kubectl get secret appsettings-backend -n default &> /dev/null; then
        echo "Secret created successfully."
    else
        echo "Failed to create secret."
        exit 1
    fi

    # Wait for backend-api pod to be running
    echo "Waiting for backend-api pod to be running..."
    kubectl wait --for=condition=Ready pod -l app=backend-api -n default --timeout=120s

    if [ $? -eq 0 ]; then
        echo "backend-api pod is running."
    else
        echo "backend-api pod failed to reach running state."
        kubectl get pods -n default
        exit 1
    fi

    # Wait for frontend (node) pod to be running
    echo "Waiting for frontend pod to be running..."
    kubectl wait --for=condition=Ready pod -l app=frontend -n default --timeout=120s

    if [ $? -eq 0 ]; then
        echo "frontend pod is running."
    else
        echo "frontend pod failed to reach running state."
        kubectl get pods -n default
        exit 1
    fi

    # Wait for ai-chatbot (node) pod to be running
    echo "Waiting for ai-chatbot pod to be running..."
    kubectl wait --for=condition=Ready pod -l app=ai-chatbot -n default --timeout=120s

    if [ $? -eq 0 ]; then
        echo "ai-chatbot pod is running."
    else
        echo "ai-chatbot pod failed to reach running state."
        kubectl get pods -n default
        exit 1
    fi    
elif [[ "$ACTION" == "delete" ]]; then
    echo "Deleting resources..."
    kubectl delete -f app/ -n default
    kubectl delete -f secrets/ -n default
else
    echo "Usage: $0 [apply|delete]"
    exit 1
fi
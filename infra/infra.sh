#!/bin/bash

# Infrastructure management script for local Supabase deployment on Minikube
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CHART_DIR="$SCRIPT_DIR/local-stack"
NAMESPACE="supabase"
RELEASE_NAME="local-stack"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_dependencies() {
    local missing_deps=()
    
    if ! command -v minikube &> /dev/null; then
        missing_deps+=("minikube")
    fi
    
    if ! command -v kubectl &> /dev/null; then
        missing_deps+=("kubectl")
    fi
    
    if ! command -v helm &> /dev/null; then
        missing_deps+=("helm")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_info "Please install them before running this script"
        exit 1
    fi
}

# Start Minikube
start_minikube() {
    log_info "Starting Minikube..."
    
    # Check if Minikube is already running
    if minikube status &> /dev/null; then
        log_warn "Minikube is already running"
        minikube status
        return 0
    fi
    
    # Start Minikube with appropriate resources
    minikube start \
        --cpus=4 \
        --memory=8192 \
        --disk-size=20g \
        --driver=docker
    
    if [ $? -eq 0 ]; then
        log_info "Minikube started successfully"
        minikube status
    else
        log_error "Failed to start Minikube"
        exit 1
    fi
}

# Stop Minikube
stop_minikube() {
    log_info "Stopping Minikube..."
    
    if ! minikube status &> /dev/null; then
        log_warn "Minikube is not running"
        return 0
    fi
    
    minikube stop
    log_info "Minikube stopped successfully"
}

# Deploy local-stack Helm chart
deploy_local_stack() {
    log_info "Deploying local-stack Helm chart..."
    
    # Check if Minikube is running
    if ! minikube status &> /dev/null; then
        log_error "Minikube is not running. Please run './infra.sh start' first"
        exit 1
    fi
    
    # Create namespace if it doesn't exist
    log_info "Creating namespace: $NAMESPACE"
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    # Update chart dependencies (pulls from local path)
    log_info "Updating chart dependencies..."
    cd "$CHART_DIR"
    helm dependency update
    cd "$SCRIPT_DIR"
    
    # Install or upgrade the chart with custom values
    log_info "Installing/upgrading $RELEASE_NAME with custom values..."
    helm upgrade --install $RELEASE_NAME "$CHART_DIR" \
        --namespace $NAMESPACE \
        --create-namespace \
        --wait \
        --timeout 10m
    
    if [ $? -eq 0 ]; then
        log_info "Deployment successful!"
        echo ""
        log_info "Access Supabase Studio at: http://$(minikube ip):30001"
        log_info "API Gateway (Kong) available at: http://$(minikube ip):30000"
        echo ""
        log_info "Run './infra.sh status' to check deployment status"
    else
        log_error "Deployment failed"
        exit 1
    fi
}

# Check deployment status
check_status() {
    log_info "Checking deployment status..."
    
    if ! minikube status &> /dev/null; then
        log_warn "Minikube is not running"
        return 0
    fi
    
    echo ""
    log_info "Minikube status:"
    minikube status
    
    echo ""
    log_info "Helm releases:"
    helm list -n $NAMESPACE
    
    echo ""
    log_info "Pods in namespace $NAMESPACE:"
    kubectl get pods -n $NAMESPACE
    
    echo ""
    log_info "Services in namespace $NAMESPACE:"
    kubectl get svc -n $NAMESPACE
}

# Uninstall local-stack
uninstall_local_stack() {
    log_info "Uninstalling local-stack..."
    
    helm uninstall $RELEASE_NAME -n $NAMESPACE
    
    if [ $? -eq 0 ]; then
        log_info "Uninstall successful"
        log_warn "Namespace $NAMESPACE still exists. Delete it with: kubectl delete namespace $NAMESPACE"
    else
        log_error "Uninstall failed"
        exit 1
    fi
}

# Show usage
show_usage() {
    cat << EOF
Infrastructure Management Script

Usage: $0 <command>

Commands:
    start           Start Minikube cluster
    stop            Stop Minikube cluster
    local-stack     Deploy the local-stack Helm chart with Supabase
    status          Check the status of deployments
    uninstall       Uninstall the local-stack deployment
    help            Show this help message

Examples:
    $0 start           # Start Minikube
    $0 local-stack     # Deploy Supabase
    $0 status          # Check deployment status
    $0 stop            # Stop Minikube

EOF
}

# Main script logic
main() {
    # Check dependencies first
    check_dependencies
    
    # Parse command
    case "${1:-help}" in
        start)
            start_minikube
            ;;
        stop)
            stop_minikube
            ;;
        local-stack)
            deploy_local_stack
            ;;
        status)
            check_status
            ;;
        uninstall)
            uninstall_local_stack
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            log_error "Unknown command: $1"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"

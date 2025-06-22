#!/bin/bash

# Flash Loan Agent Docker Management Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if .env file exists
check_env_file() {
    if [ ! -f .env ]; then
        print_warning ".env file not found. Please copy .env.example to .env and configure it."
        echo "cp .env.example .env"
        echo "Then edit .env file with your actual values."
        exit 1
    fi
}

# Build and start services
start() {
    print_info "Starting Flash Loan Agent services..."
    check_env_file
    docker-compose up --build -d
    print_info "Services started. Access the application at http://localhost:8000"
    print_info "MongoDB Express available at http://localhost:8081 (if enabled)"
}

# Start development environment
dev() {
    print_info "Starting development environment..."
    check_env_file
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml up --build
}

# Stop services
stop() {
    print_info "Stopping Flash Loan Agent services..."
    docker-compose down
}

# View logs
logs() {
    docker-compose logs -f "${1:-flash_loan_agent}"
}

# Clean up everything
clean() {
    print_warning "This will remove all containers, networks, and volumes. Are you sure? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        print_info "Cleaning up Docker resources..."
        docker-compose down -v --remove-orphans
        docker system prune -f
        print_info "Cleanup completed."
    else
        print_info "Cleanup cancelled."
    fi
}

# Show help
help() {
    echo "Flash Loan Agent Docker Management Script"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  start     Build and start services in production mode"
    echo "  dev       Start development environment with hot reload"
    echo "  stop      Stop all services"
    echo "  logs      Show logs (optional: specify service name)"
    echo "  clean     Remove all containers, networks, and volumes"
    echo "  help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 dev"
    echo "  $0 logs mongo"
    echo "  $0 stop"
}

# Main script logic
case "${1:-help}" in
    start)
        start
        ;;
    dev)
        dev
        ;;
    stop)
        stop
        ;;
    logs)
        logs "$2"
        ;;
    clean)
        clean
        ;;
    help|--help|-h)
        help
        ;;
    *)
        print_error "Unknown command: $1"
        help
        exit 1
        ;;
esac

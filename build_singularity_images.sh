#!/bin/bash
#
# Build Singularity images for the nf-purple pipeline
# This script pulls Docker images and converts them to Singularity SIF files
#
# Usage: ./build_singularity_images.sh
#
# Requirements:
#   - Singularity installed and available in PATH
#   - Write access to /isabl/local/purple/
#   - Internet access to pull Docker images
#

set -euo pipefail

# Output directory for SIF files
SIF_DIR="/isabl/local/purple"

# Container definitions: name -> docker URI
declare -A CONTAINERS=(
    ["purple_v0.1.1.sif"]="docker://papaemmelab/purple:v0.1.1"
    ["hmftools-sage_3.4.4.sif"]="docker://quay.io/biocontainers/hmftools-sage:3.4.4--hdfd78af_0"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if singularity is available
if ! command -v singularity &> /dev/null; then
    log_error "Singularity is not installed or not in PATH"
    exit 1
fi

# Create output directory if it doesn't exist
if [ ! -d "$SIF_DIR" ]; then
    log_info "Creating directory: $SIF_DIR"
    mkdir -p "$SIF_DIR"
fi

# Build each container
for sif_name in "${!CONTAINERS[@]}"; do
    docker_uri="${CONTAINERS[$sif_name]}"
    sif_path="${SIF_DIR}/${sif_name}"
    
    if [ -f "$sif_path" ]; then
        log_warn "SIF file already exists: $sif_path"
        read -p "Do you want to rebuild it? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipping $sif_name"
            continue
        fi
        rm -f "$sif_path"
    fi
    
    log_info "Building $sif_name from $docker_uri"
    log_info "This may take several minutes..."
    
    if singularity pull "$sif_path" "$docker_uri"; then
        log_info "Successfully built: $sif_path"
    else
        log_error "Failed to build: $sif_name"
        exit 1
    fi
done

log_info "All Singularity images built successfully!"
log_info "Images are located in: $SIF_DIR"
echo
log_info "Available images:"
ls -lh "$SIF_DIR"/*.sif 2>/dev/null || log_warn "No SIF files found"

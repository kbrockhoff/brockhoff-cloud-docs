#!/bin/bash

# Update documentation for modules and examples using terraform-docs
# This script runs terraform-docs with separate configurations for modules and examples

set -e

echo "Updating documentation for modules..."
terraform-docs --config .terraform-docs.yml .

echo "Updating documentation for examples..."
terraform-docs --config .terraform-docs-examples.yml .

echo "Documentation update complete!"
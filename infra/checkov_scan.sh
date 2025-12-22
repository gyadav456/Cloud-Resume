#!/bin/bash
# Install checkov if not present: pip install checkov

echo "Starting Checkov Security Scan..."
/Users/gaurav/Library/Python/3.9/bin/checkov -d . --skip-check CKV_AWS_272,CKV_AWS_116 --quiet

# Notes:
# CKV_AWS_272: Skips Lambda Code signing check (complex for personal projects)
# CKV_AWS_116: Skips DLQ check for Lambda (acceptable for non-critical counter)

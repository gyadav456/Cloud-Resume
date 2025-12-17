# Hostinger DNS Setup Guide for S3

Since your domain `gauravyadav.site` is managed by Hostinger, you need to point it to your AWS S3 bucket.

## Prerequisites
- **S3 Bucket Name**: `gauravyadav.site` (Must match domain name).
- **S3 Endpoint**: `gauravyadav.site.s3-website.ap-south-1.amazonaws.com`.

## Steps to Configure

1. **Log in to Hostinger** and go to the **DNS Zone Editor** for `gauravyadav.site`.

2. **Delete Existing A Records**:
   - Look for any **A** records with the name `@` (root).
   - Delete them (these usually point to Hostinger's default parked page).

3. **Add a CNAME Record for Root (@)**:
   - **Type**: `CNAME`
   - **Name**: `@` (or leave empty if Hostinger requires)
   - **Target**: `gauravyadav.site.s3-website.ap-south-1.amazonaws.com`
   - **TTL**: `3600`

   > **Note**: If Hostinger does not allow a CNAME at the root (`@`), proceed to the **Alternative Method** below.

4. **Add a CNAME Record for WWW**:
   - **Type**: `CNAME`
   - **Name**: `www`
   - **Target**: `gauravyadav.site.s3-website.ap-south-1.amazonaws.com`
   - **TTL**: `3600`

## Alternative Method (If CNAME @ is blocked)
If Hostinger blocks CNAME on root, use **CloudFront**.
1. Create a CloudFront Distribution in AWS pointing to your S3 bucket.
2. In Hostinger, add an **A Record** pointing to the CloudFront IP addresses (or use Alias if supported).
   *However, trying the CNAME method first is the quickest way.*

## Verification
- Wait 5-10 minutes for DNS propagation.
- Visit `http://gauravyadav.site` in your browser.
- **Important**: This setup is **HTTP only**. To get HTTPS (Secure), you typically need to use AWS CloudFront.

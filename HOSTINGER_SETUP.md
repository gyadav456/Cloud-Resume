# Hostinger DNS Setup Guide for S3 + CloudFront (HTTPS)

**Status**: HTTPS Certificate Validated.

## Final Step: Point Domain to CloudFront

To enable HTTPS, you need to update your DNS records to point to the CloudFront distribution instead of the S3 bucket directly.

### 1. Retrieve CloudFront Domain
Your CloudFront Domain is: `d1xnemhp4xttv6.cloudfront.net`

### 2. Update CNAME Records
Log in to Hostinger DNS Zone Editor for `gauravyadav.site`.

**For WWW:**
1.  Edit the existing `CNAME` record for `www`.
2.  Change **Target** to: `d1xnemhp4xttv6.cloudfront.net`
3.  **TTL**: 3600.

**For Root (@):**
*If Hostinger supports CNAME/ALIAS on root:*
1.  Edit the `@` record.
2.  Change **Target** to: `d1xnemhp4xttv6.cloudfront.net`.

*If Hostinger does NOT support CNAME on root:*
1.  You might need to use a **URL Redirect** (301) for `@` to `www.gauravyadav.site`.
2.  This ensures everyone goes to `www` which is securely handled by CloudFront.

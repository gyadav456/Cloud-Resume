# Critical: Enable Auto-Deployment (Webhook)

Use this guide to connect GitHub to your Jenkins server. Without this, your changes strictly stay in GitHub and won't deploy.

## The Missing Link: Webhook

1.  **Go to GitHub**: [https://github.com/gyadav456/Cloud-Resume/settings/hooks](https://github.com/gyadav456/Cloud-Resume/settings/hooks).
    *(Settings -> Webhooks)*
2.  **Click**: `Add webhook`.
3.  **Payload URL**: `http://<YOUR_JENKINS_IP>:8080/github-webhook/`
    *(Replace `<YOUR_JENKINS_IP>` with your actual Jenkins server IP/URL)*.
    *(Make sure to include the trailing slash `/`)*.
4.  **Content type**: `application/json`.
5.  **Which events?**: `Just the push event`.
6.  **Active**: Check this box.
7.  **Click**: `Add webhook`.

## How to Test

Once you add the webhook:
1.  Come back here and tell me "Webhook added".
2.  I will then push a small change to the code.
3.  We will verify if your Jenkins job starts automatically.

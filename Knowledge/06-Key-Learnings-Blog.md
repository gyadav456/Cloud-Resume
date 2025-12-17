# 06. The Cloud Resume Journey: Lessons Learned

*By Gaurav Yadav*

## The Challenge
"Build a resume. Put it in the cloud. Don't use a server."
That was the premise. But I wanted more. I wanted to build a **Production-Grade** platform that adhered to the strictest DevOps principles.

## Key Design Decisions

### 1. "Apple-Style" or Nothing
I didn't want a boring resume. I used **Glassmorphism**, Intersection Observers for animations, and a high-contrast dark mode to mimic the premium feel of Apple's product pages.
*   **Lesson**: Aesthetics matter. They prove you care about the end-user experience.

### 2. Serverless over Kubernetes
I love K8s, but for a resume? It's overkill.
*   **Choice**: AWS Lambda + JSON API.
*   **Result**: $0.00 cost when idle, instant scaling, and zero OS patching.

### 3. The "Security Incident"
Early on, I accidentally committed a `.pem` key to Git.
*   **The Fix**: I didn't just delete it. I rotated the key, nuked the git history, and implemented **AWS Secrets Manager**.
*   **Lesson**: Security isn't about being perfect; it's about how you recover when you slip.

### 4. Observability is a Feature
I realized that "it works" isn't enough. How do I *know* it works?
*   **Implementation**: I built a public status page. It forced me to learn CloudWatch APIs and gave visitors transparency into the system's performance.

## Final Thoughts
This project successfully transformed from a static HTML file into a fully automated, observable, and secure cloud platform. It runs itself, heals itself (via alerts), and costs pennies.

**That is the power of DevOps.**

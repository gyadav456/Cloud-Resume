document.addEventListener('DOMContentLoaded', () => {
    // Smooth scrolling for navigation links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            document.querySelector(this.getAttribute('href')).scrollIntoView({
                behavior: 'smooth'
            });
        });
    });

    // Mobile Menu Toggle
    const hamburger = document.querySelector('.hamburger');
    const navLinks = document.querySelector('.nav-links');

    hamburger.addEventListener('click', () => {
        navLinks.classList.toggle('active');
        hamburger.classList.toggle('active');
    });

    // Navbar scroll effect
    const nav = document.querySelector('nav');
    window.addEventListener('scroll', () => {
        if (window.scrollY > 50) {
            nav.style.background = 'rgba(5, 5, 17, 0.9)';
            nav.style.boxShadow = '0 10px 30px -10px rgba(0, 0, 0, 0.5)';
        } else {
            nav.style.background = 'rgba(5, 5, 17, 0.7)';
            nav.style.boxShadow = 'none';
        }
    });

    // Intersection Observer for fade-in animations on scroll
    const observerOptions = {
        threshold: 0.1
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('fade-in-visible');
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);

    document.querySelectorAll('.glass-card').forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(20px)';
        el.style.transition = 'opacity 0.6s ease-out, transform 0.6s ease-out';
        observer.observe(el);
    });

    // Add class for visible state
    const style = document.createElement('style');
    style.innerHTML = `
        .fade-in-visible {
            opacity: 1 !important;
            transform: translateY(0) !important;
        }
        .nav-links.active {
            display: flex;
            flex-direction: column;
            position: absolute;
            top: 70px;
            left: 0;
            width: 100%;
            background: #0d0d1b;
            padding: 20px;
            border-bottom: 1px solid rgba(255,255,255,0.1);
        }
    `;
    document.head.appendChild(style);

    // --- Visitor Counter Logic ---
    // TO ENABLE REAL BACKEND:
    // 1. Deploy Terraform infrastructure.
    // 2. Copy the 'api_endpoint' output URL.
    // 3. Paste it below in API_ENDPOINT.

    const API_ENDPOINT = 'https://970sm9mib1.execute-api.us-east-1.amazonaws.com/visitor'; // Real Backend

    const viewCountEl = document.getElementById('view-count');
    const downloadCountEl = document.getElementById('download-count');
    const downloadBtn = document.getElementById('download-btn');

    async function updateCounter(action = 'view') {
        try {
            if (API_ENDPOINT.startsWith('http')) {
                // Real Backend Mode
                const response = await fetch(API_ENDPOINT, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ action: action })
                });
                const data = await response.json();
                viewCountEl.textContent = data.views;
                downloadCountEl.textContent = data.downloads;

                // Also update local storage as backup/cache if needed, but primarily use API
            } else {
                // Demo / LocalStorage Mode
                if (action === 'view') {
                    let views = localStorage.getItem('resume_views') || 120;
                    views = parseInt(views) + 1;
                    localStorage.setItem('resume_views', views);
                    viewCountEl.textContent = views;

                    let downloads = localStorage.getItem('resume_downloads') || 45;
                    downloadCountEl.textContent = downloads;
                } else if (action === 'download') {
                    let downloads = parseInt(localStorage.getItem('resume_downloads') || 45);
                    downloads++;
                    localStorage.setItem('resume_downloads', downloads);
                    downloadCountEl.textContent = downloads;
                }
            }
        } catch (error) {
            console.error('Error updating counter:', error);
            viewCountEl.textContent = 'Err';
        }
    }

    // Initial load - count view
    updateCounter('view');

    if (downloadBtn) {
        downloadBtn.addEventListener('click', () => {
            updateCounter('download');
        });
    }

    // --- Gallery Modal Logic ---
    const galleryBtn = document.getElementById('gallery-btn');
    const galleryModal = document.getElementById('gallery-modal');
    const closeModal = document.querySelector('.close-modal');

    if (galleryBtn && galleryModal && closeModal) {
        galleryBtn.addEventListener('click', (e) => {
            e.preventDefault();
            galleryModal.style.display = 'block';
        });

        closeModal.addEventListener('click', () => {
            galleryModal.style.display = 'none';
        });

        window.addEventListener('click', (e) => {
            if (e.target === galleryModal) {
                galleryModal.style.display = 'none';
            }
        });
    }
});

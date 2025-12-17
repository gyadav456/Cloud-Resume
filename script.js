document.addEventListener('DOMContentLoaded', () => {
    // 1. Visitor and Download Counter Logic
    const visitorCounterElement = document.getElementById('visitor-count');
    const downloadCounterElement = document.getElementById('download-count');
    const downloadBtn = document.getElementById('download-resume-btn');
    const apiEndpoint = 'https://970sm9mib1.execute-api.us-east-1.amazonaws.com/visitor';

    async function updateCounters() {
        try {
            // Fetch initial stats (action: 'view' is default if body is empty or just checking)
            // But here we want to increment view on load.
            const response = await fetch(apiEndpoint, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ action: 'view' })
            });

            if (!response.ok) {
                throw new Error('Network response was not ok');
            }

            const data = await response.json();
            // Backend returns { views: <number>, downloads: <number> }
            animateValue(visitorCounterElement, 0, data.views, 1500);
            animateValue(downloadCounterElement, 0, data.downloads, 1500);

        } catch (error) {
            console.error('Error fetching stats:', error);
            visitorCounterElement.innerText = '---';
            downloadCounterElement.innerText = '---';
        }
    }

    async function handleDownload(e) {
        e.preventDefault();

        // 1. Start download immediately
        const link = document.createElement('a');
        link.href = 'frontend/resume.pdf'; // Assuming this path based on file list
        link.download = 'Gaurav_Yadav_Resume.pdf';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);

        // 2. Increment download count
        try {
            const response = await fetch(apiEndpoint, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ action: 'download' })
            });

            if (response.ok) {
                const data = await response.json();
                animateValue(downloadCounterElement, parseInt(downloadCounterElement.innerText) || 0, data.downloads, 500);
            }
        } catch (error) {
            console.error('Error updating download count:', error);
        }
    }

    if (downloadBtn) {
        downloadBtn.addEventListener('click', handleDownload);
    }

    // Number animation utility
    function animateValue(obj, start, end, duration) {
        if (!obj) return;
        let startTimestamp = null;
        const step = (timestamp) => {
            if (!startTimestamp) startTimestamp = timestamp;
            const progress = Math.min((timestamp - startTimestamp) / duration, 1);
            obj.innerHTML = Math.floor(progress * (end - start) + start);
            if (progress < 1) {
                window.requestAnimationFrame(step);
            }
        };
        window.requestAnimationFrame(step);
    }

    updateCounters();

    // 2. Custom Cursor Follower
    const cursor = document.querySelector('.cursor');
    const follower = document.querySelector('.cursor-follower');

    document.addEventListener('mousemove', (e) => {
        cursor.style.left = e.clientX + 'px';
        cursor.style.top = e.clientY + 'px';

        // Add a slight delay for the follower
        setTimeout(() => {
            follower.style.left = e.clientX + 'px';
            follower.style.top = e.clientY + 'px';
        }, 80);
    });

    // Cursor effects on hover
    const links = document.querySelectorAll('a, button');
    links.forEach(link => {
        link.addEventListener('mouseenter', () => {
            cursor.style.transform = 'translate(-50%, -50%) scale(1.5)';
            cursor.style.backgroundColor = 'rgba(88, 166, 255, 0.1)';
        });
        link.addEventListener('mouseleave', () => {
            cursor.style.transform = 'translate(-50%, -50%) scale(1)';
            cursor.style.backgroundColor = 'transparent';
        });
    });

    // 3. Theme Toggle
    const themeToggle = document.querySelector('.theme-toggle');
    const icon = themeToggle.querySelector('i');

    // Check saved preference
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme === 'light') {
        document.body.setAttribute('data-theme', 'light');
        icon.classList.remove('fa-moon');
        icon.classList.add('fa-sun');
    }

    themeToggle.addEventListener('click', () => {
        const currentTheme = document.body.getAttribute('data-theme');
        if (currentTheme === 'light') {
            document.body.setAttribute('data-theme', 'dark');
            localStorage.setItem('theme', 'dark');
            icon.classList.remove('fa-sun');
            icon.classList.add('fa-moon');
        } else {
            document.body.setAttribute('data-theme', 'light');
            localStorage.setItem('theme', 'light');
            icon.classList.remove('fa-moon');
            icon.classList.add('fa-sun');
        }
    });

    // 4. Smooth Scrolling for Navigation
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            document.querySelector(this.getAttribute('href')).scrollIntoView({
                behavior: 'smooth'
            });
        });
    });

    // 5. Intersection Observer for Fade-in Animation
    const observerOptions = {
        threshold: 0.1
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
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

    // Add visible class styling dynamically
    const style = document.createElement('style');
    style.innerHTML = `
        .visible {
            opacity: 1 !important;
            transform: translateY(0) !important;
        }
    `;
    document.head.appendChild(style);

    // 6. Gallery Modal Logic
    const galleryBtn = document.getElementById('gallery-btn');
    const modal = document.getElementById('gallery-modal');
    const closeBtn = document.querySelector('.close-modal');
    const galleryGrid = document.getElementById('gallery-grid');
    const galleryApiEndpoint = 'https://970sm9mib1.execute-api.us-east-1.amazonaws.com/gallery'; // New Endpoint

    async function loadGallery() {
        galleryGrid.innerHTML = '<div class="gallery-loader">Loading photos...</div>';
        try {
            const response = await fetch(galleryApiEndpoint);
            if (!response.ok) throw new Error('API failed');
            const data = await response.json();

            galleryGrid.innerHTML = ''; // Clear loader

            if (data.images && data.images.length > 0) {
                data.images.forEach(url => {
                    const img = document.createElement('img');
                    img.src = url;
                    img.className = 'gallery-item';
                    img.alt = 'Project Screenshot';
                    img.onclick = () => window.open(url, '_blank'); // Open full size on click
                    galleryGrid.appendChild(img);
                });
            } else {
                galleryGrid.innerHTML = '<div class="gallery-loader">No photos found in gallery.</div>';
            }

        } catch (e) {
            console.error(e);
            galleryGrid.innerHTML = '<div class="gallery-loader error">Failed to load images.</div>';
        }
    }

    if (galleryBtn) {
        galleryBtn.addEventListener('click', (e) => {
            e.preventDefault();
            modal.style.display = 'block';
            loadGallery(); // Fetch images when opened
        });
    }

    if (closeBtn) {
        closeBtn.addEventListener('click', () => {
            modal.style.display = 'none';
        });
    }

    window.addEventListener('click', (e) => {
        if (e.target == modal) {
            modal.style.display = 'none';
        }
    });

});

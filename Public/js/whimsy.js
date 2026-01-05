document.addEventListener('DOMContentLoaded', () => {
    // Reveal animations on scroll
    const observerOptions = {
        threshold: 0.2
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
            }
        });
    }, observerOptions);

    document.querySelectorAll('.reveal').forEach(el => observer.observe(el));

    // Dynamic scale for nav on scroll
    const nav = document.querySelector('.nav-container');
    window.addEventListener('scroll', () => {
        if (window.scrollY > 50) {
            nav.style.transform = 'translateX(-50%) scale(0.9)';
            nav.style.opacity = '0.9';
        } else {
            nav.style.transform = 'translateX(-50%) scale(1)';
            nav.style.opacity = '1';
        }
    });

    // Whimsical Blob following mouse
    const blob = document.createElement('div');
    blob.className = 'whimsy-blob';
    document.body.appendChild(blob);

    let mouseX = 0, mouseY = 0;
    let blobX = 0, blobY = 0;

    window.addEventListener('mousemove', (e) => {
        mouseX = e.clientX;
        mouseY = e.clientY;
    });

    function animateBlob() {
        // Smooth easing for the blob
        blobX += (mouseX - blobX - 200) * 0.05;
        blobY += (mouseY - blobY - 200) * 0.05;
        blob.style.transform = `translate(${blobX}px, ${blobY}px)`;
        requestAnimationFrame(animateBlob);
    }
    animateBlob();

    // Whimsy touch: Parallax for target elements
    document.querySelectorAll('.parallax-target').forEach(target => {
        window.addEventListener('mousemove', (e) => {
            const moveX = (e.clientX - window.innerWidth / 2) * 0.02;
            const moveY = (e.clientY - window.innerHeight / 2) * 0.02;
            target.style.transform = `translate(${moveX}px, ${moveY}px)`;
        });
    });
});

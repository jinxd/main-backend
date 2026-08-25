(function () {
    // mark JS availability early so reveal styles only apply when they can complete
    document.documentElement.classList.add('js');

    var reducedMotion = window.matchMedia &&
        window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    /* ---------------- host branding ---------------- */

    // Brand the site per host:
    //   hannesnagel.com -> Hannes (original)
    //   chaaarlie.com   -> Charlie (transitional)
    //   jinxd.net       -> Jinxd (current; no Hannes/Charlie mentions)
    function hostSuffix(host, suffix) {
        return host === suffix || host.slice(-(suffix.length + 1)) === '.' + suffix;
    }
    function brandFor(host) {
        host = host || '';
        if (hostSuffix(host, 'jinxd.net')) return 'jinxd';
        if (hostSuffix(host, 'chaaarlie.com')) return 'charlie';
        return 'hannes';
    }

    var siteBrand = brandFor(window.location.hostname);

    var BRAND = {
        hannes: {
            name: 'Hannes Nagel',
            mark: 'hn.',
            label: 'hannesnagel home',
            mailDomain: 'hannesnagel.com',
            mastodon: 'https://mastodon.social/@hannesmnagel',
            github: 'https://github.com/jinxd'
        },
        charlie: {
            name: 'Charlie Nagel',
            mark: 'cn.',
            label: 'chaaarlie home',
            mailDomain: 'chaaarlie.com',
            mastodon: 'https://mastodon.social/@hannesmnagel',
            github: 'https://github.com/jinxd'
        },
        jinxd: {
            name: 'Jinxd',
            mark: 'jn.',
            label: 'jinxd home',
            mailDomain: 'jinxd.net',
            mastodon: 'https://woof.tech/@jinxd',
            github: 'https://github.com/jinxd'
        }
    };

    function applyHostBranding() {
        var brand = BRAND[siteBrand];
        if (!brand || siteBrand === 'hannes') {
            return;
        }
        // document title + meta description / og tags
        var rename = function (s) {
            if (siteBrand === 'jinxd') {
                return s
                    .replace(/https?:\/\/mastodon\.social\/@hannesmnagel/g, 'https://woof.tech/@jinxd')
                    .replace(/Hannes Nagel/g, 'Jinxd')
                    .replace(/Hannes/g, 'Jinxd')
                    .replace(/contact@hannesnagel\.com/g, 'fuckyou@jinxd.net')
                    .replace(/hannesnagel\.com/g, 'jinxd.net')
                    .replace(/hannesmnagel/g, 'jinxd')
                    .replace(/hannesnagel/g, 'jinxd');
            }
            return s
                .replace(/Hannes Nagel/g, 'Charlie Nagel')
                .replace(/Hannes/g, 'Charlie')
                .replace(/hannesnagel/g, 'chaaarlie');
        };
        if (document.title) {
            document.title = rename(document.title);
        }
        var metas = document.querySelectorAll('meta[name="description"], meta[property="og:title"], meta[property="og:description"], meta[property="og:url"], meta[property="og:image"]');
        for (var i = 0; i < metas.length; i++) {
            var c = metas[i].getAttribute('content');
            if (c) {
                metas[i].setAttribute('content', rename(c));
            }
        }
        // links - rewrite hrefs that point at the old identity (mailto: and any
        // other hannesnagel/hannesmnagel URL) so nothing on this host reveals it
        var links = document.querySelectorAll('a[href]');
        for (var m = 0; m < links.length; m++) {
            var h = links[m].getAttribute('href');
            if (h && (h.indexOf('hannesnagel') !== -1 || h.indexOf('hannesmnagel') !== -1)) {
                links[m].setAttribute('href', rename(h));
            }
        }
        if (document.title) {
            document.title = rename(document.title);
        }
        var metas = document.querySelectorAll('meta[name="description"], meta[property="og:title"], meta[property="og:description"], meta[property="og:url"], meta[property="og:image"]');
        for (var i = 0; i < metas.length; i++) {
            var c = metas[i].getAttribute('content');
            if (c) {
                metas[i].setAttribute('content', rename(c));
            }
        }
        // links - rewrite hrefs that point at the old domain (mailto: and any
        // other hannesnagel.com URL) so nothing on chaaarlie.com reveals it
        var links = document.querySelectorAll('a[href]');
        for (var m = 0; m < links.length; m++) {
            var h = links[m].getAttribute('href');
            if (h && h.indexOf('hannesnagel') !== -1) {
                links[m].setAttribute('href', rename(h));
            }
        }
        // visible text: walk text nodes, skip script/style
        var walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, {
            acceptNode: function (n) {
                var el = n.parentElement;
                if (!el || el.tagName === 'SCRIPT' || el.tagName === 'STYLE') {
                    return NodeFilter.FILTER_REJECT;
                }
                return NodeFilter.FILTER_ACCEPT;
            }
        });
        var nodes = [];
        var node;
        while ((node = walker.nextNode())) {
            nodes.push(node);
        }
        for (var j = 0; j < nodes.length; j++) {
            if (nodes[j].nodeValue.indexOf('Hannes') !== -1 || nodes[j].nodeValue.indexOf('hannesnagel') !== -1 || nodes[j].nodeValue.indexOf('hannesmnagel') !== -1) {
                nodes[j].nodeValue = rename(nodes[j].nodeValue);
            }
        }
    }

    /* ---------------- nav + footer ---------------- */

    function currentPath() {
        var p = window.location.pathname || '/';
        return p.endsWith('/') && p.length > 1 ? p.slice(0, -1) : p;
    }

    function activeKey(path) {
        if (path === '/' || path === '/home') {
            return 'home';
        }
        if (
            path === '/apps' ||
            path.startsWith('/containeye') ||
            path.startsWith('/ghost') ||
            path.startsWith('/recipes') ||
            path.startsWith('/i-told-you-so') ||
            path.startsWith('/podcatcher') ||
            path === '/superghost' ||
            path === '/joinGameInSuperghostApp' ||
            path === '/openapp'
        ) {
            return 'apps';
        }
        if (path === '/about') {
            return 'about';
        }
        if (path === '/contact') {
            return 'contact';
        }
        if (path === '/thoughts' || path.startsWith('/thoughts/')) {
            return 'thoughts';
        }
        return '';
    }

    function makeLink(href, label, active) {
        var cls = active ? 'nav-link active' : 'nav-link';
        return '<a href="' + href + '" class="' + cls + '">' + label + '</a>';
    }

    function renderNav() {
        var mount = document.getElementById('site-nav');
        if (!mount) {
            return;
        }

        var path = currentPath();
        var active = activeKey(path);
        var homeHref = path === '/' ? '/' : '/home';

        var links = [
            makeLink(homeHref, 'Home', active === 'home'),
            makeLink('/apps', 'Apps', active === 'apps'),
            makeLink('/thoughts/', 'Thoughts', active === 'thoughts'),
            makeLink('/about', 'About', active === 'about'),
            makeLink('/contact', 'Contact', active === 'contact')
        ];

        var brand = BRAND[siteBrand];
        var brandMark = brand.mark;
        var brandLabel = brand.label;
        mount.innerHTML = '<nav class="nav-container" aria-label="Main">' +
            '<a href="' + homeHref + '" class="nav-brand" aria-label="' + brandLabel + '">' +
            '<img src="/images/jinxd/logo-nav.svg" alt="jinxd" class="nav-logo">' +
            '</a>' +
            links.join('') +
            '</nav>';

        var brand = mount.querySelector('.nav-brand');
        if (brand) {
            brand.addEventListener('click', function (e) {
                if (reducedMotion) {
                    return;
                }
                brand.classList.remove('spinny');
                void brand.offsetWidth;
                brand.classList.add('spinny');
                confettiBurst(e.clientX || 40, e.clientY || 30, 26);
            });
        }
    }

    function renderFooter() {
        if (document.querySelector('.site-footer')) {
            return;
        }
        var footer = document.createElement('footer');
        footer.className = 'site-footer';
        var brand = BRAND[siteBrand];
        footer.innerHTML =
            '<span class="footer-name">' + brand.name + '</span>' +
            '<nav aria-label="Footer">' +
            '<a href="/apps">Apps</a>' +
            '<a href="/thoughts/">Thoughts</a>' +
            '<a href="/about">About</a>' +
            '<a href="/contact">Contact</a>' +
            '<a href="' + brand.mastodon + '" rel="me">Mastodon</a>' +
            '<a href="' + brand.github + '">GitHub</a>' +
            '</nav>' +
            '<span>&copy; ' + new Date().getFullYear() + ' &middot; built by jinxd</span>';
        document.body.appendChild(footer);
    }

    /* ---------------- reveal on scroll ---------------- */

    function setupReveals() {
        var main = document.querySelector('main');
        if (main) {
            var sections = main.querySelectorAll(':scope > section');
            for (var i = 0; i < sections.length; i++) {
                sections[i].classList.add('reveal');
            }
        }

        var targets = document.querySelectorAll('.reveal');
        if (!('IntersectionObserver' in window)) {
            for (var j = 0; j < targets.length; j++) {
                targets[j].classList.add('visible');
            }
            return;
        }

        var pending = 0;
        var observer = new IntersectionObserver(function (entries) {
            for (var k = 0; k < entries.length; k++) {
                if (entries[k].isIntersecting) {
                    var el = entries[k].target;
                    el.style.setProperty('--reveal-delay', Math.min(pending * 70, 280) + 'ms');
                    pending++;
                    el.classList.add('visible');
                    observer.unobserve(el);
                }
            }
            setTimeout(function () { pending = 0; }, 120);
        }, { threshold: 0.08, rootMargin: '0px 0px -4% 0px' });

        for (var m = 0; m < targets.length; m++) {
            observer.observe(targets[m]);
        }
    }

    /* ---------------- hero word pop-in ---------------- */

    function splitWords() {
        if (reducedMotion) {
            return;
        }
        var h1 = document.querySelector('.hero h1');
        if (!h1 || h1.classList.contains('splitty')) {
            return;
        }

        var index = 0;

        function wrapNode(node, container) {
            if (node.nodeType === Node.TEXT_NODE) {
                var parts = node.textContent.split(/(\s+)/);
                for (var i = 0; i < parts.length; i++) {
                    if (parts[i] === '') {
                        continue;
                    }
                    if (/^\s+$/.test(parts[i])) {
                        container.appendChild(document.createTextNode(' '));
                    } else {
                        var w = document.createElement('span');
                        w.className = 'w';
                        w.style.setProperty('--i', index++);
                        w.textContent = parts[i];
                        container.appendChild(w);
                    }
                }
            } else if (node.nodeType === Node.ELEMENT_NODE) {
                var holder = document.createElement('span');
                holder.className = 'w';
                holder.style.setProperty('--i', index++);
                holder.appendChild(node.cloneNode(true));
                container.appendChild(holder);
            }
        }

        var frag = document.createDocumentFragment();
        var nodes = Array.prototype.slice.call(h1.childNodes);
        for (var n = 0; n < nodes.length; n++) {
            wrapNode(nodes[n], frag);
        }
        h1.textContent = '';
        h1.appendChild(frag);
        h1.classList.add('splitty');

        // let the squiggle draw itself after the words land
        setTimeout(function () {
            h1.closest('section') && h1.closest('section').classList.add('squiggle-go');
        }, 400);
    }

    /* ---------------- tilt cards ---------------- */

    function setupTilt() {
        if (reducedMotion || !window.matchMedia('(hover: hover)').matches) {
            return;
        }
        var cards = document.querySelectorAll('.card');
        for (var i = 0; i < cards.length; i++) {
            (function (card) {
                var glare = document.createElement('span');
                glare.className = 'glare';
                card.appendChild(glare);

                card.addEventListener('pointermove', function (e) {
                    var r = card.getBoundingClientRect();
                    var px = (e.clientX - r.left) / r.width;
                    var py = (e.clientY - r.top) / r.height;
                    var rx = (0.5 - py) * 7;
                    var ry = (px - 0.5) * 7;
                    card.classList.add('tilting');
                    card.style.transform =
                        'perspective(900px) translateY(-4px) rotateX(' + rx.toFixed(2) +
                        'deg) rotateY(' + ry.toFixed(2) + 'deg)';
                    card.style.setProperty('--gx', (px * 100).toFixed(1) + '%');
                    card.style.setProperty('--gy', (py * 100).toFixed(1) + '%');
                });

                card.addEventListener('pointerleave', function () {
                    card.classList.remove('tilting');
                    card.style.transform = '';
                });
            })(cards[i]);
        }
    }

    /* ---------------- confetti ---------------- */

    var confettiColors = ['#0e6b54', '#bf5b34', '#e0b14c', '#7fc0ab', '#1d2421', '#fffdf8'];

    function confettiBurst(x, y, count) {
        if (reducedMotion) {
            return;
        }
        var canvas = document.createElement('canvas');
        canvas.style.cssText =
            'position:fixed;inset:0;pointer-events:none;z-index:9999;';
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;
        document.body.appendChild(canvas);
        var ctx = canvas.getContext('2d');

        var parts = [];
        for (var i = 0; i < (count || 60); i++) {
            var angle = Math.random() * Math.PI * 2;
            var speed = 4 + Math.random() * 7;
            parts.push({
                x: x,
                y: y,
                vx: Math.cos(angle) * speed,
                vy: Math.sin(angle) * speed - 4,
                rot: Math.random() * Math.PI,
                vr: (Math.random() - 0.5) * 0.3,
                size: 5 + Math.random() * 6,
                color: confettiColors[Math.floor(Math.random() * confettiColors.length)],
                shape: Math.random() < 0.3 ? 'circle' : 'rect',
                life: 1
            });
        }

        var start = performance.now();
        function frame(now) {
            var t = (now - start) / 1000;
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            var alive = false;
            for (var i = 0; i < parts.length; i++) {
                var p = parts[i];
                p.vy += 0.22;
                p.vx *= 0.99;
                p.x += p.vx;
                p.y += p.vy;
                p.rot += p.vr;
                p.life = Math.max(0, 1 - t / 1.6);
                if (p.life > 0 && p.y < canvas.height + 20) {
                    alive = true;
                    ctx.save();
                    ctx.globalAlpha = p.life;
                    ctx.translate(p.x, p.y);
                    ctx.rotate(p.rot);
                    ctx.fillStyle = p.color;
                    if (p.shape === 'circle') {
                        ctx.beginPath();
                        ctx.arc(0, 0, p.size / 2, 0, Math.PI * 2);
                        ctx.fill();
                    } else {
                        ctx.fillRect(-p.size / 2, -p.size / 4, p.size, p.size / 2);
                    }
                    ctx.restore();
                }
            }
            if (alive) {
                requestAnimationFrame(frame);
            } else {
                canvas.remove();
            }
        }
        requestAnimationFrame(frame);
    }

    // let page-specific scripts throw confetti too
    window.hnConfetti = confettiBurst;

    function setupConfettiTriggers() {
        var pill = document.querySelector('.status-pill');
        if (pill) {
            pill.addEventListener('click', function (e) {
                confettiBurst(e.clientX, e.clientY, 70);
            });
        }
    }

    /* ---------------- doodle parallax ---------------- */

    function setupParallax() {
        if (reducedMotion || !window.matchMedia('(hover: hover)').matches) {
            return;
        }
        var doodles = document.querySelectorAll('.doodle');
        if (!doodles.length) {
            return;
        }
        var raf = null;
        window.addEventListener('pointermove', function (e) {
            if (raf) {
                return;
            }
            raf = requestAnimationFrame(function () {
                var cx = e.clientX / window.innerWidth - 0.5;
                var cy = e.clientY / window.innerHeight - 0.5;
                for (var i = 0; i < doodles.length; i++) {
                    var depth = parseFloat(doodles[i].getAttribute('data-depth') || '12');
                    doodles[i].style.transform =
                        'translate(' + (-cx * depth).toFixed(1) + 'px,' + (-cy * depth).toFixed(1) + 'px)';
                }
                raf = null;
            });
        }, { passive: true });
    }

    /* ---------------- ghost buddy ---------------- */

    function setupGhost() {
        var home = document.querySelector('.footer-cta');
        if (!home) {
            return;
        }
        var btn = document.createElement('button');
        btn.className = 'ghost-buddy';
        btn.type = 'button';
        btn.setAttribute('aria-label', 'A friendly ghost. Click it!');
        btn.innerHTML =
            '<svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">' +
            '<path d="M32 5C18.7 5 10 16 10 29.5V52c0 3.1 3.8 4.3 5.9 2.2l3.6-3.6 4.6 4.6c1.6 1.6 4.2 1.6 5.8 0l2.1-2.1 2.1 2.1c1.6 1.6 4.2 1.6 5.8 0l4.6-4.6 3.6 3.6c2.1 2.1 5.9 0.9 5.9-2.2V29.5C54 16 45.3 5 32 5z" fill="#fffdf8"/>' +
            '<g class="eye"><circle cx="24.5" cy="28" r="4.6" fill="#fff"/><circle class="pupil" cx="24.5" cy="28" r="2.6" fill="#1d2421"/></g>' +
            '<g class="eye"><circle cx="39.5" cy="28" r="4.6" fill="#fff"/><circle class="pupil" cx="39.5" cy="28" r="2.6" fill="#1d2421"/></g>' +
            '<circle cx="20" cy="35" r="2.6" fill="#e8a8a0" opacity="0.7"/>' +
            '<circle cx="44" cy="35" r="2.6" fill="#e8a8a0" opacity="0.7"/>' +
            '<path d="M28.5 38.5c2 2.2 5 2.2 7 0" stroke="#1d2421" stroke-width="2" stroke-linecap="round" fill="none"/>' +
            '</svg>';
        home.appendChild(btn);

        btn.addEventListener('click', function (e) {
            btn.classList.remove('boo');
            void btn.offsetWidth;
            btn.classList.add('boo');
            var r = btn.getBoundingClientRect();
            confettiBurst(r.left + r.width / 2, r.top + r.height / 2, 50);
        });

        if (reducedMotion || !window.matchMedia('(hover: hover)').matches) {
            return;
        }
        // pupils follow the cursor
        var pupils = btn.querySelectorAll('.pupil');
        var raf = null;
        window.addEventListener('pointermove', function (e) {
            if (raf) {
                return;
            }
            raf = requestAnimationFrame(function () {
                var r = btn.getBoundingClientRect();
                var cx = r.left + r.width / 2;
                var cy = r.top + r.height / 2;
                var dx = e.clientX - cx;
                var dy = e.clientY - cy;
                var d = Math.sqrt(dx * dx + dy * dy) || 1;
                var m = Math.min(d / 40, 1) * 2.4;
                var tx = (dx / d) * m;
                var ty = (dy / d) * m;
                for (var i = 0; i < pupils.length; i++) {
                    pupils[i].style.transform = 'translate(' + tx.toFixed(1) + 'px,' + ty.toFixed(1) + 'px)';
                }
                raf = null;
            });
        }, { passive: true });
    }

    /* ---------------- tab title easter egg ---------------- */

    function setupTabWink() {
        var original = null;
        document.addEventListener('visibilitychange', function () {
            if (document.hidden) {
                original = document.title;
                document.title = 'pssst… come back';
            } else if (original) {
                document.title = original;
            }
        });
    }

    /* ---------------- corner mascot (follows the mouse) ---------------- */

    function setupMascot() {
        var host = window.location.hostname || '';
        // skip the hannesnagel.com host (legacy) - mascot is jinxd identity
        var m = document.createElement('div');
        m.className = 'jinxd-mascot';
        m.setAttribute('aria-hidden', 'true');
        m.innerHTML =
            '<img src="/images/jinxd/logo-nav.svg" alt="">' +
            '<span class="m-eye m-eye-l"><i></i></span>' +
            '<span class="m-eye m-eye-r"><i></i></span>';
        document.body.appendChild(m);

        var pupils = m.querySelectorAll('.m-eye i');
        var eyes = m.querySelectorAll('.m-eye');
        if (!pupils.length || !window.matchMedia('(hover: hover)').matches) {
            return;
        }

        var maxDx = 6.5;
        var maxDy = 6.5;

        window.addEventListener('pointermove', function (e) {
            for (var i = 0; i < eyes.length; i++) {
                var r = eyes[i].getBoundingClientRect();
                var cx = r.left + r.width / 2;
                var cy = r.top + r.height / 2;
                var dx = e.clientX - cx;
                var dy = e.clientY - cy;
                var d = Math.sqrt(dx * dx + dy * dy) || 1;
                var m2 = Math.min(d / 60, 1);
                var tx = (dx / d) * maxDx * m2;
                var ty = (dy / d) * maxDy * m2;
                pupils[i].style.transform = 'translate(' + tx.toFixed(2) + 'px,' + ty.toFixed(2) + 'px)';
            }
        }, { passive: true });
    }

    /* ---------------- init ---------------- */

    function init() {
        applyHostBranding();
        renderNav();
        renderFooter();
        setupReveals();
        splitWords();
        setupTilt();
        setupConfettiTriggers();
        setupParallax();
        setupGhost();
        setupTabWink();
        setupMascot();
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();

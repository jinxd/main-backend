(function () {
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

        mount.innerHTML = '<nav class="nav-container">' + links.join('') + '</nav>';
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', renderNav);
    } else {
        renderNav();
    }
})();

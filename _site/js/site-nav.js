document.addEventListener('DOMContentLoaded', () => {
    const toggle = document.getElementById('nav-toggle');
    const mobileNav = document.getElementById('mobile-nav');
    const closeBtn = document.getElementById('mobile-nav-close');

    function openNav() {
        mobileNav.classList.add('is-open');
        mobileNav.setAttribute('aria-hidden', 'false');
        toggle.setAttribute('aria-expanded', 'true');
        document.body.style.overflow = 'hidden';
    }

    function closeNav() {
        mobileNav.classList.remove('is-open');
        mobileNav.setAttribute('aria-hidden', 'true');
        toggle.setAttribute('aria-expanded', 'false');
        document.body.style.overflow = '';
    }

    toggle?.addEventListener('click', openNav);
    closeBtn?.addEventListener('click', closeNav);

    mobileNav?.querySelectorAll('a').forEach(link => {
        link.addEventListener('click', closeNav);
    });

    document.addEventListener('keydown', e => {
        if (e.key === 'Escape') closeNav();
    });
});

// Contact modal
document.addEventListener('DOMContentLoaded', () => {
    const modal = document.getElementById('modal-contact');
    if (!modal) return;

    const content = modal.querySelector('.modal-content');
    const closeBtn = modal.querySelector('.modal-close');
    const triggers = document.querySelectorAll('[data-modal-open="modal-contact"]');
    let lastTrigger = null;

    function openModal(trigger) {
        lastTrigger = trigger;
        modal.removeAttribute('inert');
        modal.setAttribute('aria-hidden', 'false');
        document.body.style.overflow = 'hidden';

        requestAnimationFrame(() => {
            content.classList.remove('animate-in');
            void content.offsetWidth;
            content.classList.add('animate-in');
        });

        closeBtn.focus();
    }

    function closeModal() {
        modal.setAttribute('inert', '');
        modal.setAttribute('aria-hidden', 'true');
        document.body.style.overflow = '';
        content.classList.remove('animate-in');

        if (lastTrigger) lastTrigger.focus();
    }

    triggers.forEach(trigger => {
        trigger.addEventListener('click', e => {
            e.preventDefault();
            openModal(trigger);
        });
    });

    closeBtn?.addEventListener('click', closeModal);

    modal.addEventListener('click', e => {
        if (e.target === modal) closeModal();
    });

    document.addEventListener('keydown', e => {
        if (e.key === 'Escape' && modal.getAttribute('aria-hidden') === 'false') closeModal();
    });
});

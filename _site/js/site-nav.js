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

// Contact forms (submitted via Formspree) — redirect to /thanks/ on success,
// since custom redirects aren't available on Formspree's free plan.
document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('.formspree-form').forEach(form => {
        const submitBtn = form.querySelector('button[type="submit"]');
        const submitLabel = submitBtn?.textContent;

        const status = document.createElement('p');
        status.className = 'form-status';
        status.setAttribute('aria-live', 'polite');
        form.appendChild(status);

        form.addEventListener('submit', async e => {
            e.preventDefault();

            status.textContent = '';
            if (submitBtn) {
                submitBtn.disabled = true;
                submitBtn.textContent = 'Sending…';
            }

            try {
                const response = await fetch(form.action, {
                    method: 'POST',
                    body: new FormData(form),
                    headers: { 'Accept': 'application/json' }
                });

                if (response.ok) {
                    window.location.href = '/thanks/';
                    return;
                }

                const data = await response.json().catch(() => null);
                const message = data?.errors?.map(err => err.message).join(', ');
                status.textContent = message || 'Something went wrong. Please try again in a moment.';
            } catch (err) {
                status.textContent = 'Something went wrong. Please try again in a moment.';
            }

            if (submitBtn) {
                submitBtn.disabled = false;
                submitBtn.textContent = submitLabel;
            }
        });
    });
});

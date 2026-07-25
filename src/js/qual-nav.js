document.addEventListener('DOMContentLoaded', () => {
  // --- Principle flip cards ---
  const allPrincipleCards = document.querySelectorAll('.preamble-remaining .principle-card');

  const flipCard = (card) => {
    const flipped = card.classList.toggle('is-flipped');
    card.querySelector('.principle-front')?.setAttribute('aria-hidden', String(flipped));
    card.querySelector('.principle-back')?.setAttribute('aria-hidden', String(!flipped));
    if (flipped) {
      allPrincipleCards.forEach(other => {
        if (other !== card && other.classList.contains('is-flipped')) {
          other.classList.remove('is-flipped');
          other.querySelector('.principle-front')?.setAttribute('aria-hidden', 'false');
          other.querySelector('.principle-back')?.setAttribute('aria-hidden', 'true');
        }
      });
    }
  };

  allPrincipleCards.forEach(card => {
    card.addEventListener('click', () => flipCard(card));
    card.addEventListener('keydown', e => {
      if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); flipCard(card); }
    });
  });

  // --- Paper accordion ---
  document.querySelectorAll('.paper-header').forEach(header => {
    header.addEventListener('click', () => {
      const expanded = header.getAttribute('aria-expanded') === 'true';
      const bodyId = header.getAttribute('aria-controls');
      const body = document.getElementById(bodyId);
      const paper = header.closest('.paper');

      header.setAttribute('aria-expanded', String(!expanded));
      if (body) body.hidden = expanded;
      paper.classList.toggle('is-open', !expanded);
    });

    header.addEventListener('keydown', e => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        header.click();
      }
    });
  });

  // --- Mobile sidebar ---
  const sidebar = document.querySelector('.sidebar');
  const overlay = document.querySelector('.sidebar-overlay');
  const menuBtn = document.querySelector('.mobile-menu-btn');

  function closeSidebar() {
    sidebar.classList.remove('is-open');
    overlay.classList.remove('is-visible');
    document.body.style.overflow = '';
  }

  // --- Smooth scroll + auto-expand papers from nav ---
  document.querySelectorAll('a[href^="#"]').forEach(link => {
    link.addEventListener('click', e => {
      const id = link.getAttribute('href').slice(1);
      const target = document.getElementById(id);
      if (!target) return;
      e.preventDefault();

      closeSidebar();

      target.scrollIntoView({ behavior: 'smooth', block: 'start' });

      // Auto-expand paper cards when linked directly
      if (target.classList.contains('paper')) {
        const h = target.querySelector('.paper-header');
        if (h && h.getAttribute('aria-expanded') === 'false') {
          setTimeout(() => h.click(), 350);
        }
      }
    });
  });

  menuBtn?.addEventListener('click', () => {
    const isOpen = sidebar.classList.contains('is-open');
    if (isOpen) {
      closeSidebar();
    } else {
      sidebar.classList.add('is-open');
      overlay.classList.add('is-visible');
      document.body.style.overflow = 'hidden';
    }
  });

  overlay?.addEventListener('click', closeSidebar);
  document.querySelector('.sidebar-close')?.addEventListener('click', closeSidebar);

  // --- Intersection Observer for active nav state ---
  const sections = document.querySelectorAll('[data-section]');
  const navLinks = document.querySelectorAll('[data-nav]');

  const setActive = id => {
    navLinks.forEach(link => {
      link.classList.toggle('active', link.getAttribute('data-nav') === id);
    });
  };

  const observer = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        setActive(entry.target.getAttribute('data-section'));
      }
    });
  }, {
    rootMargin: '-10% 0px -70% 0px',
    threshold: 0,
  });

  sections.forEach(s => observer.observe(s));
});

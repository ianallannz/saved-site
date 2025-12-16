  const hamburger = document.querySelector('.hamburger');
  const nav = document.querySelector('.prop-nav');

  // Toggle nav when hamburger is clicked
  hamburger.addEventListener('click', () => {
    const expanded = hamburger.getAttribute('aria-expanded') === 'true';
    hamburger.setAttribute('aria-expanded', !expanded);
    nav.classList.toggle('open');
  });

  // Close nav when any link inside it is clicked
  nav.querySelectorAll('a').forEach(link => {
    link.addEventListener('click', () => {
      nav.classList.remove('open');
      hamburger.setAttribute('aria-expanded', false);
    });
  });


  window.addEventListener('scroll', () => {
    // Adjust this threshold (e.g. 50px) to taste
    const threshold = 50;

    if (window.scrollY <= threshold && window.location.hash) {
      history.replaceState(null, null, window.location.pathname + window.location.search);
    }
  });


  const headings = document.querySelectorAll('h2[id], h3[id], h4[id]');
  const navLinks = document.querySelectorAll('#prop-nav ul li a');

  // Mark the very first nav link as active by default
  if (navLinks.length > 0) {
    navLinks[0].classList.add('active');
  }

  const observer = new IntersectionObserver(
    entries => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          const id = entry.target.getAttribute('id');
          navLinks.forEach(link => {
            link.classList.remove('active');
            if (link.getAttribute('href') === '#' + id) {
              link.classList.add('active');
            }
          });
        }
      });
    },
    {
      root: null,
      rootMargin: '0px 0px -70% 0px',
      threshold: 0
    }
  );

  headings.forEach(h => observer.observe(h));

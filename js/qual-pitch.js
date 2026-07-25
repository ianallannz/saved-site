document.addEventListener('DOMContentLoaded', () => {
  const deck = document.querySelector('.deck');
  const slides = Array.from(document.querySelectorAll('.slide'));
  const dots = Array.from(document.querySelectorAll('.deck-dot'));
  const counter = document.querySelector('.deck-counter-current');
  const prevBtn = document.querySelector('.deck-prev');
  const nextBtn = document.querySelector('.deck-next');

  if (!deck || slides.length === 0) return;

  let currentIndex = 0;

  const setActive = index => {
    currentIndex = index;
    dots.forEach((dot, i) => dot.classList.toggle('active', i === index));
    if (counter) counter.textContent = index + 1;
    history.replaceState(null, null, '#' + slides[index].id);
  };

  const goToSlide = (index, behavior = 'smooth') => {
    if (index < 0 || index >= slides.length) return;
    // Update state immediately so rapid clicks chain off the requested
    // index rather than the last index the scroll observer confirmed.
    setActive(index);
    slides[index].scrollIntoView({ behavior, block: 'start' });
  };

  // Track the active slide as the user scrolls/swipes
  const observer = new IntersectionObserver(
    entries => {
      entries.forEach(entry => {
        if (entry.isIntersecting && entry.intersectionRatio >= 0.6) {
          setActive(slides.indexOf(entry.target));
        }
      });
    },
    { root: deck, threshold: 0.6 }
  );
  slides.forEach(slide => observer.observe(slide));

  // Dot navigation
  dots.forEach((dot, i) => {
    dot.addEventListener('click', () => goToSlide(i));
  });

  // Prev/next arrows
  prevBtn?.addEventListener('click', () => goToSlide(currentIndex - 1));
  nextBtn?.addEventListener('click', () => goToSlide(currentIndex + 1));

  // Keyboard navigation — ignore keystrokes aimed at form fields (e.g. the
  // contact modal), so typing/arrow-keys/space work normally there instead
  // of being hijacked to change slides.
  document.addEventListener('keydown', e => {
    const target = e.target;
    const isFormField = target instanceof HTMLElement && (
      target.tagName === 'INPUT' ||
      target.tagName === 'TEXTAREA' ||
      target.tagName === 'SELECT' ||
      target.isContentEditable
    );
    if (isFormField) return;

    switch (e.key) {
      case 'ArrowDown':
      case 'ArrowRight':
      case ' ':
        e.preventDefault();
        goToSlide(currentIndex + 1);
        break;
      case 'ArrowUp':
      case 'ArrowLeft':
        e.preventDefault();
        goToSlide(currentIndex - 1);
        break;
      case 'Home':
        e.preventDefault();
        goToSlide(0);
        break;
      case 'End':
        e.preventDefault();
        goToSlide(slides.length - 1);
        break;
    }
  });

  // Land on the linked slide immediately (no animation) if the URL has a hash
  const initialIndex = slides.findIndex(s => s.id === location.hash.slice(1));
  if (initialIndex > 0) {
    goToSlide(initialIndex, 'auto');
    setActive(initialIndex);
  } else {
    setActive(0);
  }
});

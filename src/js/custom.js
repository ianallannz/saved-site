const logoRight = document.querySelector('.logo-right');
const bgEl = logoRight.querySelector('.bg');
const images = [
  'images/logo-bg01.jpg',
  'images/logo-bg02.jpg',
  'images/logo-bg03.jpg',
  'images/logo-bg04.jpg',
  'images/logo-bg05.jpg'
];

let index = 0;

// Preload images
const preloaded = [];
images.forEach(src => {
  const img = new Image();
  img.src = src;
  preloaded.push(img);
});


function runCycle() {
  // set next background
  bgEl.style.backgroundImage = `url(${images[index]})`;

  // reset instantly off-screen left (no transition)
  bgEl.style.transition = 'none';
  bgEl.style.transform = 'translateX(-100%)';

  // force reflow
  void bgEl.offsetWidth;

  // mark logo as active (invert mode)
  logoRight.classList.add('active');

  // slide in over 0.5s
  bgEl.style.transition = 'transform 0.4s ease-out';
  bgEl.style.transform = 'translateX(0)';

  // hold 2s, then slide out right over 1s
  setTimeout(() => {
    // remove active immediately when slide-out begins
    logoRight.classList.remove('active');

    bgEl.style.transition = 'transform 0.4s ease-in';
    bgEl.style.transform = 'translateX(101%)'; // overshoot exit
  }, 2000);

  // advance index
  index = (index + 1) % images.length;

  // schedule next cycle with pause
  const cycleDuration = 3500; // 0.5s in + 2s hold + 1s out
  const pause = 1500;         // extra gap between cycles
  setTimeout(runCycle, cycleDuration + pause);
}

// initial delay before first run
setTimeout(runCycle, 1000);


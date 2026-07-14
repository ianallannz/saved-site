const logoRight = document.querySelector('.logo-right');
const bgEl = logoRight?.querySelector('.bg');

if (logoRight && bgEl) {
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
}


document.addEventListener("DOMContentLoaded", () => {
    const a = document.getElementById("screen-a");
    const b = document.getElementById("screen-b");
    if (!a || !b) return;

    const images = [
        "/images/bluefin-windows-10-disaster.jpg",
        "/images/bluefin-windows-10-disaster-workspace.jpg",
        "/images/bluefin-favourite-web-apps.jpg",
        "/images/bluefin-workspace-power.jpg",
        "/images/bluefin-ms-office.jpg",
        "/images/bluefin-easy-access.jpg",
        "/images/bluefin-familiar-menu.jpg",
        "/images/bluefin-signed-in.jpg",
        "/images/bluefin-sign-in.jpg"
    ];

    let index = 0;
    let showingA = true;

    function crossfade() {
        const nextIndex = (index + 1) % images.length;

        if (showingA) {
            // prepare B
            b.setAttribute("href", images[nextIndex]);
            b.style.opacity = 1;   // fade B in
            a.style.opacity = 0;   // fade A out
        } else {
            // prepare A
            a.setAttribute("href", images[nextIndex]);
            a.style.opacity = 1;   // fade A in
            b.style.opacity = 0;   // fade B out
        }

        showingA = !showingA;
        index = nextIndex;
    }

    setInterval(crossfade, 4000);
});

// "Go back" link on the thanks page — return to whatever page sent them here.
// Only intercept when we can confirm they actually arrived from this site;
// history.length alone isn't reliable (browsers count a fresh tab differently).
document.addEventListener("DOMContentLoaded", () => {
    const goBack = document.getElementById("go-back");
    if (!goBack) return;

    let cameFromSite = false;
    try {
        cameFromSite = document.referrer && new URL(document.referrer).origin === window.location.origin;
    } catch (err) {
        cameFromSite = false;
    }

    if (cameFromSite) {
        goBack.addEventListener("click", e => {
            e.preventDefault();
            window.history.back();
        });
    }
});

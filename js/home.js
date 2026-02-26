(function ($) {
  'use strict';

  $(document).ready(function () {
    $('.button-collapse').sideNav({ closeOnClick: true });

    $('a[href*="#"]:not([href="#"])').on('click', function () {
      if (location.pathname.replace(/^\//, '') === this.pathname.replace(/^\//, '') && location.hostname === this.hostname) {
        var target = $(this.hash);
        var headerHeight = $('body').find('header').height();
        target = target.length ? target : $('[name=' + this.hash.slice(1) + ']');
        if (target.length) {
          $('html,body').animate({ scrollTop: target.offset().top - (headerHeight + 5) }, 1000);
          return false;
        }
      }
      return true;
    });
  });
})(jQuery);

function closeSideNav() {
  jQuery('.button-collapse').sideNav('hide');
}

const DARK_THEME = 'dark';
const LIGHT_THEME = 'light';
let manualThemeOverride = false;

function getSystemTheme() {
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? DARK_THEME : LIGHT_THEME;
}

function updateThemeControl(theme) {
  const toggle = document.querySelector('.theme-toggle');
  const themeIcon = toggle ? toggle.querySelector('i') : null;
  if (!toggle || !themeIcon) {
    return;
  }

  themeIcon.textContent = theme === DARK_THEME ? 'light_mode' : 'dark_mode';
  toggle.setAttribute('title', theme === DARK_THEME ? 'Theme: Dark' : 'Theme: Light');
  toggle.setAttribute('aria-label', theme === DARK_THEME ? 'Theme: dark' : 'Theme: light');
}

function applyTheme(theme) {
  document.documentElement.setAttribute('data-theme', theme);
  updateThemeControl(theme);
}

function toggleTheme() {
  const currentTheme = document.documentElement.getAttribute('data-theme') === DARK_THEME ? DARK_THEME : LIGHT_THEME;
  const nextTheme = currentTheme === DARK_THEME ? LIGHT_THEME : DARK_THEME;
  manualThemeOverride = true;
  applyTheme(nextTheme);
}

document.addEventListener('DOMContentLoaded', function () {
  manualThemeOverride = false;
  applyTheme(getSystemTheme());

  const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
  const handleThemeChange = function () {
    if (!manualThemeOverride) {
      applyTheme(getSystemTheme());
    }
  };

  if (typeof mediaQuery.addEventListener === 'function') {
    mediaQuery.addEventListener('change', handleThemeChange);
  } else if (typeof mediaQuery.addListener === 'function') {
    mediaQuery.addListener(handleThemeChange);
  }

  document.querySelectorAll('img').forEach(function (img) {
    if (img.complete) {
      img.classList.add('loaded');
    } else {
      img.addEventListener('load', function () {
        this.classList.add('loaded');
      });
    }
  });
});

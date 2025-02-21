// ==UserScript==
// @name         Reddit Automatic Dark Mode
// @version      2025-02-20
// @description  Switches Reddit cark mode on and off according to System Theme (if exposed by browser).
// @author       Duy Pham
// @match        *://*.reddit.com/*
// @icon         https://www.redditstatic.com/shreddit/assets/favicon/64x64.png
// @grant        none
// @license      MIT
// ==/UserScript==

// jshint esversion:11
(function() {
  'use strict';

  // Determine the preferred theme based on system settings.
  const getPreferredTheme = () => window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  const userDrawerButton = document.getElementById("expand-user-drawer-button");

  let first_time = false;
  if (!document.getElementsByName("darkmode-switch-name")[0]) {
    if (userDrawerButton) {
      userDrawerButton.click();
      first_time = true;
    } else {
      return console.error("Profile drawer button not found!");
    }
  }

  setTimeout(() => {
    const darkModeToggle = document.getElementsByName("darkmode-switch-name")[0];
    if (!darkModeToggle) {
      return console.error("Dark mode toggle not found!");
    }

    // Check Reddit's current theme based on the aria-checked attribute.
    const getRedditTheme = () => darkModeToggle.attributes["aria-checked"]?.value === "true" ? 'dark' : 'light';

    // If the current theme doesn't match the preferred theme, simulate a click.
    const applyPreferredTheme = () => {
      if (getRedditTheme() !== getPreferredTheme()) {
        darkModeToggle.click();
      }
      if (first_time) {
        setTimeout(() => {
          userDrawerButton.click();
        }, 500);
        first_time = false;
      }
    };

    // Listen for changes in system theme preference.
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', applyPreferredTheme);
    // Apply the theme immediately.
    applyPreferredTheme();
  }, 500) // Adjust the delay if necessary to ensure the drawer and toggle have loaded.

})();

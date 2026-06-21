const links = document.querySelectorAll('[data-tab]');
const tabs = document.querySelectorAll('.tab');

function showTab(target) {
  tabs.forEach(t => t.classList.remove('active'));
  const el = document.getElementById(target);
  if (el) el.classList.add('active');
}

links.forEach(link => {
  link.addEventListener('click', e => {
    e.preventDefault();
    showTab(link.dataset.tab);
  });
});

// support deep-linking via hash e.g. ryanperkins.dev#projects
const hash = window.location.hash.replace('#', '');
if (hash) showTab(hash);

const links = document.querySelectorAll('[data-tab]');
const tabs = document.querySelectorAll('.tab');

links.forEach(link => {
  link.addEventListener('click', e => {
    e.preventDefault();

    const target = link.dataset.tab;

    links.forEach(l => l.classList.remove('active'));
    tabs.forEach(t => t.classList.remove('active'));

    link.classList.add('active');
    document.getElementById(target).classList.add('active');
  });
});

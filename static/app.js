// Small progressive enhancements. Every page still works without JavaScript.
document.addEventListener("DOMContentLoaded", () => {
  // Selects marked data-autosubmit submit their form when changed.
  document.querySelectorAll("[data-autosubmit]").forEach(el =>
    el.addEventListener("change", () => el.form.submit()));

  // Forms marked data-confirm ask before destructive actions.
  document.querySelectorAll("form[data-confirm]").forEach(f =>
    f.addEventListener("submit", e => { if (!confirm(f.dataset.confirm)) e.preventDefault(); }));

  // Run form: only show the Level picker for per-level categories.
  const cat = document.getElementById("category");
  const wrap = document.getElementById("level-wrap");
  if (cat && wrap) {
    const sync = () => {
      const perLevel = cat.selectedOptions[0] && cat.selectedOptions[0].dataset.type === "per level";
      wrap.hidden = !perLevel;
      wrap.querySelector("select").required = perLevel;
    };
    cat.addEventListener("change", sync);
    sync();
  }

  // Theme toggle (remembered per browser; works without storage).
  document.querySelectorAll("#theme-toggle").forEach(btn => btn.addEventListener("click", () => {
    const root = document.documentElement;
    const current = root.dataset.theme || (matchMedia("(prefers-color-scheme: light)").matches ? "light" : "dark");
    const next = current === "light" ? "dark" : "light";
    root.dataset.theme = next;
    try { localStorage.setItem("theme", next); } catch (e) { /* storage blocked */ }
  }));

  // Close the account menu when clicking elsewhere.
  document.addEventListener("click", e => {
    document.querySelectorAll("details.menu[open]").forEach(d => { if (!d.contains(e.target)) d.removeAttribute("open"); });
  });
});

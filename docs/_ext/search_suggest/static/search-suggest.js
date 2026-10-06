// Dropdown of suggestions under the search box (data: suggestions-data.js).
(() => {
  // Site root, from this script's own URL (<root>/_static/search-suggest.js): the
  // suggestion URLs are relative to it, whatever the depth of the current page.
  const ROOT = new URL("..", document.currentScript.src).href;
  const LIMIT = 10;
  const BADGE = {page: "page", module: "module", section: "§", cmd: "cmd", attribute: "attr", type: "type", val: "val", exception: "exn"};
  const CODE = new Set(["module", "type", "val", "exception"]);
  const RANK = {page: 0, module: 0, cmd: 1, attribute: 1, type: 2, val: 2, exception: 2, section: 3};

  const score = (q, label) => {
    const l = label.toLowerCase(), last = l.slice(l.lastIndexOf(".") + 1);
    if (l.startsWith(q)) return 0;
    if (last.startsWith(q)) return 1;
    if (l.includes(q)) return 2;
    const words = q.split(/\s+/);
    return words.length > 1 && words.every(w => l.includes(w)) ? 3 : -1;
  };

  const search = q => {
    q = q.trim().toLowerCase();
    if (!q) return [];
    const hits = [];
    for (const e of window.CAMLTAC_SUGGESTIONS || []) {
      const s = score(q, e[1]);
      if (s >= 0) hits.push({e, s});
    }
    hits.sort((a, b) => a.s - b.s || RANK[a.e[0]] - RANK[b.e[0]] || a.e[1].length - b.e[1].length);
    return hits.slice(0, LIMIT).map(h => h.e);
  };

  const init = () => {
    const input = document.querySelector(".searchbox input[name=q]");
    if (!input) return;
    const box = input.form;
    const list = document.createElement("ul");
    list.className = "search-suggest";
    list.id = "search-suggest-list";
    list.setAttribute("role", "listbox");
    list.hidden = true;
    box.appendChild(list);
    input.setAttribute("autocomplete", "off");
    input.setAttribute("aria-controls", list.id);
    input.setAttribute("aria-autocomplete", "list");

    let items = [], active = -1;
    const select = i => {
      active = items.length ? (i + items.length) % items.length : -1;
      [...list.children].forEach((li, j) => li.setAttribute("aria-selected", j === active));
      if (active >= 0) list.children[active].scrollIntoView({block: "nearest"});
    };
    const render = () => {
      items = search(input.value);
      list.replaceChildren(...items.map(([kind, label, url, page]) => {
        const li = document.createElement("li");
        li.setAttribute("role", "option");
        const a = document.createElement("a");
        a.href = new URL(url, ROOT).href;
        a.tabIndex = -1;
        const badge = document.createElement("span");
        badge.className = "badge badge-" + kind;
        badge.textContent = BADGE[kind];
        const text = document.createElement("span");
        text.className = "label";
        if (CODE.has(kind)) {
          const dot = label.lastIndexOf(".");
          const name = document.createElement("code");
          name.textContent = label.slice(dot + 1);
          const where = document.createElement("span");
          where.className = "where";
          where.textContent = `${label.slice(0, dot)}`;
          text.append(name, where);
        } else if (page) {
          const name = document.createElement("span");
          name.textContent = label;
          const where = document.createElement("span");
          where.className = "where";
          where.textContent = page;
          text.append(name, where);
        } else {
          text.textContent = label;
        }
        a.append(badge, text);
        li.appendChild(a);
        li.addEventListener("mousedown", ev => ev.preventDefault()); // keep focus for the click
        return li;
      }));
      list.hidden = !items.length;
      select(0);
    };

    input.addEventListener("input", render);
    input.addEventListener("focus", render);
    input.addEventListener("blur", () => { list.hidden = true; });
    input.addEventListener("keydown", ev => {
      if (list.hidden) return;
      if (ev.key === "ArrowDown") { ev.preventDefault(); select(active + 1); }
      else if (ev.key === "ArrowUp") { ev.preventDefault(); select(active - 1); }
      else if (ev.key === "Escape") { list.hidden = true; }
      else if (ev.key === "Enter" && active >= 0) {
        ev.preventDefault();
        location.href = list.children[active].firstChild.href;
      }
    });
  };

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();
})();

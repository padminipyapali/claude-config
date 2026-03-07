/**
 * Claude Mockup Annotation Toolkit
 * Drop into any HTML mockup to enable element-level annotations.
 * Saves structured JSON feedback for Claude Code to read.
 */
(function () {
  "use strict";
  if (window.__claudeAnnotator) return;
  window.__claudeAnnotator = true;

  const FEEDBACK_FILENAME = "claude-feedback.json";

  // ── State ──────────────────────────────────────────────
  const state = {
    active: false,
    annotations: [],
    nextId: 1,
    selected: null, // currently editing annotation id
    hovered: null,  // DOM element under cursor
  };

  // ── Selector generation ────────────────────────────────
  function getSelector(el) {
    if (el.id) return `#${el.id}`;
    const path = [];
    let node = el;
    while (node && node !== document.body && node !== document.documentElement) {
      let seg = node.tagName.toLowerCase();
      if (node.id) { path.unshift(`#${node.id}`); break; }
      if (node.className && typeof node.className === "string") {
        const cls = node.className.trim().split(/\s+/)
          .filter(c => !c.startsWith("ca-")) // skip our own classes
          .slice(0, 2).join(".");
        if (cls) seg += `.${cls}`;
      }
      const parent = node.parentElement;
      if (parent) {
        const siblings = Array.from(parent.children).filter(c => c.tagName === node.tagName);
        if (siblings.length > 1) {
          seg += `:nth-child(${Array.from(parent.children).indexOf(node) + 1})`;
        }
      }
      path.unshift(seg);
      node = parent;
    }
    return path.join(" > ");
  }

  function getElementPreview(el) {
    const text = (el.textContent || "").trim();
    if (text.length <= 60) return text;
    return text.slice(0, 57) + "...";
  }

  // ── Inject styles ──────────────────────────────────────
  const style = document.createElement("style");
  style.textContent = `
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap');

    .ca-toolbar {
      position: fixed;
      top: 12px;
      right: 12px;
      z-index: 99999;
      display: flex;
      align-items: center;
      gap: 6px;
      background: rgb(255 255 255 / 92%);
      backdrop-filter: blur(16px);
      border: 1px solid rgb(0 0 0 / 8%);
      border-radius: 10px;
      padding: 6px 10px;
      box-shadow: 0 2px 12px rgb(0 0 0 / 6%);
      font-family: 'Inter', system-ui, -apple-system, sans-serif;
      font-size: 13px;
      color: #4a4a52;
      user-select: none;
    }
    .ca-toolbar button {
      font-family: inherit;
      font-size: 12px;
      font-weight: 500;
      border: 1px solid rgb(0 0 0 / 8%);
      border-radius: 7px;
      padding: 5px 12px;
      cursor: pointer;
      transition: all 0.15s ease;
      background: #fff;
      color: #4a4a52;
    }
    .ca-toolbar button:hover { border-color: rgb(0 0 0 / 16%); background: #faf9f7; }
    .ca-toolbar button.ca-active {
      background: #b35244;
      color: #fff;
      border-color: #b35244;
    }
    .ca-toolbar .ca-badge {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      min-width: 20px;
      height: 20px;
      border-radius: 10px;
      background: rgb(0 0 0 / 6%);
      font-size: 11px;
      font-weight: 600;
      padding: 0 6px;
      color: #707078;
    }
    .ca-toolbar .ca-badge.ca-has { background: #b35244; color: #fff; }
    .ca-toolbar .ca-sep {
      width: 1px;
      height: 18px;
      background: rgb(0 0 0 / 8%);
      margin: 0 4px;
    }
    .ca-send-btn {
      background: #1a1a1f !important;
      color: #fff !important;
      border-color: #1a1a1f !important;
    }
    .ca-send-btn:hover { background: #333 !important; }

    /* Hover highlight */
    .ca-highlight-overlay {
      position: fixed;
      pointer-events: none;
      z-index: 99990;
      border: 2px solid #b35244;
      border-radius: 3px;
      background: rgb(179 82 68 / 6%);
      transition: all 0.1s ease;
      display: none;
    }

    /* Annotation markers on elements */
    .ca-marker {
      position: absolute;
      z-index: 99991;
      width: 22px;
      height: 22px;
      border-radius: 50%;
      background: #b35244;
      color: #fff;
      font-family: 'Inter', system-ui, sans-serif;
      font-size: 11px;
      font-weight: 600;
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 1px 4px rgb(0 0 0 / 15%);
      cursor: pointer;
      pointer-events: auto;
      transition: transform 0.15s ease;
    }
    .ca-marker:hover { transform: scale(1.15); }

    /* Comment popover */
    .ca-popover {
      position: fixed;
      z-index: 99995;
      width: 300px;
      background: rgb(255 255 255 / 96%);
      backdrop-filter: blur(16px);
      border: 1px solid rgb(0 0 0 / 8%);
      border-radius: 10px;
      box-shadow: 0 4px 24px rgb(0 0 0 / 10%);
      padding: 14px;
      font-family: 'Inter', system-ui, sans-serif;
      display: none;
    }
    .ca-popover-label {
      font-size: 10px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.06em;
      color: #b0b0b8;
      margin-bottom: 6px;
    }
    .ca-popover-element {
      font-size: 12px;
      color: #707078;
      margin-bottom: 10px;
      padding: 4px 8px;
      background: rgb(0 0 0 / 3%);
      border-radius: 5px;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    .ca-popover textarea {
      width: 100%;
      min-height: 60px;
      border: 1px solid rgb(0 0 0 / 8%);
      border-radius: 7px;
      padding: 8px 10px;
      font-family: inherit;
      font-size: 13px;
      color: #1a1a1f;
      resize: vertical;
      outline: none;
      transition: border-color 0.15s;
    }
    .ca-popover textarea:focus { border-color: #b35244; }
    .ca-popover-actions {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-top: 8px;
    }
    .ca-popover-actions button {
      font-family: inherit;
      font-size: 12px;
      font-weight: 500;
      border-radius: 6px;
      padding: 4px 12px;
      cursor: pointer;
      border: 1px solid rgb(0 0 0 / 8%);
      background: #fff;
      color: #4a4a52;
    }
    .ca-popover-actions button:hover { background: #faf9f7; }
    .ca-popover-actions .ca-save-btn {
      background: #1a1a1f;
      color: #fff;
      border-color: #1a1a1f;
    }
    .ca-popover-actions .ca-save-btn:hover { background: #333; }
    .ca-popover-actions .ca-delete-btn { color: #b35244; border-color: rgb(179 82 68 / 20%); }
    .ca-popover-actions .ca-delete-btn:hover { background: rgb(179 82 68 / 6%); }

    /* Sidebar panel */
    .ca-panel {
      position: fixed;
      top: 0;
      right: 0;
      width: 320px;
      height: 100vh;
      z-index: 99998;
      background: rgb(255 255 255 / 95%);
      backdrop-filter: blur(20px);
      border-left: 1px solid rgb(0 0 0 / 6%);
      box-shadow: -4px 0 24px rgb(0 0 0 / 5%);
      font-family: 'Inter', system-ui, sans-serif;
      display: none;
      flex-direction: column;
      overflow: hidden;
    }
    .ca-panel.ca-open { display: flex; }
    .ca-panel-header {
      padding: 16px 18px 12px;
      border-bottom: 1px solid rgb(0 0 0 / 6%);
    }
    .ca-panel-header h3 {
      font-size: 14px;
      font-weight: 600;
      color: #1a1a1f;
      margin: 0;
    }
    .ca-panel-close {
      position: absolute;
      top: 14px;
      right: 14px;
      background: none;
      border: none;
      font-size: 18px;
      color: #b0b0b8;
      cursor: pointer;
      padding: 2px 6px;
      border-radius: 4px;
    }
    .ca-panel-close:hover { background: rgb(0 0 0 / 4%); color: #4a4a52; }
    .ca-panel-body {
      flex: 1;
      overflow-y: auto;
      padding: 12px 0;
    }
    .ca-annotation-item {
      padding: 10px 18px;
      border-bottom: 1px solid rgb(0 0 0 / 4%);
      cursor: pointer;
      transition: background 0.1s;
    }
    .ca-annotation-item:hover { background: rgb(0 0 0 / 2%); }
    .ca-annotation-item-header {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-bottom: 4px;
    }
    .ca-annotation-item-num {
      width: 20px;
      height: 20px;
      border-radius: 50%;
      background: #b35244;
      color: #fff;
      font-size: 11px;
      font-weight: 600;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }
    .ca-annotation-item-tag {
      font-size: 11px;
      color: #b0b0b8;
      font-family: 'SF Mono', 'Fira Code', monospace;
    }
    .ca-annotation-item-comment {
      font-size: 13px;
      color: #4a4a52;
      line-height: 1.4;
      padding-left: 28px;
    }
    .ca-annotation-item-comment textarea {
      width: 100%;
      min-height: 40px;
      border: 1px solid rgb(0 0 0 / 8%);
      border-radius: 6px;
      padding: 6px 8px;
      font-family: inherit;
      font-size: 13px;
      color: #4a4a52;
      resize: vertical;
      outline: none;
      transition: border-color 0.15s;
      background: #fff;
    }
    .ca-annotation-item-comment textarea:focus { border-color: #b35244; }
    .ca-annotation-item-element {
      font-size: 11px;
      color: #b0b0b8;
      padding-left: 28px;
      margin-top: 2px;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    /* Notes section at bottom of panel */
    .ca-panel-notes {
      border-top: 1px solid rgb(0 0 0 / 6%);
      padding: 14px 18px;
    }
    .ca-panel-notes h4 {
      font-size: 11px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.06em;
      color: #b0b0b8;
      margin: 0 0 8px;
    }
    .ca-panel-notes textarea {
      width: 100%;
      min-height: 70px;
      border: 1px solid rgb(0 0 0 / 6%);
      border-radius: 7px;
      padding: 8px 10px;
      font-family: 'Inter', system-ui, sans-serif;
      font-size: 13px;
      color: #1a1a1f;
      resize: vertical;
      outline: none;
    }
    .ca-panel-notes textarea:focus { border-color: #b35244; }

    .ca-panel-footer {
      padding: 12px 18px;
      border-top: 1px solid rgb(0 0 0 / 6%);
    }
    .ca-panel-send {
      width: 100%;
      padding: 10px;
      background: #1a1a1f;
      color: #fff;
      border: none;
      border-radius: 8px;
      font-family: inherit;
      font-size: 13px;
      font-weight: 600;
      cursor: pointer;
      transition: background 0.15s;
    }
    .ca-panel-send:hover { background: #333; }

    /* Annotated element outlines */
    .ca-annotated {
      outline: 2px solid rgb(179 82 68 / 30%) !important;
      outline-offset: 2px;
    }

    /* Toast */
    .ca-toast {
      position: fixed;
      bottom: 24px;
      left: 50%;
      transform: translateX(-50%) translateY(20px);
      z-index: 99999;
      background: #1a1a1f;
      color: #fff;
      font-family: 'Inter', system-ui, sans-serif;
      font-size: 13px;
      font-weight: 500;
      padding: 10px 20px;
      border-radius: 8px;
      box-shadow: 0 4px 16px rgb(0 0 0 / 20%);
      opacity: 0;
      transition: all 0.25s ease;
      pointer-events: none;
    }
    .ca-toast.ca-visible {
      opacity: 1;
      transform: translateX(-50%) translateY(0);
    }
  `;
  document.head.appendChild(style);

  // ── DOM elements ───────────────────────────────────────

  // Highlight overlay
  const highlight = document.createElement("div");
  highlight.className = "ca-highlight-overlay";
  document.body.appendChild(highlight);

  // Popover
  const popover = document.createElement("div");
  popover.className = "ca-popover";
  popover.innerHTML = `
    <div class="ca-popover-label">Annotating</div>
    <div class="ca-popover-element" id="caPopoverEl"></div>
    <textarea id="caPopoverText" placeholder="What's your feedback on this element?"></textarea>
    <div class="ca-popover-actions">
      <button class="ca-delete-btn" id="caPopoverDelete" type="button">Delete</button>
      <button class="ca-save-btn" id="caPopoverSave" type="button">Done</button>
    </div>
  `;
  document.body.appendChild(popover);

  // Panel
  const panel = document.createElement("div");
  panel.className = "ca-panel";
  panel.innerHTML = `
    <div class="ca-panel-header">
      <h3>Annotations</h3>
      <button class="ca-panel-close" id="caPanelClose" type="button">&times;</button>
    </div>
    <div class="ca-panel-body" id="caPanelBody"></div>
    <div class="ca-panel-notes">
      <h4>General notes</h4>
      <textarea id="caGeneralNotes" placeholder="Overall feedback, context, or direction..."></textarea>
    </div>
    <div class="ca-panel-footer">
      <button class="ca-panel-send" id="caPanelSend" type="button">Send to Claude</button>
    </div>
  `;
  document.body.appendChild(panel);

  // Toolbar
  const toolbar = document.createElement("div");
  toolbar.className = "ca-toolbar";
  toolbar.innerHTML = `
    <button id="caToggle" type="button">Annotate</button>
    <span class="ca-badge" id="caBadge">0</span>
    <div class="ca-sep"></div>
    <button id="caListBtn" type="button">List</button>
    <button class="ca-send-btn" id="caSendBtn" type="button">Send to Claude</button>
  `;
  document.body.appendChild(toolbar);

  // Toast
  const toast = document.createElement("div");
  toast.className = "ca-toast";
  document.body.appendChild(toast);

  function showToast(msg) {
    toast.textContent = msg;
    toast.classList.add("ca-visible");
    clearTimeout(toast._t);
    toast._t = setTimeout(() => toast.classList.remove("ca-visible"), 2200);
  }

  // ── Toolbar logic ──────────────────────────────────────
  const toggleBtn = document.getElementById("caToggle");
  const badge = document.getElementById("caBadge");
  const listBtn = document.getElementById("caListBtn");
  const sendBtn = document.getElementById("caSendBtn");
  const panelClose = document.getElementById("caPanelClose");
  const panelBody = document.getElementById("caPanelBody");
  const panelSend = document.getElementById("caPanelSend");
  const generalNotes = document.getElementById("caGeneralNotes");

  function updateBadge() {
    badge.textContent = state.annotations.length;
    badge.classList.toggle("ca-has", state.annotations.length > 0);
  }

  toggleBtn.addEventListener("click", () => {
    state.active = !state.active;
    toggleBtn.classList.toggle("ca-active", state.active);
    toggleBtn.textContent = state.active ? "Annotating..." : "Annotate";
    highlight.style.display = "none";
    if (!state.active) closePopover();
  });

  listBtn.addEventListener("click", () => {
    panel.classList.toggle("ca-open");
    renderPanel();
  });

  panelClose.addEventListener("click", () => {
    panel.classList.remove("ca-open");
  });

  // Close panel when clicking outside of it
  document.addEventListener("mousedown", (e) => {
    if (!panel.classList.contains("ca-open")) return;
    const target = e.target;
    if (target.closest(".ca-panel") || target.closest(".ca-toolbar")) return;
    panel.classList.remove("ca-open");
  });

  sendBtn.addEventListener("click", sendFeedback);
  panelSend.addEventListener("click", sendFeedback);

  // ── Hover / Click ──────────────────────────────────────
  function isOurElement(el) {
    return el.closest(".ca-toolbar, .ca-popover, .ca-panel, .ca-highlight-overlay, .ca-marker, .ca-toast");
  }

  document.addEventListener("mousemove", (e) => {
    if (!state.active) { highlight.style.display = "none"; return; }
    const el = document.elementFromPoint(e.clientX, e.clientY);
    if (!el || isOurElement(el)) { highlight.style.display = "none"; return; }
    state.hovered = el;
    const rect = el.getBoundingClientRect();
    highlight.style.display = "block";
    highlight.style.top = rect.top - 2 + "px";
    highlight.style.left = rect.left - 2 + "px";
    highlight.style.width = rect.width + 4 + "px";
    highlight.style.height = rect.height + 4 + "px";
  });

  document.addEventListener("click", (e) => {
    if (!state.active) return;
    const el = document.elementFromPoint(e.clientX, e.clientY);
    if (!el || isOurElement(el)) return;
    e.preventDefault();
    e.stopPropagation();
    addAnnotation(el);
  }, true);

  // ── Annotations ────────────────────────────────────────
  function addAnnotation(el) {
    const id = state.nextId++;
    const selector = getSelector(el);
    const preview = getElementPreview(el);
    const tag = el.tagName.toLowerCase() + (el.className && typeof el.className === "string"
      ? "." + el.className.trim().split(/\s+/).filter(c => !c.startsWith("ca-")).slice(0, 1).join(".")
      : "");

    const annotation = { id, selector, element: preview, tag, comment: "", el };
    state.annotations.push(annotation);
    el.classList.add("ca-annotated");

    placeMarker(annotation);
    openPopover(annotation);
    updateBadge();
    renderPanel();
  }

  function placeMarker(ann) {
    const el = ann.el;
    if (!el) return;

    // Ensure parent is positioned for absolute marker
    const pos = getComputedStyle(el).position;
    if (pos === "static") el.style.position = "relative";

    const marker = document.createElement("div");
    marker.className = "ca-marker";
    marker.textContent = ann.id;
    marker.dataset.annId = ann.id;
    el.appendChild(marker);
    marker.style.position = "absolute";
    marker.style.top = "-8px";
    marker.style.right = "-8px";

    marker.addEventListener("click", (e) => {
      e.preventDefault();
      e.stopPropagation();
      e.stopImmediatePropagation();
      openPopover(ann);
    });

    ann.marker = marker;
  }

  function removeAnnotation(id) {
    const idx = state.annotations.findIndex(a => a.id === id);
    if (idx === -1) return;
    const ann = state.annotations[idx];
    if (ann.marker) ann.marker.remove();
    if (ann.el) ann.el.classList.remove("ca-annotated");
    state.annotations.splice(idx, 1);
    closePopover();
    updateBadge();
    renderPanel();
  }

  // ── Popover ────────────────────────────────────────────
  const popoverEl = document.getElementById("caPopoverEl");
  const popoverText = document.getElementById("caPopoverText");
  const popoverSave = document.getElementById("caPopoverSave");
  const popoverDelete = document.getElementById("caPopoverDelete");

  function openPopover(ann) {
    state.selected = ann.id;
    popoverEl.textContent = `<${ann.tag}> ${ann.element}`;
    popoverText.value = ann.comment;

    // Position near the element
    const rect = ann.el.getBoundingClientRect();
    let top = rect.bottom + 8;
    let left = rect.left;
    if (top + 200 > window.innerHeight) top = rect.top - 200;
    if (left + 310 > window.innerWidth) left = window.innerWidth - 320;
    if (left < 8) left = 8;

    popover.style.top = top + "px";
    popover.style.left = left + "px";
    popover.style.display = "block";
    setTimeout(() => popoverText.focus(), 50);
  }

  function closePopover() {
    if (state.selected !== null) {
      const ann = state.annotations.find(a => a.id === state.selected);
      if (ann) ann.comment = popoverText.value;
    }
    state.selected = null;
    popover.style.display = "none";
    renderPanel();
  }

  popoverSave.addEventListener("click", () => closePopover());
  popoverDelete.addEventListener("click", () => {
    if (state.selected !== null) removeAnnotation(state.selected);
  });

  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") {
      if (popover.style.display === "block") closePopover();
      else if (state.active) {
        state.active = false;
        toggleBtn.classList.remove("ca-active");
        toggleBtn.textContent = "Annotate";
        highlight.style.display = "none";
      }
    }
  });

  // ── Panel rendering ────────────────────────────────────
  function renderPanel() {
    if (!state.annotations.length) {
      panelBody.innerHTML = `<div style="padding:40px 18px;text-align:center;color:#b0b0b8;font-size:13px;">
        No annotations yet.<br>Click <strong>Annotate</strong> and click on elements.
      </div>`;
      return;
    }
    panelBody.innerHTML = state.annotations.map(ann => `
      <div class="ca-annotation-item" data-ann-id="${ann.id}">
        <div class="ca-annotation-item-header">
          <div class="ca-annotation-item-num">${ann.id}</div>
          <div class="ca-annotation-item-tag">${escapeHtml(ann.tag)}</div>
        </div>
        <div class="ca-annotation-item-comment">
          <textarea data-ann-id="${ann.id}" placeholder="Add your feedback...">${escapeHtml(ann.comment)}</textarea>
        </div>
        <div class="ca-annotation-item-element">${escapeHtml(ann.element)}</div>
      </div>
    `).join("");

    // Sync textarea edits back to annotation state
    panelBody.querySelectorAll(".ca-annotation-item-comment textarea").forEach(ta => {
      ta.addEventListener("input", () => {
        const ann = state.annotations.find(a => a.id === +ta.dataset.annId);
        if (ann) ann.comment = ta.value;
      });
      // Prevent click from bubbling to the item's scroll handler
      ta.addEventListener("click", (e) => e.stopPropagation());
    });

    panelBody.querySelectorAll(".ca-annotation-item").forEach(item => {
      item.addEventListener("click", () => {
        const ann = state.annotations.find(a => a.id === +item.dataset.annId);
        if (ann) {
          ann.el.scrollIntoView({ behavior: "smooth", block: "center" });
        }
      });
    });
  }

  function escapeHtml(s) {
    if (!s) return "";
    return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
  }

  // ── Send feedback ──────────────────────────────────────
  const INBOX_URL = "http://localhost:9876/inbox";

  function sendFeedback() {
    // Save any open popover
    if (state.selected !== null) {
      const ann = state.annotations.find(a => a.id === state.selected);
      if (ann) ann.comment = popoverText.value;
    }

    if (!state.annotations.length) {
      showToast("No annotations to send");
      return;
    }

    const payload = {
      timestamp: new Date().toISOString(),
      url: window.location.href,
      mockup: document.title || window.location.pathname,
      annotations: state.annotations.map(a => ({
        id: a.id,
        selector: a.selector,
        element: a.element,
        tag: a.tag,
        comment: a.comment,
      })),
      notes: generalNotes.value,
    };

    // Try POST to inbox server first, fall back to file download
    fetch(INBOX_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload, null, 2),
    }).then(res => {
      if (!res.ok) throw new Error("Server error");
      showToast("Sent to Claude's inbox");
      clearAnnotations();
    }).catch(() => {
      // Fallback: download file
      const json = JSON.stringify(payload, null, 2);
      const blob = new Blob([json], { type: "application/json" });
      const a = document.createElement("a");
      a.href = URL.createObjectURL(blob);
      a.download = FEEDBACK_FILENAME;
      a.click();
      setTimeout(() => URL.revokeObjectURL(a.href), 1000);
      showToast("Downloaded feedback (inbox server not running)");
      clearAnnotations();
    });

    panel.classList.remove("ca-open");
  }

  function clearAnnotations() {
    // Remove all markers and outlines from DOM
    state.annotations.forEach(ann => {
      if (ann.marker) ann.marker.remove();
      if (ann.el) ann.el.classList.remove("ca-annotated");
    });
    state.annotations = [];
    state.nextId = 1;
    state.selected = null;
    generalNotes.value = "";
    closePopover();
    updateBadge();
    renderPanel();
    // Deactivate annotation mode
    state.active = false;
    toggleBtn.classList.remove("ca-active");
    toggleBtn.textContent = "Annotate";
    highlight.style.display = "none";
  }

})();

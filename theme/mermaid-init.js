// Render ```mermaid fenced blocks as diagrams (mdBook ships them as code.language-mermaid).
(function () {
  function isDarkTheme() {
    var html = document.documentElement;
    var theme =
      html.getAttribute("class") ||
      localStorage.getItem("mdbook-theme") ||
      "";
    return /navy|coal|ayu|dark/i.test(theme);
  }

  function convertBlocks() {
    document.querySelectorAll("code.language-mermaid").forEach(function (block) {
      var pre = block.parentElement;
      if (!pre || pre.tagName.toLowerCase() !== "pre") {
        return;
      }
      if (pre.dataset.mermaidConverted === "1") {
        return;
      }
      var div = document.createElement("div");
      div.className = "mermaid";
      div.textContent = block.textContent;
      pre.replaceWith(div);
      pre.dataset.mermaidConverted = "1";
    });
  }

  function runMermaid() {
    if (typeof mermaid === "undefined") {
      return;
    }
    convertBlocks();
    mermaid.initialize({
      startOnLoad: false,
      theme: isDarkTheme() ? "dark" : "default",
      securityLevel: "loose",
      flowchart: { htmlLabels: true },
    });
    mermaid.run({ querySelector: ".mermaid" });
  }

  function loadMermaid() {
    if (window.mermaid) {
      runMermaid();
      return;
    }
    var script = document.createElement("script");
    script.src = "https://cdn.jsdelivr.net/npm/mermaid@10.9.1/dist/mermaid.min.js";
    script.onload = runMermaid;
    script.onerror = function () {
      console.error("Failed to load Mermaid from CDN");
    };
    document.head.appendChild(script);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", loadMermaid);
  } else {
    loadMermaid();
  }

  // Re-run when the user switches mdBook themes
  document.addEventListener("click", function (e) {
    if (e.target && e.target.classList && e.target.classList.contains("theme")) {
      setTimeout(function () {
        if (window.mermaid) {
          document.querySelectorAll(".mermaid[data-processed]").forEach(function (el) {
            el.removeAttribute("data-processed");
          });
          runMermaid();
        }
      }, 50);
    }
  });
})();

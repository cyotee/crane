// Render ```mermaid fenced blocks as diagrams (mdBook ships them as code.language-mermaid).
// Use theme "base" + dark themeVariables so node text stays light-on-dark (readable).
// Avoid Mermaid's built-in "dark" theme: it paints bright primary fills with white labels.
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

  function darkThemeVariables() {
    return {
      darkMode: true,
      background: "transparent",
      // Node body: deep slate (not neon green)
      primaryColor: "#2c3e50",
      primaryTextColor: "#ecf0f1",
      primaryBorderColor: "#80cbc4",
      secondaryColor: "#34495e",
      secondaryTextColor: "#ecf0f1",
      tertiaryColor: "#1b2631",
      tertiaryTextColor: "#ecf0f1",
      lineColor: "#90a4ae",
      textColor: "#ecf0f1",
      mainBkg: "#2c3e50",
      nodeBorder: "#80cbc4",
      clusterBkg: "#1b2631",
      clusterBorder: "#546e7a",
      titleColor: "#eceff1",
      edgeLabelBackground: "#1b2631",
      fontFamily: "inherit",
    };
  }

  function lightThemeVariables() {
    return {
      darkMode: false,
      primaryColor: "#e3f2fd",
      primaryTextColor: "#0d47a1",
      primaryBorderColor: "#1565c0",
      secondaryColor: "#f5f5f5",
      secondaryTextColor: "#212121",
      tertiaryColor: "#eceff1",
      lineColor: "#546e7a",
      textColor: "#212121",
      mainBkg: "#e3f2fd",
      nodeBorder: "#1565c0",
      clusterBkg: "#fafafa",
      clusterBorder: "#90a4ae",
      titleColor: "#212121",
    };
  }

  function runMermaid() {
    if (typeof mermaid === "undefined") {
      return;
    }
    convertBlocks();
    var dark = isDarkTheme();
    mermaid.initialize({
      startOnLoad: false,
      // "base" respects themeVariables; built-in "dark" forces bright fills.
      theme: "base",
      themeVariables: dark ? darkThemeVariables() : lightThemeVariables(),
      securityLevel: "loose",
      flowchart: { htmlLabels: true, curve: "basis" },
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

  document.addEventListener("click", function (e) {
    if (e.target && e.target.classList && e.target.classList.contains("theme")) {
      setTimeout(function () {
        if (window.mermaid) {
          document.querySelectorAll(".mermaid[data-processed]").forEach(function (el) {
            el.removeAttribute("data-processed");
            // Force re-render by resetting SVG content
            if (el.getAttribute("data-original-code")) {
              el.textContent = el.getAttribute("data-original-code");
            }
          });
          // Re-convert is no-op; re-run on existing .mermaid with stored source
          document.querySelectorAll("div.mermaid").forEach(function (el) {
            if (!el.getAttribute("data-original-code") && el.textContent) {
              el.setAttribute("data-original-code", el.textContent);
            }
          });
          runMermaid();
        }
      }, 50);
    }
  });
})();

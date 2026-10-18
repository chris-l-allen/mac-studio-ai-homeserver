---
layout: default
---

{% include_relative README.md %}

<script type="module">
  // Render the Mermaid architecture diagram on the GitHub Pages site
  // (GitHub's own repo view renders it natively; Jekyll does not).
  import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";
  mermaid.initialize({ startOnLoad: false });
  mermaid.run({ querySelector: ".language-mermaid" });
</script>

# lsp-diagnostic-quirks

TODO:
  - Explain what this plugin does
      - Add a section explaining why Python is uniquely in need of this. Call
        to action: let me know if there are other languages that often have
        unused, necessary, but no mechanism/convention for marking it as unused
        by necessary.
  - Explain what would have to change in Neovim for the mess that is
    `./lua/lsp-diagnostic-quirks/vendored.lua` to go away.
    - In short: Neovim would need a concept of non-actionable "diagnostics/hints".
  - Explain what it would take for this plugin to go away entirely.
    - <https://github.com/microsoft/language-server-protocol/issues/2026>
  - If this must remain in a plugin, explain where it should live. Maybe this
    is in-scope for lspconfig?

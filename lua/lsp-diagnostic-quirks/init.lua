-- Pyright wants to tell us about unused variables, even when they're
-- not actionable. This is arguably useful: it lets Neovim know that it can
-- gray out the variable name. However, the LSP spec doesn't have a
-- mechanism for LSP servers to convey the non-actionability of diagnostics.
-- Pyright claims it's doing something reasonable, Neovim's maintainers say
-- it's unreasonable. See
-- [my summary of the situation](https://github.com/neovim/neovim/issues/30444).
--
-- This means that an otherwise stock Neovim + Pyright is going to produce a
-- lot of noise that you can't actually address by changing your code.
-- The fix is to for the LSP spec to change in a way that makes it crystal
-- clear how LSP servers are supposed to convey "non-actionable unused code
-- diagnostics". I've asked about that over in
-- <https://github.com/microsoft/language-server-protocol/issues/2026>.
--
-- Before I got cursed by reading too much about this, I worked around this
-- issue with [this clever, but imperfect hack](https://github.com/neovim/nvim-lspconfig/issues/726#issuecomment-1075539112).
-- Basically, it just filters out these Pyright diagnostics when they're
-- known to be non-actionable. There are two issues with this:
--  1. Neovim can no longer color these as unused.
--  2. It's not always possible to rewrite your function parameter names to
--     start with `_` (because callers may invoke you with named
--     parameters).
--
-- Now, I work around the issue by:
--  - Monkeypatching the various `vim.diagnostic.handler`s to ignore "hint
--    diagnostics" with tag "unnecessary".
--  - `vim.diagnostic.handlers.underline` remains the same though, as it is
--    responsible for recoloring variables to appear grayed out when
--  unused.

local monkeypatch = require("lsp-diagnostic-quirks.monkeypatch")

return {
    setup = function(opts)
        monkeypatch()
    end,
}

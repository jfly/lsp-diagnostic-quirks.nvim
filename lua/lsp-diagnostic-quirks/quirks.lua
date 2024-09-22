local function is_actionable(diagnostic)
    -- [Pyright] appears to be a bit of an outlier in the LSP
    -- ecosystem: it emits diagnostics that are (sometimes*)
    -- non-actionable about unused code**. Since it doesn't tell us which
    -- is which, we assume they're non-actionable to avoid pestering
    -- the user about a bunch of lines of code they can't do anything to
    -- fix.
    --
    -- *Note: as unused code is (sometimes) a sign of something
    -- actionable, it's best to pair Pyright with another LSP like
    -- [ruff-lsp] which emits only *actionable* diagnostics about unused code.
    --
    -- **Note: this is arguably a quirk of Python's support for "named
    -- parameters". In Python, you'll sometimes implement a method signature
    -- and not use any of the parameters. In other languages (e.g., Javascript
    -- and Rust, you're free to rename that variable to something like `_foo`
    -- to clearly annotate your intent not to use the variable. In Python,
    -- that's not always an option you have.
    --
    -- [Pyright]: https://github.com/microsoft/pyright
    -- [ruff-lsp]: https://github.com/astral-sh/ruff-lsp
    if diagnostic.source == "Pyright" then
        local unnecessary = diagnostic._tags and diagnostic._tags.unnecessary
        local is_hint = diagnostic.severity == vim.diagnostic.severity.HINT

        -- From https://github.com/microsoft/pyright/issues/1118#issuecomment-1859280421:
        --
        -- > Pyright makes use of tagged hints (using the Unnecessary tag) in various
        -- > places to indicate to the client that it should display the text in a
        -- > dimmed-out manner. This is used for unreachable code, unreferenced symbols,
        -- > etc., and it is not meant to be displayed as a diagnostic. A tagged hint
        -- > is not indicative of something wrong with the code that must be "fixed".
        -- > Rather, it's a subtle visual hint to the user meant to provide additional
        -- > information about the code.
        local non_actionable = unnecessary and is_hint
        return not non_actionable
    end

    -- Apparently (citation needed), every other LSP server only emits actionable
    -- diagnostics? I'm not totally convinced this is true, but I haven't investigated
    -- the universe of LSP servers.
    return true
end

return {
    is_actionable = is_actionable,
}

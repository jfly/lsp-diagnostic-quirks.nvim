local vendored = require("lsp-diagnostic-quirks.vendored")
local quirks = require("lsp-diagnostic-quirks.quirks")

local function partition(pred, t)
    local result = { yes = {}, no = {} }

    for key, value in pairs(t) do
        if pred(value) then
            table.insert(result.yes, value)
        else
            table.insert(result.no, value)
        end
    end

    return result
end

-- Monkeypatch various public apis in `vim.diagnostic`.
-- The idea here is to distinguish between actionable and
-- non-actionable diagnostics.
--
-- Non-actionable diagnostics are mostly* hidden
-- from the rest of Neovim core and plugins querying for diagnostics.
--
-- *The only exception is `vim.handlers.underline`, which is so subtle that
-- it's actually useful to let it show non-actionable diagnostics.
local function monkeypatch()
    local og_set = vim.diagnostic.set
    vim.diagnostic.set = function(namespace, bufnr, diagnostics, opts)
        -- I'm not sure if this hack negatively impacts other functions in
        -- `runtime/lua/vim/diagnostic.lua`. For example, I see that `vim.diagnostic.reset`
        -- and `vim.diagnostic.hide` read directly from `diagnostic_cache`. Perhaps we
        -- ought to hook into those codepaths as well and do something analogous with
        -- underlines?

        local split_by_actionability = partition(quirks.is_actionable, diagnostics)
        local actionable_diagnostics = split_by_actionability.yes
        local non_actionable_diagnostics = split_by_actionability.no

        bufnr = vendored.get_bufnr(bufnr)

        if vim.tbl_isempty(diagnostics) then
            vendored.non_actionable_diagnostic_cache[bufnr][namespace] = nil
        else
            -- Note: this does not do the "normalization" that Neovim's [set_diagnostic_cache] does.
            -- I don't know if this would cause issues with some LSP servers or codepaths...
            --
            -- [set_diagnostic_cache]: https://github.com/neovim/neovim/blob/v0.10.1/runtime/lua/vim/diagnostic.lua#L580
            vendored.non_actionable_diagnostic_cache[bufnr][namespace] = non_actionable_diagnostics
        end

        og_set(namespace, bufnr, actionable_diagnostics, opts)
    end

    local og_show = vim.diagnostic.show
    vim.diagnostic.show = function(namespace, bufnr, diagnostics, opts)
        og_show(namespace, bufnr, diagnostics, opts)

        -- Here's the magic: after invoking the original `vim.diagnostic.show`, we now go on to invoke
        -- `vim.handlers.underline`, as this handler is subtle enough (it just grays out text) that
        -- it's not distracting for it to show non-actionable diagnostics (such as an unused parameter
        -- in a method signature).
        if bufnr and namespace then
            non_actionable_diagnostics = vendored.get_non_actionable_diagnostics(bufnr, { namespace = namespace }, true)

            if vim.tbl_isempty(non_actionable_diagnostics) then
                return
            end

            vim.diagnostic.handlers.underline.show(namespace, bufnr, non_actionable_diagnostics, opts)
        end
    end
end

return monkeypatch

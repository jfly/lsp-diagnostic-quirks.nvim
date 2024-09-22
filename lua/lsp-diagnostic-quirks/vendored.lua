-- This code was mostly copied from Neovim's `runtime/lua/vim/diagnostic.lua`, or was
-- lightly tweaked to support a new concept of "non-actionable diagnostics".

local non_actionable_diagnostic_cache = {} --- @type table<integer,table<integer,vim.Diagnostic[]>>
do
    local group = vim.api.nvim_create_augroup("DiagnosticBufWipeout", {})
    setmetatable(non_actionable_diagnostic_cache, {
        --- @param t table<integer,vim.Diagnostic[]>
        --- @param bufnr integer
        __index = function(t, bufnr)
            assert(bufnr > 0, "Invalid buffer number")
            vim.api.nvim_create_autocmd("BufWipeout", {
                group = group,
                buffer = bufnr,
                callback = function()
                    rawset(t, bufnr, nil)
                end,
            })
            t[bufnr] = {}
            return t[bufnr]
        end,
    })
end

local function get_bufnr(bufnr)
    if not bufnr or bufnr == 0 then
        return vim.api.nvim_get_current_buf()
    end
    return bufnr
end

--- @param bufnr integer?
--- @param opts vim.diagnostic.GetOpts?
--- @param clamp boolean
--- @return vim.Diagnostic[]
local function get_non_actionable_diagnostics(bufnr, opts, clamp)
    opts = opts or {}

    local namespace = opts.namespace

    if type(namespace) == "number" then
        namespace = { namespace }
    end

    ---@cast namespace integer[]

    local diagnostics = {}

    -- Memoized results of buf_line_count per bufnr
    --- @type table<integer,integer>
    local buf_line_count = setmetatable({}, {
        --- @param t table<integer,integer>
        --- @param k integer
        --- @return integer
        __index = function(t, k)
            t[k] = vim.api.nvim_buf_line_count(k)
            return rawget(t, k)
        end,
    })

    local match_severity = opts.severity and severity_predicate(opts.severity)
        or function(_)
            return true
        end

    ---@param b integer
    ---@param d vim.Diagnostic
    local function add(b, d)
        if match_severity(d) and (not opts.lnum or (opts.lnum >= d.lnum and opts.lnum <= (d.end_lnum or d.lnum))) then
            if clamp and vim.api.nvim_buf_is_loaded(b) then
                local line_count = buf_line_count[b] - 1
                if
                    d.lnum > line_count
                    or d.end_lnum > line_count
                    or d.lnum < 0
                    or d.end_lnum < 0
                    or d.col < 0
                    or d.end_col < 0
                then
                    d = vim.deepcopy(d, true)
                    d.lnum = math.max(math.min(d.lnum, line_count), 0)
                    d.end_lnum = math.max(math.min(assert(d.end_lnum), line_count), 0)
                    d.col = math.max(d.col, 0)
                    d.end_col = math.max(d.end_col, 0)
                end
            end
            table.insert(diagnostics, d)
        end
    end

    --- @param buf integer
    --- @param diags vim.Diagnostic[]
    local function add_all_diags(buf, diags)
        for _, diagnostic in pairs(diags) do
            add(buf, diagnostic)
        end
    end

    if namespace == nil and bufnr == nil then
        for b, t in pairs(non_actionable_diagnostic_cache) do
            for _, v in pairs(t) do
                add_all_diags(b, v)
            end
        end
    elseif namespace == nil then
        bufnr = get_bufnr(bufnr)
        for iter_namespace in pairs(non_actionable_diagnostic_cache[bufnr]) do
            add_all_diags(bufnr, non_actionable_diagnostic_cache[bufnr][iter_namespace])
        end
    elseif bufnr == nil then
        for b, t in pairs(non_actionable_diagnostic_cache) do
            for _, iter_namespace in ipairs(namespace) do
                add_all_diags(b, t[iter_namespace] or {})
            end
        end
    else
        bufnr = get_bufnr(bufnr)
        for _, iter_namespace in ipairs(namespace) do
            add_all_diags(bufnr, non_actionable_diagnostic_cache[bufnr][iter_namespace] or {})
        end
    end

    return diagnostics
end

return {
    non_actionable_diagnostic_cache = non_actionable_diagnostic_cache,
    get_non_actionable_diagnostics = get_non_actionable_diagnostics,
    get_bufnr = get_bufnr,
}

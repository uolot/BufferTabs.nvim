local api = vim.api
local U = require('buffertabs.utils')

---@class Data
---@field win_buf number|nil
---@field win number|nil
---@field name string
---@field active boolean

---@type Data[]
local data = {}
local width = 0
local ns = api.nvim_create_namespace('buffertabs')

local cfg = {
    border = 'rounded',
    icons = true,
    hl_group = 'Keyword',
    hl_group_inactive = 'Comment',
    exclude = { 'NvimTree', 'help', 'dashboard', 'lir', 'alpha' },
    horizontal = 'right',
    vertical = 'bottom'
}


local function load_buffers()
    data = {}

    for _, buf in pairs(api.nvim_list_bufs()) do
        local is_valid = api.nvim_buf_is_valid(buf)
        local is_loaded = api.nvim_buf_is_loaded(buf)

        if is_valid and is_loaded then
            local name = api.nvim_buf_get_name(buf):match("[^\\/]+$") or ""
            local ext = string.match(name, "%w+%.(.+)") or name
            local icon = U.get_icon(name, ext, cfg)

            local is_excluded = vim.tbl_contains(cfg.exclude, vim.bo[buf].ft)

            if not is_excluded and name ~= "" then
                local is_active = api.nvim_get_current_buf() == buf

                table.insert(data, {
                    win = nil,
                    win_buf = nil,
                    name = icon .. " " .. name .. "",
                    active = is_active,
                })
            end
        end
    end
end

---@param name string
---@param is_active boolean
---@param data_idx number
local function create_win(name, is_active, data_idx)
    -- setup buffer
    local buf = api.nvim_create_buf(false, true)
    data[data_idx].win_buf = buf
    api.nvim_buf_set_lines(buf, 0, -1, true, { " " .. name .. " " })

    -- create window
    local win_opts = {
        relative = 'editor',
        width = #name,
        height = 1,
        row = U.get_position_vertical(cfg.vertical),
        col = width + 3,
        style = "minimal",
        border = cfg.border,
        focusable = false,
    }
    local win = api.nvim_open_win(buf, false, win_opts)
    data[data_idx].win = win

    width = width + #name + 3

    -- configure window
    api.nvim_buf_set_option(buf, 'modifiable', false)
    api.nvim_buf_set_option(buf, 'buflisted', false)


    -- add highlight
    if is_active then
        api.nvim_buf_add_highlight(buf, ns, cfg.hl_group, 0, 0, -1)
        api.nvim_win_set_option(win, 'winhighlight', 'FloatBorder:' .. cfg.hl_group)
    else
        api.nvim_buf_add_highlight(buf, ns, cfg.hl_group_inactive, 0, 0, -1)
        api.nvim_win_set_option(win, 'winhighlight', 'FloatBorder:' .. cfg.hl_group_inactive)
    end
end

local function display_buffers()
    local max = U.get_max_width(data)
    width = U.get_position_horizontal(cfg.horizontal, max)

    for idx, v in pairs(data) do
        create_win(v.name, v.active, idx)
    end
end


---@param opts table
local function setup(opts)
    -- load config
    opts = opts or {}
    for k, v in pairs(opts) do
        cfg[k] = v
    end

    -- start displaying
    api.nvim_create_autocmd(U.events, {
        callback = function()
            U.delete_buffers(data)
            load_buffers()
            display_buffers()
        end
    })
end

return {
    setup = setup
}

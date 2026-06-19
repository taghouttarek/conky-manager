-- ###Crypto settings###
coin_id = "solana"
currency = "usd"
coin_symbol = "SOL"
chart_days = 7
-- ###Style (matching system-widgets)###
HTML_color = "#FFFFFF"
HTML_color_border = "#FFFFFF"
transparency_bg = 0.6
transparency_border = 0.1
transparency_text = 0.6
transparency_value = 0.9
transparency_chart = 0.3
HTML_chart_line = "#FFFFFF"
HTML_chart_fill = "#FFFFFF"
HTML_change_up = "#00ff88"
HTML_change_down = "#ff4444"
-- ###Mode (1 = background, 2 = no background)###
mode = 1
border_size = 4
-- ###Font sizes###
Symbol_font = 12
Price_font = 22
Change_font = 14
Label_font = 12
Mcap_font = 12
-- ###Dont change code below###
require 'cairo'
assert(os.setlocale("en_US.utf8", "numeric"))

local script = os.getenv("HOME") .. "/.config/conky/crypto-tracker/crypto_price.py"
local cmd_base = "python3 " .. script .. " --coin " .. coin_id .. " --currency " .. currency

operator = {CAIRO_OPERATOR_SOURCE, CAIRO_OPERATOR_CLEAR}
operator_transpose = {CAIRO_OPERATOR_CLEAR, CAIRO_OPERATOR_SOURCE}

function hex2rgb(hex)
    hex = hex:gsub("#","")
    return (tonumber("0x"..hex:sub(1,2))/255), (tonumber("0x"..hex:sub(3,4))/255), tonumber(("0x"..hex:sub(5,6))/255)
end

r, g, b = hex2rgb(HTML_color)
r_border, g_border, b_border = hex2rgb(HTML_color_border)
r_up, g_up, b_up = hex2rgb(HTML_change_up)
r_down, g_down, b_down = hex2rgb(HTML_change_down)
r_line, g_line, b_line = hex2rgb(HTML_chart_line)
r_fill, g_fill, b_fill = hex2rgb(HTML_chart_fill)

function get_val(flag)
    local raw = conky_parse("${exec " .. cmd_base .. " " .. flag .. " 2>/dev/null}")
    if raw then return raw:gsub("%s+", "") end
    return ""
end

function parse_chart(csv)
    local prices = {}
    for price_str in csv:gmatch("[^,]+") do
        local val = tonumber(price_str)
        if val then
            table.insert(prices, val)
        end
    end
    return prices
end

function draw_square(cr, pos_x, pos_y, rectangle_x, rectangle_y, trans)
    cairo_set_operator(cr, operator[mode])
    cairo_set_source_rgba(cr, r, g, b, trans)
    cairo_set_line_width(cr, 2)
    cairo_rectangle(cr, pos_x, pos_y, rectangle_x, rectangle_y)
    cairo_fill(cr)

    cairo_set_operator(cr, operator[mode])
    cairo_set_source_rgba(cr, r_border, g_border, b_border, transparency_border)
    cairo_set_line_width(cr, border_size)
    cairo_rectangle(cr, pos_x, pos_y, rectangle_x, rectangle_y)
    cairo_stroke(cr)
end

function draw_text(cr, x, y, text, font_size, trans)
    cairo_set_operator(cr, operator_transpose[mode])
    cairo_set_source_rgba(cr, r, g, b, trans)
    cairo_set_font_size(cr, font_size)
    cairo_move_to(cr, x, y)
    cairo_show_text(cr, text)
end

function draw_text_right(cr, x, y, text, font_size, trans)
    cairo_set_operator(cr, operator_transpose[mode])
    cairo_set_source_rgba(cr, r, g, b, trans)
    cairo_set_font_size(cr, font_size)
    local ct = cairo_text_extents_t:create()
    cairo_text_extents(cr, text, ct)
    cairo_move_to(cr, x - ct.width, y)
    cairo_show_text(cr, text)
end

function draw_icon_crypto(cr, x, y, size)
    cairo_set_operator(cr, operator_transpose[mode])
    cairo_set_source_rgba(cr, r, g, b, transparency_value)
    cairo_set_line_width(cr, 1.5)
    -- Coin circle (filled)
    local radius = size * 0.35
    cairo_arc(cr, x, y, radius, 0, 2 * math.pi)
    cairo_fill(cr)
    -- Inner circle outline
    cairo_arc(cr, x, y, radius * 0.6, 0, 2 * math.pi)
    cairo_stroke(cr)
    -- Dollar sign vertical line
    cairo_move_to(cr, x, y - radius * 0.4)
    cairo_line_to(cr, x, y + radius * 0.4)
    cairo_stroke(cr)
    -- Dollar sign curves
    cairo_arc(cr, x, y - radius * 0.15, radius * 0.25, -0.8 * math.pi, 0.3 * math.pi)
    cairo_stroke(cr)
    cairo_arc(cr, x, y + radius * 0.15, radius * 0.25, 0.2 * math.pi, 1.3 * math.pi)
    cairo_stroke(cr)
end

function draw_chart(cr, x, y, chart_w, chart_h, prices)
    if #prices < 2 then return end

    local min_val = prices[1]
    local max_val = prices[1]
    for _, v in ipairs(prices) do
        if v < min_val then min_val = v end
        if v > max_val then max_val = v end
    end

    local range = max_val - min_val
    if range == 0 then range = 1 end

    local step = chart_w / (#prices - 1)

    -- Filled area
    cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE)
    cairo_move_to(cr, x, y + chart_h)
    for i, v in ipairs(prices) do
        local px = x + (i - 1) * step
        local py = y + chart_h - ((v - min_val) / range) * chart_h
        cairo_line_to(cr, px, py)
    end
    cairo_line_to(cr, x + chart_w, y + chart_h)
    cairo_close_path(cr)
    cairo_set_source_rgba(cr, r_fill, g_fill, b_fill, transparency_chart)
    cairo_fill(cr)

    -- Line
    cairo_set_operator(cr, operator_transpose[mode])
    cairo_move_to(cr, x, y + chart_h - ((prices[1] - min_val) / range) * chart_h)
    for i = 2, #prices do
        local px = x + (i - 1) * step
        local py = y + chart_h - ((prices[i] - min_val) / range) * chart_h
        cairo_line_to(cr, px, py)
    end
    cairo_set_source_rgba(cr, r_line, g_line, b_line, transparency_value)
    cairo_set_line_width(cr, 2)
    cairo_stroke(cr)

    -- End dot
    local last_px = x + chart_w
    local last_py = y + chart_h - ((prices[#prices] - min_val) / range) * chart_h
    cairo_arc(cr, last_px, last_py, 3, 0, 2 * math.pi)
    cairo_fill(cr)

    -- High/Low labels
    cairo_set_operator(cr, operator_transpose[mode])
    cairo_set_source_rgba(cr, r, g, b, transparency_text)
    cairo_set_font_size(cr, 9)
    local ct = cairo_text_extents_t:create()
    cairo_text_extents(cr, string.format("%.2f", max_val), ct)
    cairo_move_to(cr, x + chart_w + 5, y + ct.height)
    cairo_show_text(cr, string.format("%.2f", max_val))
    cairo_text_extents(cr, string.format("%.2f", min_val), ct)
    cairo_move_to(cr, x + chart_w + 5, y + chart_h)
    cairo_show_text(cr, string.format("%.2f", min_val))
end

function draw_crypto_widget(cr, x, y)
    local w, h = 250, 250

    -- Background square
    draw_square(cr, x, y, w, h, transparency_bg)

    -- Icon and Title
    draw_icon_crypto(cr, x + 15, y + 15, 20)
    draw_text(cr, x + 35, y + 20, "CRYPTO", 12, transparency_value)

    -- Fetch data
    local raw_price = get_val("--get_price")
    local raw_change = get_val("--get_change")
    local raw_mcap = get_val("--get_market_cap")
    local raw_chart = get_val("--days " .. chart_days .. " --get_chart")

    -- Coin + Price
    local cy = y + 50
    draw_text(cr, x + 10, cy, coin_symbol, Symbol_font, transparency_value)

    cy = cy + 25
    local price_str = #raw_price > 0 and ("$" .. raw_price) or "..."
    draw_text(cr, x + 10, cy, price_str, Price_font, transparency_value)

    -- 24h change
    cy = cy + 22
    local change_val = tonumber(raw_change) or 0
    local change_str = #raw_change > 0 and (string.format("%.2f", change_val) .. "%") or "..."
    local prefix = change_val >= 0 and "+" or ""
    -- Draw change with color (using OVER operator for visibility)
    cairo_set_operator(cr, CAIRO_OPERATOR_OVER)
    if change_val >= 0 then
        cairo_set_source_rgba(cr, r_up, g_up, b_up, transparency_value)
    else
        cairo_set_source_rgba(cr, r_down, g_down, b_down, transparency_value)
    end
    cairo_set_font_size(cr, Change_font)
    cairo_move_to(cr, x + 10, cy)
    cairo_show_text(cr, prefix .. change_str)

    -- Chart
    cy = cy + 15
    local chart_x = x + 10
    local chart_y = cy
    local chart_w = w - 35
    local chart_h = 80
    local prices = parse_chart(raw_chart)

    -- Chart border
    cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE)
    cairo_set_source_rgba(cr, r_border, g_border, b_border, 0.2)
    cairo_set_line_width(cr, 1)
    cairo_rectangle(cr, chart_x, chart_y, chart_w, chart_h)
    cairo_stroke(cr)

    draw_chart(cr, chart_x, chart_y, chart_w, chart_h, prices)

    cy = chart_y + chart_h + 10

    -- Market cap
    local mcap_str = #raw_mcap > 0 and raw_mcap or "..."
    draw_text(cr, x + 10, cy, "MCap: " .. mcap_str, Label_font, transparency_text)

    -- Time range
    cy = cy + 15
    local days_label = chart_days .. "d"
    if chart_days == 1 then days_label = "24h" end
    draw_text(cr, x + 10, cy, days_label .. " chart", 9, transparency_text)
end

function draw_function(cr)
    local w, h = conky_window.width, conky_window.height
    cairo_select_font_face(cr, "Dejavu Sans Book", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)

    -- Position widget below network widgets (left side)
    local widget_x = 30
    local widget_y = 720
    draw_crypto_widget(cr, widget_x, widget_y)
end

function conky_start_widgets()
    local function draw_conky_function(cr)
        draw_function(cr)
    end

    if conky_window == nil then return end
    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
    local cr = cairo_create(cs)

    local updates = conky_parse('${updates}')
    update_num = tonumber(updates)
    if update_num > 5 then
        draw_conky_function(cr)
    end
    cairo_surface_destroy(cs)
    cairo_destroy(cr)
end

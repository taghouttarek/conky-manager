-- All Widgets Theme (White)
-- Unified conky theme containing all widgets in a single instance

-- ###Style###
HTML_color = "#FFFFFF"
HTML_color_border = "#FFFFFF"
transparency_bg = 0.6
transparency_border = 0.1
transparency_text = 0.6
transparency_value = 0.9

-- ###Mode (1 = background, 2 = no background)###
mode = 1
border_size = 4

-- ###Bandwidth settings###
iface = "auto"

-- ###Weather settings###
api_key = ""
city = "Tunis"
country_code = "TN"

-- ###Crypto settings###
coin_id = "solana"
currency = "usd"
coin_symbol = "SOL"
chart_days = 7

-- ###KEV/Infra accent color###
HTML_critical_kev = "#ff4444"
HTML_critical_infra = "#ff8800"

-- ###Revisited settings###
battery = true
battery_number = "BAT0"
drive_paths = {"/home", "/"}
drive_names = {"Home", "Root"}
drives = 2
number_of_cpus = 4
special_border = 0
gap_x_distance = 10

-- ###Calendar settings###
number_of_physical_CPU_cores = 16

-- ###Widget visibility (true = enabled, false = disabled)###
enabled_network = true
enabled_bandwidth = true
enabled_processes = true
enabled_docker = true
enabled_k8s = true
enabled_crypto = true
enabled_kev = true
enabled_infra = true
enabled_weather = true
enabled_calendar = true
enabled_revisited = true

-- ###Dont change code below###
require 'cairo'
pcall(require, 'cairo_xlib')
assert(os.setlocale("en_US.utf8", "numeric"))

operator = {CAIRO_OPERATOR_SOURCE, CAIRO_OPERATOR_CLEAR}
operator_transpose = {CAIRO_OPERATOR_CLEAR, CAIRO_OPERATOR_SOURCE}

function hex2rgb(hex)
    hex = hex:gsub("#","")
    return (tonumber("0x"..hex:sub(1,2))/255), (tonumber("0x"..hex:sub(3,4))/255), tonumber("0x"..hex:sub(5,6))/255
end

r, g, b = hex2rgb(HTML_color)
r_border, g_border, b_border = hex2rgb(HTML_color_border)
r_crit_kev, g_crit_kev, b_crit_kev = hex2rgb(HTML_critical_kev)
r_crit_infra, g_crit_infra, b_crit_infra = hex2rgb(HTML_critical_infra)

-- Crypto extra colors
HTML_chart_line = "#FFFFFF"
HTML_chart_fill = "#FFFFFF"
HTML_change_up = "#00ff88"
HTML_change_down = "#ff4444"
transparency_chart = 0.3
r_up, g_up, b_up = hex2rgb(HTML_change_up)
r_down, g_down, b_down = hex2rgb(HTML_change_down)
r_line, g_line, b_line = hex2rgb(HTML_chart_line)
r_fill, g_fill, b_fill = hex2rgb(HTML_chart_fill)

-- Weather colors
HTML_circle = "#FFFFFF"
HTML_border_w = "#000000"
HTML_text_w = "#FFFFFF"
transparency_w = 0.6
transparency_border_w = 0.2
transparency_text_w = 0.5
transparency_weather_icon = 1.0
City_font = 9
Temperature_font = 24
Day_font = 12
r_circle_w, g_circle_w, b_circle_w = hex2rgb(HTML_circle)
r_border_w, g_border_w, b_border_w = hex2rgb(HTML_border_w)
r_text_w, g_text_w, b_text_w = hex2rgb(HTML_text_w)

-- Revisited colors
HTML_color_battery = "#FFFFFF"
HTML_color_drive_1 = "#FFFFFF"
HTML_color_drive_2 = "#FFFFFF"
HTML_background_CPU = "#FFFFFF"
HTML_color_RAM = "#FFFFFF"
transparency_battery = 0.6
transparency_drive_1 = 0.6
transparency_drive_2 = 0.6
transparency_CPU = 0.6
transparency_RAM = 0.6
r_battery, g_battery, b_battery = hex2rgb(HTML_color_battery)
r_CPU, g_CPU, b_CPU = hex2rgb(HTML_background_CPU)
r_RAM, g_RAM, b_RAM = hex2rgb(HTML_color_RAM)
r_drive_1, g_drive_1, b_drive_1 = hex2rgb(HTML_color_drive_1)
r_drive_2, g_drive_2, b_drive_2 = hex2rgb(HTML_color_drive_2)
drive_colors = {{r_drive_1, g_drive_1, b_drive_1, transparency_drive_1},
                {r_drive_2, g_drive_2, b_drive_2, transparency_drive_2}}

-- Calendar colors
HTML_colors_cal = "#FFFFFF"
HTML_colors_current_cal = "#FFFFFF"
transparency_cal = 0.6
transparency_active_cal = 0.9
r_cal, g_cal, b_cal = hex2rgb(HTML_colors_cal)
r_c_cal, g_c_cal, b_c_cal = hex2rgb(HTML_colors_current_cal)
r_border_cal, g_border_cal, b_border_cal = hex2rgb(HTML_colors_cal)

-- ============================================================
-- SHARED DRAWING HELPERS
-- ============================================================

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

-- ============================================================
-- NETWORK WIDGET
-- ============================================================

function draw_icon_network(cr, x, y, size)
    cairo_set_operator(cr, operator_transpose[mode])
    cairo_set_source_rgba(cr, r, g, b, transparency_value)
    cairo_set_line_width(cr, 1.5)
    for i = 0, 2 do
        local radius = size * 0.3 + i * size * 0.25
        cairo_arc(cr, x, y + size * 0.3, radius, -0.8 * math.pi, -0.2 * math.pi)
        cairo_stroke(cr)
    end
    cairo_arc(cr, x, y + size * 0.3, 2, 0, 2 * math.pi)
    cairo_fill(cr)
end

function draw_network_info(cr, x, y)
    local w, h = 220, 160
    draw_square(cr, x, y, w, h, transparency_bg)
    draw_icon_network(cr, x + 15, y + 15, 20)
    draw_text(cr, x + 35, y + 20, "NETWORK", 12, transparency_value)

    local iface_name = conky_parse('${if_existing /sys/class/net/wlp2s0}wlp2s0${else}enp1s0f0${endif}')
    draw_text(cr, x + 10, y + 45, "Interface", 12, transparency_text)
    draw_text(cr, x + 10, y + 60, iface_name, 12, transparency_value)

    local local_ip = conky_parse('${addr wlp2s0}')
    if local_ip == "" then local_ip = conky_parse('${addr enp1s0f0}') end
    draw_text(cr, x + 10, y + 80, "Local IP", 12, transparency_text)
    draw_text(cr, x + 10, y + 95, local_ip, 12, transparency_value)

    local ext_ip = conky_parse('${exec curl -s --max-time 3 ifconfig.me 2>/dev/null || echo "N/A"}')
    draw_text(cr, x + 10, y + 115, "External IP", 12, transparency_text)
    draw_text(cr, x + 10, y + 130, ext_ip, 12, transparency_value)
end

-- ============================================================
-- BANDWIDTH WIDGET
-- ============================================================

function draw_icon_bandwidth(cr, x, y, size)
    cairo_set_operator(cr, operator_transpose[mode])
    cairo_set_source_rgba(cr, r, g, b, transparency_value)
    cairo_set_line_width(cr, 2)
    cairo_move_to(cr, x - size * 0.3, y + size * 0.6)
    cairo_line_to(cr, x - size * 0.3, y + size * 0.2)
    cairo_line_to(cr, x - size * 0.45, y + size * 0.35)
    cairo_move_to(cr, x - size * 0.3, y + size * 0.2)
    cairo_line_to(cr, x - size * 0.15, y + size * 0.35)
    cairo_stroke(cr)
    cairo_move_to(cr, x + size * 0.3, y + size * 0.2)
    cairo_line_to(cr, x + size * 0.3, y + size * 0.6)
    cairo_line_to(cr, x + size * 0.15, y + size * 0.45)
    cairo_move_to(cr, x + size * 0.3, y + size * 0.6)
    cairo_line_to(cr, x + size * 0.45, y + size * 0.45)
    cairo_stroke(cr)
end

function draw_network_bandwidth(cr, x, y)
    local w, h = 220, 120
    draw_square(cr, x, y, w, h, transparency_bg)
    draw_icon_bandwidth(cr, x + 15, y + 15, 20)
    draw_text(cr, x + 35, y + 20, "BANDWIDTH", 12, transparency_value)

    local iface_name = iface
    if iface_name == "auto" then
        local down = conky_parse('${downspeed wlp2s0}')
        if down == "0B/s" then iface_name = "enp1s0f0"
        else iface_name = "wlp2s0" end
    end

    local down = conky_parse('${downspeed ' .. iface_name .. '}')
    draw_text(cr, x + 10, y + 45, "Download", 12, transparency_text)
    draw_text(cr, x + 10, y + 60, down, 14, transparency_value)

    local up = conky_parse('${upspeed ' .. iface_name .. '}')
    draw_text(cr, x + 10, y + 80, "Upload", 12, transparency_text)
    draw_text(cr, x + 10, y + 95, up, 14, transparency_value)
end

-- ============================================================
-- PROCESSES WIDGET
-- ============================================================

function draw_icon_processes(cr, x, y, size)
    cairo_set_operator(cr, operator_transpose[mode])
    cairo_set_source_rgba(cr, r, g, b, transparency_value)
    cairo_set_line_width(cr, 1.5)
    local radius = size * 0.35
    local teeth = 8
    for i = 0, teeth - 1 do
        local angle = (i / teeth) * 2 * math.pi
        local next_angle = ((i + 0.5) / teeth) * 2 * math.pi
        local x1 = x + radius * math.cos(angle)
        local y1 = y + radius * math.sin(angle)
        local x2 = x + (radius + size * 0.15) * math.cos(angle + 0.1)
        local y2 = y + (radius + size * 0.15) * math.sin(angle + 0.1)
        local x3 = x + (radius + size * 0.15) * math.cos(next_angle - 0.1)
        local y3 = y + (radius + size * 0.15) * math.sin(next_angle - 0.1)
        local x4 = x + radius * math.cos(next_angle)
        local y4 = y + radius * math.sin(next_angle)
        cairo_move_to(cr, x1, y1)
        cairo_line_to(cr, x2, y2)
        cairo_line_to(cr, x3, y3)
        cairo_line_to(cr, x4, y4)
        cairo_stroke(cr)
    end
    cairo_arc(cr, x, y, size * 0.15, 0, 2 * math.pi)
    cairo_stroke(cr)
end

function draw_top_processes(cr, x, y)
    local w, h = 250, 220
    draw_square(cr, x, y, w, h, transparency_bg)
    draw_icon_processes(cr, x + 15, y + 15, 20)
    draw_text(cr, x + 35, y + 20, "TOP PROCESSES", 12, transparency_value)

    local proc_y = y + 45
    for i = 1, 10 do
        local name = conky_parse('${top name ' .. i .. '}')
        local cpu = conky_parse('${top cpu ' .. i .. '}')
        if name and name ~= "" then
            if string.len(name) > 14 then name = string.sub(name, 1, 12) .. ".." end
            draw_text(cr, x + 10, proc_y, name, 12, transparency_text)
            draw_text(cr, x + w - 50, proc_y, cpu .. "%", 12, transparency_value)
            proc_y = proc_y + 17
        end
    end
end

-- ============================================================
-- DOCKER WIDGET
-- ============================================================

function draw_icon_docker(cr, x, y, size)
    cairo_set_operator(cr, operator_transpose[mode])
    cairo_set_source_rgba(cr, r, g, b, transparency_value)
    cairo_set_line_width(cr, 1.5)
    cairo_move_to(cr, x - size * 0.4, y + size * 0.2)
    cairo_line_to(cr, x + size * 0.4, y + size * 0.2)
    cairo_line_to(cr, x + size * 0.45, y + size * 0.35)
    cairo_line_to(cr, x - size * 0.35, y + size * 0.35)
    cairo_close_path(cr)
    cairo_stroke(cr)
    for i = 0, 2 do
        local cx = x - size * 0.25 + i * size * 0.2
        cairo_rectangle(cr, cx, y, size * 0.15, size * 0.15)
        cairo_stroke(cr)
    end
    cairo_move_to(cr, x - size * 0.4, y + size * 0.45)
    for i = 0, 8 do
        local wx = x - size * 0.4 + i * size * 0.1
        local wy = y + size * 0.45 + ((i % 2 == 0) and 0 or size * 0.05)
        cairo_line_to(cr, wx, wy)
    end
    cairo_stroke(cr)
end

function draw_docker_containers(cr, x, y)
    local w, h = 250, 180
    draw_square(cr, x, y, w, h, transparency_bg)
    draw_icon_docker(cr, x + 15, y + 15, 20)
    draw_text(cr, x + 35, y + 20, "DOCKER", 12, transparency_value)

    local containers = conky_parse('${exec docker ps --format "{{.Names}}" 2>/dev/null || echo ""}')
    local cont_y = y + 45
    local count = 0

    if containers and containers ~= "" then
        for line in containers:gmatch("[^\n]+") do
            local name = line:match("^%s*(.-)%s*$")
            if name and name ~= "" and count < 8 then
                if string.len(name) > 18 then name = string.sub(name, 1, 16) .. ".." end
                cairo_set_operator(cr, operator[mode])
                cairo_set_source_rgba(cr, 0.4, 0.8, 0.4, transparency_value)
                cairo_arc(cr, x + 14, cont_y - 3, 3, 0, 2 * math.pi)
                cairo_fill(cr)
                draw_text(cr, x + 22, cont_y, name, 12, transparency_text)
                cont_y = cont_y + 17
                count = count + 1
            end
        end
    end

    if count == 0 then
        draw_text(cr, x + 10, cont_y, "No containers", 12, transparency_text)
    end
end

-- ============================================================
-- K8S WIDGET
-- ============================================================

function draw_icon_k8s(cr, x, y, size)
    cairo_set_operator(cr, operator_transpose[mode])
    cairo_set_source_rgba(cr, r, g, b, transparency_value)
    cairo_set_line_width(cr, 1.5)
    local radius = size * 0.35
    local spokes = 7
    cairo_arc(cr, x, y, radius, 0, 2 * math.pi)
    cairo_stroke(cr)
    cairo_arc(cr, x, y, radius * 0.3, 0, 2 * math.pi)
    cairo_stroke(cr)
    for i = 0, spokes - 1 do
        local angle = (i / spokes) * 2 * math.pi
        cairo_move_to(cr, x + radius * 0.3 * math.cos(angle), y + radius * 0.3 * math.sin(angle))
        cairo_line_to(cr, x + radius * math.cos(angle), y + radius * math.sin(angle))
        cairo_stroke(cr)
    end
    cairo_move_to(cr, x, y - radius)
    cairo_line_to(cr, x, y - radius - size * 0.15)
    cairo_stroke(cr)
end

function draw_k8s_context(cr, x, y)
    local w, h = 250, 140
    draw_square(cr, x, y, w, h, transparency_bg)
    draw_icon_k8s(cr, x + 15, y + 15, 20)
    draw_text(cr, x + 35, y + 20, "K8S", 12, transparency_value)

    local ok1, context = pcall(function() return conky_parse('${exec kubectl config current-context 2>/dev/null || echo "N/A"}') end)
    if not ok1 then context = "N/A" end
    context = context or "N/A"
    if context == "" then context = "N/A" end
    draw_text(cr, x + 10, y + 45, "Context", 12, transparency_text)
    draw_text(cr, x + 10, y + 60, context, 14, transparency_value)

    local ok2, namespace = pcall(function() return conky_parse('${exec kubectl config view --minify --output "jsonpath={..namespace}" 2>/dev/null || echo "default"}') end)
    if not ok2 then namespace = "default" end
    namespace = namespace or "default"
    if namespace == "" then namespace = "default" end
    draw_text(cr, x + 10, y + 80, "Namespace", 12, transparency_text)
    draw_text(cr, x + 10, y + 95, namespace, 12, transparency_value)

    local ok3, nodes = pcall(function() return conky_parse('${exec kubectl get nodes --no-headers 2>/dev/null | wc -l || echo "0"}') end)
    if not ok3 then nodes = "0" end
    nodes = tostring(nodes or "0"):match("^%s*(.-)%s*$")
    if nodes == "" then nodes = "0" end
    draw_text(cr, x + 10, y + 115, "Nodes: " .. nodes, 12, transparency_value)
end

-- ============================================================
-- CRYPTO WIDGET
-- ============================================================

local crypto_script = os.getenv("HOME") .. "/.config/conky/all-widgets-conky-manager/crypto_price.py"
local cmd_base = "python3 " .. crypto_script .. " --coin " .. coin_id .. " --currency " .. currency

function crypto_get_val(flag)
    local raw = conky_parse("${exec " .. cmd_base .. " " .. flag .. " 2>/dev/null}")
    if raw then return raw:gsub("%s+", "") end
    return ""
end

function crypto_get_all_data()
    local raw = conky_parse("${exec " .. cmd_base .. " --get_all 2>/dev/null}")
    if not raw or raw == "" then return nil end
    local result = {}
    for line in raw:gmatch("[^\n]+") do
        local key, val = line:match("^(%w+):(.*)$")
        if key and val then result[key] = val end
    end
    return result
end

function parse_chart(csv)
    local prices = {}
    for price_str in csv:gmatch("[^,]+") do
        local val = tonumber(price_str)
        if val then table.insert(prices, val) end
    end
    return prices
end

function draw_icon_crypto(cr, x, y, size)
    cairo_set_operator(cr, operator_transpose[mode])
    cairo_set_source_rgba(cr, r, g, b, transparency_value)
    cairo_set_line_width(cr, 1.5)
    local radius = size * 0.35
    cairo_arc(cr, x, y, radius, 0, 2 * math.pi)
    cairo_fill(cr)
    cairo_arc(cr, x, y, radius * 0.6, 0, 2 * math.pi)
    cairo_stroke(cr)
    cairo_move_to(cr, x, y - radius * 0.4)
    cairo_line_to(cr, x, y + radius * 0.4)
    cairo_stroke(cr)
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

    local last_px = x + chart_w
    local last_py = y + chart_h - ((prices[#prices] - min_val) / range) * chart_h
    cairo_arc(cr, last_px, last_py, 3, 0, 2 * math.pi)
    cairo_fill(cr)

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
    draw_square(cr, x, y, w, h, transparency_bg)
    draw_icon_crypto(cr, x + 15, y + 15, 20)
    draw_text(cr, x + 35, y + 20, "CRYPTO", 12, transparency_value)

    local data = crypto_get_all_data()
    local raw_price = data and data["PRICE"] or ""
    local raw_change = data and data["CHANGE"] or ""
    local raw_mcap = data and data["MCAP"] or ""
    local raw_chart = crypto_get_val("--days " .. chart_days .. " --get_chart")

    local cy = y + 50
    draw_text(cr, x + 10, cy, coin_symbol, 12, transparency_value)

    cy = cy + 25
    local price_str = #raw_price > 0 and ("$" .. raw_price) or "..."
    draw_text(cr, x + 10, cy, price_str, 22, transparency_value)

    cy = cy + 22
    local change_val = tonumber(raw_change) or 0
    local change_str = #raw_change > 0 and (string.format("%.2f", change_val) .. "%") or "..."
    local prefix = change_val >= 0 and "+" or ""
    cairo_set_operator(cr, CAIRO_OPERATOR_OVER)
    if change_val >= 0 then
        cairo_set_source_rgba(cr, r_up, g_up, b_up, transparency_value)
    else
        cairo_set_source_rgba(cr, r_down, g_down, b_down, transparency_value)
    end
    cairo_set_font_size(cr, 14)
    cairo_move_to(cr, x + 10, cy)
    cairo_show_text(cr, prefix .. change_str)

    cy = cy + 15
    local chart_x = x + 10
    local chart_y = cy
    local chart_w = w - 35
    local chart_h = 80
    local prices = parse_chart(raw_chart)

    cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE)
    cairo_set_source_rgba(cr, r_border, g_border, b_border, 0.2)
    cairo_set_line_width(cr, 1)
    cairo_rectangle(cr, chart_x, chart_y, chart_w, chart_h)
    cairo_stroke(cr)

    draw_chart(cr, chart_x, chart_y, chart_w, chart_h, prices)
    cy = chart_y + chart_h + 10

    local mcap_str = #raw_mcap > 0 and raw_mcap or "..."
    draw_text(cr, x + 10, cy, "MCap: " .. mcap_str, 12, transparency_text)
    cy = cy + 15
    local days_label = chart_days .. "d"
    if chart_days == 1 then days_label = "24h" end
    draw_text(cr, x + 10, cy, days_label .. " chart", 9, transparency_text)
end

-- ============================================================
-- KEV WIDGET
-- ============================================================

function draw_icon_shield(cr, x, y, size)
    cairo_set_operator(cr, operator_transpose[mode])
    cairo_set_source_rgba(cr, r, g, b, transparency_value)
    cairo_set_line_width(cr, 1.5)
    local w = size * 0.35
    local h = size * 0.45
    cairo_move_to(cr, x, y - h)
    cairo_line_to(cr, x + w, y - h * 0.5)
    cairo_line_to(cr, x + w, y + h * 0.2)
    cairo_line_to(cr, x, y + h)
    cairo_line_to(cr, x - w, y + h * 0.2)
    cairo_line_to(cr, x - w, y - h * 0.5)
    cairo_close_path(cr)
    cairo_stroke(cr)
    cairo_move_to(cr, x, y - h * 0.3)
    cairo_line_to(cr, x, y + h * 0.15)
    cairo_stroke(cr)
    cairo_arc(cr, x, y + h * 0.35, 2, 0, 2 * math.pi)
    cairo_fill(cr)
end

function is_recent(date_str, max_days)
    local y, m, d = date_str:match("(%d+)-(%d+)-(%d+)")
    if not y then return false end
    local now = os.time()
    local entry = os.time{year=tonumber(y), month=tonumber(m), day=tonumber(d)}
    if not entry then return false end
    local diff = os.difftime(now, entry) / 86400
    return diff <= max_days
end

function draw_flashing_dot(cr, x, y, updates, cr2, cg2, cb2)
    local visible = (updates % 2 == 0)
    if visible then
        cairo_set_operator(cr, CAIRO_OPERATOR_OVER)
        cairo_set_source_rgba(cr, cr2, cg2, cb2, 1.0)
        cairo_arc(cr, x, y, 3, 0, 2 * math.pi)
        cairo_fill(cr)
    end
end

function draw_vuln_widget(cr, x, y, title, script_path, cr2, cg2, cb2)
    local w, h = 250, 250
    draw_square(cr, x, y, w, h, transparency_bg)
    draw_icon_shield(cr, x + 15, y + 15, 20)
    draw_text(cr, x + 35, y + 20, title, 12, transparency_value)
    draw_text(cr, x + w - 75, y + 20, "CISA KEV", 8, transparency_text)

    local raw = conky_parse("${exec python3 " .. script_path .. " --get_list --count 5 2>/dev/null}")
    local updates = tonumber(conky_parse("${updates}")) or 0
    local cy = y + 45
    local count = 0

    if raw and raw ~= "" then
        for line in raw:gmatch("[^\n]+") do
            local id, vendor, product, date = line:match("([^|]+)|([^|]+)|([^|]+)|([^|]+)")
            if id and count < 5 then
                if is_recent(date, 7) then
                    draw_flashing_dot(cr, x + w - 12, cy - 4, updates, cr2, cg2, cb2)
                end
                cairo_set_operator(cr, operator_transpose[mode])
                cairo_set_source_rgba(cr, cr2, cg2, cb2, transparency_value)
                cairo_set_font_size(cr, 11)
                cairo_move_to(cr, x + 10, cy)
                cairo_show_text(cr, id)
                local vp = vendor .. " " .. product
                if string.len(vp) > 28 then vp = string.sub(vp, 1, 26) .. ".." end
                draw_text(cr, x + 10, cy + 14, vp, 9, transparency_text)
                draw_text(cr, x + 10, cy + 26, date, 8, transparency_text)
                cy = cy + 40
                count = count + 1
            end
        end
    end

    if count == 0 then
        draw_text(cr, x + 10, cy, "No entries", 11, transparency_text)
    end
end

-- ============================================================
-- WEATHER WIDGET
-- ============================================================

function draw_weather_circle(cr, pos_x, pos_y, radius, trans)
    cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE)
    cairo_set_source_rgba(cr, r_circle_w, g_circle_w, b_circle_w, trans)
    cairo_set_line_width(cr, 1)
    cairo_arc(cr, pos_x, pos_y, radius, 0, 2 * math.pi)
    cairo_fill(cr)
end

function draw_weather_border(cr, pos_x, pos_y, radius, trans)
    cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE)
    cairo_set_source_rgba(cr, r_border_w, g_border_w, b_border_w, trans)
    cairo_set_line_width(cr, 2)
    cairo_arc(cr, pos_x, pos_y, radius, 0, 2 * math.pi)
    cairo_stroke(cr)
end

function draw_weather_icon(cr, pos_x, pos_y, image_path, trans)
    cairo_set_operator(cr, CAIRO_OPERATOR_OVER)
    local home = os.getenv("HOME") or ""
    local img_path = home .. "/.config/conky/all-widgets-conky-manager/PNG/" .. image_path .. ".png"
    local image = cairo_image_surface_create_from_png(img_path)
    local w_img = cairo_image_surface_get_width(image)
    local h_img = cairo_image_surface_get_height(image)
    cairo_save(cr)
    cairo_set_source_surface(cr, image, pos_x - w_img / 2, pos_y - h_img / 2)
    cairo_paint_with_alpha(cr, trans)
    cairo_surface_destroy(image)
    cairo_restore(cr)
end

function draw_weather_text(cr, pos_x, pos_y, r_t, g_t, b_t, trans, text, font_size, shift_x, shift_y)
    cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE)
    cairo_set_source_rgba(cr, r_t, g_t, b_t, trans)
    local ct = cairo_text_extents_t:create()
    cairo_set_font_size(cr, font_size)
    cairo_text_extents(cr, text, ct)
    cairo_move_to(cr, pos_x - ct.width / 2 + shift_x, pos_y + ct.height / 2 + shift_y)
    cairo_show_text(cr, text)
    cairo_close_path(cr)
    ct:destroy()
end

function draw_weather_widget(cr, x, y)
    local widget_w = 120
    local widget_h = 120
    local radius = widget_w / 2
    local pos_x = x + widget_w / 2
    local pos_y = y + widget_h / 2

    draw_weather_circle(cr, pos_x, pos_y, radius, transparency_w)
    draw_weather_border(cr, pos_x, pos_y, radius + 1, transparency_border_w)

    cairo_select_font_face(cr, "DejaVu Sans Book", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    draw_weather_text(cr, pos_x, pos_y, r_text_w, g_text_w, b_text_w, transparency_text_w, city, City_font, 0, -35)

    local day = conky_parse('${exec date +%A}') or "N/A"
    draw_weather_text(cr, pos_x, pos_y, r_text_w, g_text_w, b_text_w, transparency_text_w, day, Day_font, 0, 35)

    cairo_select_font_face(cr, "DejaVu Sans Book", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD)
    local temperature = conky_parse("${exec ~/.config/conky/all-widgets-conky-manager/openweather.py --get_temp_c --api_key " .. api_key .. " --city " .. "\"" .. city .. "\"" .. " --ccode " .. country_code .. "}") or "N/A"
    draw_weather_text(cr, pos_x, pos_y, r_text_w, g_text_w, b_text_w, transparency_text_w, temperature .. "˚C", Temperature_font, 19.25, 0)

    local image_path = conky_parse("${exec ~/.config/conky/all-widgets-conky-manager/openweather.py --get_weather_icon --api_key " .. api_key .. " --city " .. "\"" .. city .. "\"" .. " --ccode " .. country_code .. "}") or ""
    if image_path ~= "" then
        draw_weather_icon(cr, pos_x - 60, pos_y, image_path, transparency_weather_icon)
    end
end

-- ============================================================
-- CALENDAR WIDGET
-- ============================================================

function cal_create_circle_hdd(cr, w_c, h_c, elements, distance_between_blocks, radius, line_width, current)
    cairo_set_line_width(cr, line_width)
    cairo_set_source_rgba(cr, r_cal, g_cal, b_cal, transparency_cal)
    cairo_new_path(cr)
    local number_of_arcs = (360 - (elements * distance_between_blocks)) / elements
    local start_angel = 270
    local percent_per_element = 100.0 / elements
    local charged_elements = current / percent_per_element
    for i = 1, elements do
        if charged_elements >= i then
            cairo_set_source_rgba(cr, r_c_cal, g_c_cal, b_c_cal, transparency_active_cal)
        end
        cairo_arc(cr, w_c, h_c, radius, start_angel * math.pi / 180, (start_angel + number_of_arcs) * math.pi / 180)
        cairo_stroke(cr)
        start_angel = start_angel + number_of_arcs + distance_between_blocks
        cairo_set_source_rgba(cr, r_cal, g_cal, b_cal, transparency_cal)
    end
end

function cal_create_circle(cr, w_c, h_c, elements, distance_between_blocks, two_number_degree, radius, line_width, draw_operator, radius_shift_for_text, current, days, shift_days_distance)
    elements = tonumber(elements) or 12
    cairo_set_line_width(cr, line_width)
    cairo_set_source_rgba(cr, r_cal, g_cal, b_cal, transparency_cal)
    cairo_new_path(cr)
    local number_of_arcs = (360 - (elements * distance_between_blocks)) / elements
    local start_angel = 270
    for i = 1, elements do
        if i == current then
            cairo_set_source_rgba(cr, r_c_cal, g_c_cal, b_c_cal, transparency_active_cal)
        end
        cairo_arc(cr, w_c / 2, h_c / 2, radius, start_angel * math.pi / 180, (start_angel + number_of_arcs) * math.pi / 180)
        cairo_stroke(cr)
        start_angel = start_angel + number_of_arcs + distance_between_blocks
        cairo_set_source_rgba(cr, r_cal, g_cal, b_cal, transparency_cal)
    end
    start_angel = 270
    cairo_set_operator(cr, draw_operator)
    for i = 1, elements do
        if i == current then
            cairo_set_source_rgba(cr, r_c_cal, g_c_cal, b_c_cal, transparency_active_cal)
        end
        if string.len(tostring(i)) == 2 and days == "" then
            cairo_move_to(cr, w_c / 2 + ((radius + radius_shift_for_text) * math.cos((start_angel + ((number_of_arcs - two_number_degree) / 2)) * (math.pi / 180.0))), h_c / 2 + ((radius + radius_shift_for_text) * math.sin((start_angel + ((number_of_arcs - two_number_degree) / 2)) * (math.pi / 180.0))))
            cairo_rotate(cr, (((number_of_arcs - two_number_degree) / 2) + (number_of_arcs + distance_between_blocks) * (i - 1)) * math.pi / 180.0)
            cairo_show_text(cr, tostring(i))
            cairo_rotate(cr, -(((number_of_arcs - two_number_degree) / 2) + (number_of_arcs + distance_between_blocks) * (i - 1)) * math.pi / 180.0)
        elseif days ~= "" then
            cairo_move_to(cr, w_c / 2 + ((radius + radius_shift_for_text) * math.cos((start_angel + ((math.abs((number_of_arcs - shift_days_distance)) / 2))) * (math.pi / 180.0))), h_c / 2 + ((radius + radius_shift_for_text) * math.sin((start_angel + ((math.abs((number_of_arcs - shift_days_distance)) / 2))) * (math.pi / 180.0))))
            cairo_rotate(cr, ((math.abs((number_of_arcs - shift_days_distance)) / 2) + (number_of_arcs + distance_between_blocks) * (i - 1) + 4) * math.pi / 180.0)
            cairo_show_text(cr, days[i])
            cairo_rotate(cr, -((math.abs((number_of_arcs - shift_days_distance)) / 2) + (number_of_arcs + distance_between_blocks) * (i - 1) + 4) * math.pi / 180.0)
        elseif string.len(tostring(i)) == 1 and days == "" then
            cairo_move_to(cr, w_c / 2 + ((radius + radius_shift_for_text) * math.cos((start_angel + ((number_of_arcs - distance_between_blocks) / 2)) * (math.pi / 180.0))), h_c / 2 + ((radius + radius_shift_for_text) * math.sin((start_angel + ((number_of_arcs - distance_between_blocks) / 2)) * (math.pi / 180.0))))
            cairo_rotate(cr, (((number_of_arcs - distance_between_blocks) / 2) + (number_of_arcs + distance_between_blocks) * (i - 1)) * math.pi / 180.0)
            cairo_show_text(cr, tostring(i))
            cairo_rotate(cr, -(((number_of_arcs - distance_between_blocks) / 2) + (number_of_arcs + distance_between_blocks) * (i - 1)) * math.pi / 180.0)
        end
        start_angel = start_angel + number_of_arcs + distance_between_blocks
        cairo_set_source_rgba(cr, r_cal, g_cal, b_cal, transparency_cal)
    end
    cairo_close_path(cr)
    cairo_set_operator(cr, CAIRO_OPERATOR_OVER)
end

function draw_calendar_widget(cr, x, y)
    local widget_w = 600
    local widget_h = 500
    local center_x = x + widget_w / 2
    local center_y = y + widget_h / 2

    cairo_set_line_width(cr, 3)
    cairo_set_font_size(cr, 12)
    cairo_select_font_face(cr, "DejaVu Sans Book", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)

    cal_create_circle(cr, 2 * center_x, 2 * center_y, 52.0, 2, 3.5, 225, 3, CAIRO_OPERATOR_OVER, 4, tonumber(conky_parse('${exec date +%V}')), '')
    cal_create_circle(cr, 2 * center_x, 2 * center_y, tonumber(conky_parse('${exec cal |egrep -v [a-z] |wc -w}')), 2, 3.5, 200, 13, CAIRO_OPERATOR_CLEAR, -4.5, tonumber(conky_parse('${exec date +%d}')), '')

    local days = {"Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"}
    cal_create_circle(cr, 2 * center_x, 2 * center_y, 7, 2, 3.5, 150, 13, CAIRO_OPERATOR_CLEAR, -4, tonumber(conky_parse('${exec date +%u}')), days, 8.5)

    local month = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
    cal_create_circle(cr, 2 * center_x, 2 * center_y, 12, 2, 3.5, 175, 13, CAIRO_OPERATOR_CLEAR, -4, tonumber(conky_parse('${exec date +%m}')), month, 5.5)

    cairo_set_font_size(cr, 42)
    cairo_move_to(cr, center_x - 54, center_y)
    cairo_show_text(cr, conky_parse('${exec date +%H}') .. ":" .. conky_parse('${exec date +%M}'))

    cairo_set_operator(cr, CAIRO_OPERATOR_OVER)
    angle1 = 0.0 * (math.pi / 180.0)
    angle2 = 360.0 * (math.pi / 180.0)

    cal_create_circle_hdd(cr, center_x - 60, center_y - 80, 20, 3, 20, 3, 100 - tonumber(conky_parse("${fs_free_perc /}")))
    cal_create_circle_hdd(cr, center_x + 60, center_y - 80, 20, 3, 20, 3, 100 - tonumber(conky_parse("${fs_free_perc /home}")))

    cairo_arc(cr, center_x - 60, center_y - 80, 14, 0, 2 * math.pi)
    cairo_fill(cr)
    cairo_arc(cr, center_x + 60, center_y - 80, 14, 0, 2 * math.pi)
    cairo_fill(cr)

    cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR)
    cairo_move_to(cr, center_x - 64, center_y - 75)
    cairo_show_text(cr, "R")
    cairo_move_to(cr, center_x + 56, center_y - 75)
    cairo_show_text(cr, "H")
    cairo_set_operator(cr, CAIRO_OPERATOR_OVER)

    -- Music Player
    local mx = center_x
    local music_y = center_y + 50
    local artist = conky_parse('${exec playerctl metadata artist 2>/dev/null || echo ""}')
    local title = conky_parse('${exec playerctl metadata title 2>/dev/null || echo ""}')
    local status = conky_parse('${exec playerctl status 2>/dev/null || echo "Stopped"}')
    local position = conky_parse('${exec playerctl position 2>/dev/null || echo "0"}')
    local duration = conky_parse('${exec playerctl metadata mpris:length 2>/dev/null || echo "0"}')

    if string.len(artist) > 20 then artist = string.sub(artist, 1, 18) .. ".." end
    if string.len(title) > 20 then title = string.sub(title, 1, 18) .. ".." end

    local pos_val = tonumber(position) or 0
    local dur_val = (tonumber(duration) or 0) / 1000000
    local pos_min = math.floor(pos_val / 60)
    local pos_sec = math.floor(pos_val % 60)
    local dur_min = math.floor(dur_val / 60)
    local dur_sec = math.floor(dur_val % 60)
    local time_str = string.format("%d:%02d / %d:%02d", pos_min, pos_sec, dur_min, dur_sec)

    cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE)
    cairo_set_source_rgba(cr, r_cal, g_cal, b_cal, transparency_active_cal)
    cairo_set_font_size(cr, 10)
    cairo_move_to(cr, mx - 40, music_y)
    cairo_show_text(cr, "MUSIC: " .. status)
    if artist ~= "" then
        cairo_move_to(cr, mx - 40, music_y + 15)
        cairo_show_text(cr, artist)
    end
    if title ~= "" then
        cairo_move_to(cr, mx - 40, music_y + 30)
        cairo_show_text(cr, title)
    end
    cairo_set_source_rgba(cr, r_cal, g_cal, b_cal, transparency_cal)
    cairo_move_to(cr, mx - 40, music_y + 50)
    cairo_show_text(cr, time_str)
    if dur_val > 0 then
        local progress = pos_val / dur_val
        cairo_set_source_rgba(cr, r_cal, g_cal, b_cal, 0.2)
        cairo_rectangle(cr, mx - 40, music_y + 60, 80, 4)
        cairo_fill(cr)
        cairo_set_source_rgba(cr, r_c_cal, g_c_cal, b_c_cal, transparency_active_cal)
        cairo_rectangle(cr, mx - 40, music_y + 60, 80 * progress, 4)
        cairo_fill(cr)
    end
end

-- ============================================================
-- REVISITED WIDGET (Square Horizontal)
-- ============================================================

function revisited_draw_square(cr, pos_x, pos_y, rectangle_x, rectangle_y, color1, color2, color3, trans)
    cairo_set_operator(cr, operator[mode])
    cairo_set_source_rgba(cr, color1, color2, color3, trans)
    cairo_set_line_width(cr, 2)
    cairo_rectangle(cr, pos_x, pos_y, rectangle_x, rectangle_y)
    cairo_fill(cr)

    cairo_set_operator(cr, operator_transpose[mode])
    cairo_set_line_width(cr, special_border)
    cairo_set_source_rgba(cr, color1, color2, color3, trans)
    cairo_move_to(cr, pos_x + 3, pos_y + 3)
    cairo_rel_line_to(cr, rectangle_x - 6, 0)
    cairo_rel_line_to(cr, 0, rectangle_y - 6)
    cairo_rel_line_to(cr, -(rectangle_x - 6))
    cairo_close_path(cr)
    cairo_stroke(cr)

    cairo_set_operator(cr, operator[mode])
    cairo_set_source_rgba(cr, r_border, g_border, b_border, transparency_border)
    cairo_set_line_width(cr, border_size)
    cairo_rectangle(cr, pos_x, pos_y, rectangle_x, rectangle_y)
    cairo_stroke(cr)
end

function revisited_draw_battery(cr, pos_x, pos_y, start_rect_height, color1, color2, color3, trans, gap_y_text)
    cairo_set_operator(cr, operator_transpose[mode])
    cairo_set_source_rgba(cr, color1, color2, color3, trans)
    cairo_set_line_width(cr, 2)
    set_battery_blocks_x = 0
    battery_gap_y = (start_rect_height / 2) - 27 / 2 + pos_y
    cairo_move_to(cr, pos_x, battery_gap_y)
    cairo_rel_line_to(cr, 64, 0)
    cairo_rel_line_to(cr, 0, ((27 - 10) / 2))
    cairo_rel_line_to(cr, 5, 0)
    cairo_rel_line_to(cr, 0, 10)
    cairo_rel_line_to(cr, -5, 0)
    cairo_rel_line_to(cr, 0, ((27 - 10) / 2))
    cairo_rel_line_to(cr, -64, 0)
    cairo_close_path(cr)
    cairo_fill(cr)

    number_of_charges = math.floor((12 / 100) * tonumber(conky_parse('${battery_percent ' .. battery_number .. '}')))
    cairo_set_operator(cr, operator[mode])
    for i = 1, number_of_charges do
        cairo_rectangle(cr, pos_x + 3 + set_battery_blocks_x, 3 + battery_gap_y, 3, 21)
        cairo_fill(cr)
        set_battery_blocks_x = set_battery_blocks_x + 5
    end

    cairo_set_operator(cr, operator_transpose[mode])
    cairo_set_font_size(cr, 21)
    cairo_move_to(cr, pos_x + 69 + 10, gap_y_text + pos_y)
    local percent = conky_parse('${battery_percent ' .. battery_number .. '}')
    if string.len(percent) == 1 then
        cairo_show_text(cr, "0" .. percent .. "%")
    elseif string.len(percent) == 3 then
        cairo_show_text(cr, "100%")
    else
        cairo_show_text(cr, percent .. "%")
    end

    cairo_move_to(cr, pos_x + 69 + 10, gap_y_text + 18 + pos_y)
    cairo_set_font_size(cr, 12)
    local status = conky_parse('${battery ' .. battery_number .. '}')
    if string.find(status, "discharging") then status = "Discharging"
    elseif string.find(status, "charging") then status = "Charging"
    elseif string.find(status, "charged") then status = "Charged" end
    if status == "" then status = "N/A" end
    cairo_show_text(cr, status)
    cairo_move_to(cr, pos_x + 69 + 10, gap_y_text + 18 + 14 + pos_y)
    local battery_time = conky_parse('${battery_time ' .. battery_number .. '}')
    if battery_time == "" then battery_time = "N/A" end
    cairo_show_text(cr, battery_time)
end

function revisited_draw_folder(cr, x_pos, y_pos, start_rect_height, hdd, folder_name, r_cd, g_cd, b_cd, trans_d, gap_y_text)
    cairo_set_source_rgba(cr, r_cd, g_cd, b_cd, trans_d)
    cairo_set_operator(cr, operator_transpose[mode])
    local distance_between_arcs = 0
    local number_of_arcs = 20
    local arcs_length = (360 - (number_of_arcs * distance_between_arcs)) / number_of_arcs
    local start_angel = 270
    local used_blocks = math.floor((number_of_arcs / 100) * tonumber(conky_parse('${fs_free_perc ' .. hdd .. '}')))
    local radius = 29
    cairo_set_line_width(cr, 6)
    cairo_arc(cr, x_pos + 10 + 34, (start_rect_height / 2) + y_pos, radius, start_angel * math.pi / 180, (start_angel + 360) * math.pi / 180)
    cairo_stroke(cr)
    cairo_set_line_width(cr, 3)
    cairo_set_operator(cr, operator[mode])
    for i = 1, used_blocks do
        cairo_arc(cr, x_pos + 10 + 34, (start_rect_height / 2) + y_pos, radius, start_angel * math.pi / 180, (start_angel + arcs_length) * math.pi / 180)
        cairo_stroke(cr)
        start_angel = start_angel + arcs_length + distance_between_arcs
    end
    cairo_set_operator(cr, operator_transpose[mode])
    cairo_set_source_rgba(cr, r_cd, g_cd, b_cd, trans_d)
    cairo_set_line_width(cr, 2)
    cairo_move_to(cr, x_pos + 10 + 34 - 15, (start_rect_height / 2 - 5.5) + y_pos)
    cairo_rel_line_to(cr, 15, -9)
    cairo_rel_line_to(cr, 15, 9)
    cairo_rel_line_to(cr, 0, 4)
    cairo_rel_line_to(cr, -15, -9)
    cairo_rel_line_to(cr, -15, 9)
    cairo_close_path(cr)
    cairo_fill(cr)
    cairo_move_to(cr, x_pos + 10 + 34 - 15 + 24, (start_rect_height / 2 - 5.5) - 6 + y_pos)
    cairo_rel_line_to(cr, 4, 2)
    cairo_rel_line_to(cr, 0, -5)
    cairo_rel_line_to(cr, -4, 0)
    cairo_close_path(cr)
    cairo_fill(cr)
    cairo_move_to(cr, x_pos + 10 + 34 - 15 + 4, (start_rect_height / 2 - 5.5) + 5 + y_pos)
    cairo_rel_line_to(cr, 11, -7)
    cairo_rel_line_to(cr, 11, 7)
    cairo_rel_line_to(cr, 0, 15)
    cairo_rel_line_to(cr, -(11 * 2 - math.abs(-8)) / 2, 0)
    cairo_rel_line_to(cr, 0, -6)
    cairo_rel_line_to(cr, -8, 0)
    cairo_rel_line_to(cr, 0, 6)
    cairo_rel_line_to(cr, -(11 * 2 - math.abs(-8)) / 2, 0)
    cairo_close_path(cr)
    cairo_fill(cr)
    cairo_set_operator(cr, operator_transpose[mode])
    cairo_set_font_size(cr, 21)
    cairo_move_to(cr, x_pos + 10 + 34 + 34 + 10, gap_y_text + y_pos)
    cairo_show_text(cr, conky_parse('${fs_free_perc ' .. hdd .. '}') .. "%")
    cairo_set_font_size(cr, 12)
    cairo_move_to(cr, x_pos + 10 + 34 + 34 + 10, gap_y_text + 18 + y_pos)
    cairo_show_text(cr, folder_name)
    cairo_move_to(cr, x_pos + 10 + 34 + 34 + 10, gap_y_text + 18 + 14 + y_pos)
    cairo_show_text(cr, conky_parse('${fs_free ' .. hdd .. '}') .. "/" .. conky_parse('${fs_size ' .. hdd .. '}'))
end

function revisited_draw_cpu(cr, number_of_cpus, x_pos, y_pos, r_cpu, g_cpu, b_cpu, trans_cpu, gap_y_text)
    cairo_set_operator(cr, operator_transpose[mode])
    cairo_set_source_rgba(cr, r_cpu, g_cpu, b_cpu, trans_cpu)
    multipler = 68 / 100
    for i = 1, number_of_cpus do
        cairo_rectangle(cr, x_pos + ((68 - (5 * (number_of_cpus - 1))) / number_of_cpus + 5) * (i - 1), y_pos + 68, (68 - (5 * (number_of_cpus - 1))) / number_of_cpus, -multipler * tonumber(conky_parse('${cpu cpu' .. tostring(i) .. '}')))
        cairo_fill(cr)
    end
    cairo_set_font_size(cr, 21)
    cairo_move_to(cr, x_pos + 68 + 10, gap_y_text + y_pos - 10)
    cairo_show_text(cr, conky_parse('${cpu cpu0}' .. "%"))
    cairo_set_font_size(cr, 12)
    cairo_move_to(cr, x_pos + 68 + 10, gap_y_text + 18 + y_pos - 10)
    cairo_show_text(cr, "CPU")
    cairo_move_to(cr, x_pos + 68 + 10, gap_y_text + 18 + 14 + y_pos - 10)
    cairo_show_text(cr, "Total usage")
end

function revisited_draw_ram(cr, x_pos, y_pos, radius_r, r_ram, g_ram, b_ram, trans_ram, gap_y_text)
    cairo_set_operator(cr, operator_transpose[mode])
    cairo_set_source_rgba(cr, r_ram, g_ram, b_ram, trans_ram)
    cairo_set_line_width(cr, 2)
    local align_middle = 14
    cairo_arc(cr, x_pos + radius_r, y_pos + radius_r + align_middle, radius_r, 180 * math.pi / 180, (180 + 90) * math.pi / 180)
    cairo_arc(cr, x_pos + radius_r + (68 - 2 * radius_r), y_pos + radius_r + align_middle, radius_r, -90 * math.pi / 180, 0 * math.pi / 180)
    cairo_arc(cr, x_pos + radius_r + (68 - 2 * radius_r), y_pos + radius_r + 20 + align_middle, radius_r, 0 * math.pi / 180, 90 * math.pi / 180)
    cairo_arc(cr, x_pos + radius_r, y_pos + radius_r + 20 + align_middle, radius_r, 90 * math.pi / 180, 180 * math.pi / 180)
    cairo_close_path(cr)
    cairo_fill(cr)
    local multipler_r = 7 / 100
    local free_memory = math.floor((100 - tonumber(conky_parse('${memperc}'))) * multipler_r)
    for i = 1, 7 do
        cairo_move_to(cr, x_pos + radius_r + (8 * (i - 1)) - 2, y_pos + radius_r + 20 + align_middle + 10 + 1 + 2 + 1)
        cairo_rel_line_to(cr, 4, 0)
        cairo_arc(cr, x_pos + radius_r + (8 * (i - 1)), y_pos + radius_r + 20 + align_middle + 10 + 1 + 2 + 1 + 4, 2, 0 * math.pi / 180, 180 * math.pi / 180)
        cairo_close_path(cr)
        if i <= free_memory then
            cairo_stroke_preserve(cr)
            cairo_fill(cr)
        else
            cairo_stroke(cr)
        end
        cairo_move_to(cr, x_pos + radius_r + (8 * (i - 1)) + 2, y_pos + align_middle - 4)
        cairo_rel_line_to(cr, -4, 0)
        cairo_arc(cr, x_pos + radius_r + (8 * (i - 1)), y_pos + align_middle - 4 - 4, 2, 180 * math.pi / 180, 0 * math.pi / 180)
        cairo_close_path(cr)
        if i <= free_memory then
            cairo_stroke_preserve(cr)
            cairo_fill(cr)
        else
            cairo_stroke(cr)
        end
    end
    cairo_set_operator(cr, operator[mode])
    cairo_set_font_size(cr, 21)
    cairo_move_to(cr, x_pos - 1 + 33 - 22, y_pos + align_middle + 1 + 19 + 8)
    cairo_show_text(cr, "RAM")
    cairo_set_operator(cr, operator_transpose[mode])
    cairo_set_font_size(cr, 21)
    cairo_move_to(cr, x_pos + 68 + 10, gap_y_text + y_pos - 10)
    cairo_show_text(cr, tostring(100 - tonumber(conky_parse('${memperc}'))) .. "%")
    cairo_set_font_size(cr, 12)
    cairo_move_to(cr, x_pos + 68 + 10, gap_y_text + 18 + y_pos - 10)
    cairo_show_text(cr, "Free RAM")
    cairo_move_to(cr, x_pos + 68 + 10, gap_y_text + 18 + 14 + y_pos - 10)
    cairo_show_text(cr, conky_parse('${memeasyfree}') .. '/' .. conky_parse('${memmax}'))
end

function draw_revisited_widget(cr, x, y)
    local start_rect_height = 88
    local start_rect_width = 200
    local gap_y_text_r = (start_rect_height / 2) - 7
    local gap_x_r = 10
    local gap_y_r = 10
    local gap_x_fix = x + 2
    local gap_y_fix = y + 2
    local start_rect_width_no_battery = 106
    local radius_r = 10

    if battery then
        revisited_draw_square(cr, gap_x_fix, gap_y_fix, start_rect_width, start_rect_height, r_battery, g_battery, b_battery, transparency_battery)
        revisited_draw_battery(cr, gap_x_r + gap_x_fix, gap_y_fix, start_rect_height, r_battery, g_battery, b_battery, transparency_battery, gap_y_text_r)
        for i = 1, drives do
            revisited_draw_square(cr, (start_rect_width + gap_x_distance) * i + gap_x_fix, gap_y_fix, start_rect_width, start_rect_height, drive_colors[i][1], drive_colors[i][2], drive_colors[i][3], drive_colors[i][4])
            revisited_draw_folder(cr, (start_rect_width + gap_x_distance) * i + gap_x_fix, gap_y_fix, start_rect_height, drive_paths[i], drive_names[i], drive_colors[i][1], drive_colors[i][2], drive_colors[i][3], drive_colors[i][4], gap_y_text_r)
        end
        revisited_draw_square(cr, (start_rect_width + gap_x_distance) * (drives + 1) + gap_x_fix, gap_y_fix, start_rect_width, start_rect_height, r_CPU, g_CPU, b_CPU, transparency_CPU)
        revisited_draw_cpu(cr, number_of_cpus, (start_rect_width + gap_x_distance) * (drives + 1) + gap_x_r + gap_x_fix, gap_y_fix + gap_y_r, r_CPU, g_CPU, b_CPU, transparency_CPU, gap_y_text_r)
        revisited_draw_square(cr, (start_rect_width + gap_x_distance) * (drives + 2) + gap_x_fix, gap_y_fix, start_rect_width, start_rect_height, r_RAM, g_RAM, b_RAM, transparency_RAM)
        revisited_draw_ram(cr, (start_rect_width + gap_x_distance) * (drives + 2) + gap_x_r + gap_x_fix, gap_y_r + gap_y_fix, radius_r, r_RAM, g_RAM, b_RAM, transparency_RAM, gap_y_text_r)
    else
        for i = 1, drives do
            revisited_draw_square(cr, start_rect_width_no_battery + gap_x_fix, gap_y_fix, start_rect_width, start_rect_height, drive_colors[i][1], drive_colors[i][2], drive_colors[i][3], drive_colors[i][4])
            revisited_draw_folder(cr, start_rect_width_no_battery + gap_x_fix, gap_y_fix, start_rect_height, drive_paths[i], drive_names[i], drive_colors[i][1], drive_colors[i][2], drive_colors[i][3], drive_colors[i][4], gap_y_text_r)
            start_rect_width_no_battery = start_rect_width_no_battery + gap_x_distance + 200
        end
        revisited_draw_square(cr, start_rect_width_no_battery + gap_x_fix, gap_y_fix, start_rect_width, start_rect_height, r_CPU, g_CPU, b_CPU, transparency_CPU)
        revisited_draw_cpu(cr, number_of_cpus, start_rect_width_no_battery + gap_x_r + gap_x_fix, gap_y_fix + gap_y_r, r_CPU, g_CPU, b_CPU, transparency_CPU, gap_y_text_r)
        start_rect_width_no_battery = start_rect_width_no_battery + gap_x_distance + 200
        revisited_draw_square(cr, start_rect_width_no_battery + gap_x_fix, gap_y_fix, start_rect_width, start_rect_height, r_RAM, g_RAM, b_RAM, transparency_RAM)
        revisited_draw_ram(cr, start_rect_width_no_battery + gap_x_r + gap_x_fix, gap_y_r + gap_y_fix, radius_r, r_RAM, g_RAM, b_RAM, transparency_RAM, gap_y_text_r)
    end
end

-- ============================================================
-- MAIN DRAW FUNCTION - calls all widgets
-- ============================================================

function draw_function(cr)
    local w, h = conky_window.width, conky_window.height
    cairo_select_font_face(cr, "DejaVu Sans Book", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)

    -- Network
    if enabled_network then
        local nx = positions["network-conky-manager"].x
        local ny = positions["network-conky-manager"].y
        draw_network_info(cr, nx, ny)
    end

    -- Bandwidth
    if enabled_bandwidth then
        local bx = positions["bandwidth-conky-manager"].x
        local by = positions["bandwidth-conky-manager"].y
        draw_network_bandwidth(cr, bx, by)
    end

    -- Processes
    if enabled_processes then
        local px = positions["processes-conky-manager"].x
        local py = positions["processes-conky-manager"].y
        draw_top_processes(cr, px, py)
    end

    -- Docker
    if enabled_docker then
        local dx = positions["docker-conky-manager"].x
        local dy = positions["docker-conky-manager"].y
        draw_docker_containers(cr, dx, dy)
    end

    -- K8S
    if enabled_k8s then
        local kx = positions["k8s-conky-manager"].x
        local ky = positions["k8s-conky-manager"].y
        draw_k8s_context(cr, kx, ky)
    end

    -- Crypto
    if enabled_crypto then
        local cx = positions["crypto-conky-manager"].x
        local cy = positions["crypto-conky-manager"].y
        draw_crypto_widget(cr, cx, cy)
    end

    -- KEV
    if enabled_kev then
        local kx2 = positions["kev-conky-manager"].x
        local ky2 = positions["kev-conky-manager"].y
        draw_vuln_widget(cr, kx2, ky2, "KEV", os.getenv("HOME") .. "/.config/conky/all-widgets-conky-manager/fetch_vulns.py", r_crit_kev, g_crit_kev, b_crit_kev)
    end

    -- Infra
    if enabled_infra then
        local ix = positions["infra-conky-manager"].x
        local iy = positions["infra-conky-manager"].y
        draw_vuln_widget(cr, ix, iy, "INFRA", os.getenv("HOME") .. "/.config/conky/all-widgets-conky-manager/fetch_infra_vulns.py", r_crit_infra, g_crit_infra, b_crit_infra)
    end

    -- Weather
    if enabled_weather then
        local wx = positions["weather-conky-manager"].x
        local wy = positions["weather-conky-manager"].y
        draw_weather_widget(cr, wx, wy)
    end

    -- Calendar
    if enabled_calendar then
        local calx = positions["calendar-conky-manager"].x
        local caly = positions["calendar-conky-manager"].y
        draw_calendar_widget(cr, calx, caly)
    end

    -- Revisited
    if enabled_revisited then
        local rx = positions["revisited-conky-manager"].x
        local ry = positions["revisited-conky-manager"].y
        draw_revisited_widget(cr, rx, ry)
    end
end

function conky_start_widgets()
    local function draw_conky_function(cr)
        local ok, err = pcall(draw_function, cr)
        if not ok then
            local f = io.open(os.getenv("HOME") .. "/.config/conky/all-widgets-conky-manager/error.log", "a")
            if f then
                f:write(os.date("%Y-%m-%d %H:%M:%S") .. " " .. tostring(err) .. "\n")
                f:close()
            end
        end
    end

    if conky_window == nil then return end
    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
    local cr = cairo_create(cs)

    local updates = conky_parse('${updates}')
    if tonumber(updates or "0") > 5 then
        draw_conky_function(cr)
    end
    cairo_surface_destroy(cs)
    cairo_destroy(cr)
end

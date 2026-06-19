-- System Widgets - Network, Processes, Docker, K8s
-- Styled exactly like Conky-Revisited-2

require 'cairo'

-- Colors (matching Revisited-2 exactly)
HTML_color = "#FFFFFF"
HTML_color_border = "#FFFFFF"
transparency_bg = 0.6
transparency_border = 0.1
transparency_text = 0.6
transparency_value = 0.9

-- Mode (1 = background, 2 = no background)
mode = 1

-- Border size
border_size = 4

operator = {CAIRO_OPERATOR_SOURCE, CAIRO_OPERATOR_CLEAR}
operator_transpose = {CAIRO_OPERATOR_CLEAR, CAIRO_OPERATOR_SOURCE}

function hex2rgb(hex)
    hex = hex:gsub("#","")
    return (tonumber("0x"..hex:sub(1,2))/255), (tonumber("0x"..hex:sub(3,4))/255), tonumber(("0x"..hex:sub(5,6))/255)
end

r, g, b = hex2rgb(HTML_color)
r_border, g_border, b_border = hex2rgb(HTML_color_border)

-- Icon drawing functions
function draw_icon_network(cr, x, y, size)
    cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE)
    cairo_set_source_rgba(cr, r, g, b, transparency_active)
    cairo_set_line_width(cr, 1.5)
    -- Signal waves
    for i = 0, 2 do
        local radius = size * 0.3 + i * size * 0.25
        cairo_arc(cr, x, y + size * 0.3, radius, -0.8 * math.pi, -0.2 * math.pi)
        cairo_stroke(cr)
    end
    -- Dot
    cairo_arc(cr, x, y + size * 0.3, 2, 0, 2 * math.pi)
    cairo_fill(cr)
end

function draw_icon_bandwidth(cr, x, y, size)
    cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE)
    cairo_set_source_rgba(cr, r, g, b, transparency_active)
    cairo_set_line_width(cr, 2)
    -- Arrow up
    cairo_move_to(cr, x - size * 0.3, y + size * 0.6)
    cairo_line_to(cr, x - size * 0.3, y + size * 0.2)
    cairo_line_to(cr, x - size * 0.45, y + size * 0.35)
    cairo_move_to(cr, x - size * 0.3, y + size * 0.2)
    cairo_line_to(cr, x - size * 0.15, y + size * 0.35)
    cairo_stroke(cr)
    -- Arrow down
    cairo_move_to(cr, x + size * 0.3, y + size * 0.2)
    cairo_line_to(cr, x + size * 0.3, y + size * 0.6)
    cairo_line_to(cr, x + size * 0.15, y + size * 0.45)
    cairo_move_to(cr, x + size * 0.3, y + size * 0.6)
    cairo_line_to(cr, x + size * 0.45, y + size * 0.45)
    cairo_stroke(cr)
end

function draw_icon_processes(cr, x, y, size)
    cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE)
    cairo_set_source_rgba(cr, r, g, b, transparency_active)
    cairo_set_line_width(cr, 1.5)
    -- Gear
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
    -- Center circle
    cairo_arc(cr, x, y, size * 0.15, 0, 2 * math.pi)
    cairo_stroke(cr)
end

function draw_icon_docker(cr, x, y, size)
    cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE)
    cairo_set_source_rgba(cr, r, g, b, transparency_active)
    cairo_set_line_width(cr, 1.5)
    -- Whale body
    cairo_move_to(cr, x - size * 0.4, y + size * 0.2)
    cairo_line_to(cr, x + size * 0.4, y + size * 0.2)
    cairo_line_to(cr, x + size * 0.45, y + size * 0.35)
    cairo_line_to(cr, x - size * 0.35, y + size * 0.35)
    cairo_close_path(cr)
    cairo_stroke(cr)
    -- Containers on top
    for i = 0, 2 do
        local cx = x - size * 0.25 + i * size * 0.2
        cairo_rectangle(cr, cx, y, size * 0.15, size * 0.15)
        cairo_stroke(cr)
    end
    -- Water line
    cairo_move_to(cr, x - size * 0.4, y + size * 0.45)
    for i = 0, 8 do
        local wx = x - size * 0.4 + i * size * 0.1
        local wy = y + size * 0.45 + ((i % 2 == 0) and 0 or size * 0.05)
        cairo_line_to(cr, wx, wy)
    end
    cairo_stroke(cr)
end

function draw_icon_k8s(cr, x, y, size)
    cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE)
    cairo_set_source_rgba(cr, r, g, b, transparency_active)
    cairo_set_line_width(cr, 1.5)
    -- Helm wheel
    local radius = size * 0.35
    local spokes = 7
    -- Outer circle
    cairo_arc(cr, x, y, radius, 0, 2 * math.pi)
    cairo_stroke(cr)
    -- Inner circle
    cairo_arc(cr, x, y, radius * 0.3, 0, 2 * math.pi)
    cairo_stroke(cr)
    -- Spokes
    for i = 0, spokes - 1 do
        local angle = (i / spokes) * 2 * math.pi
        cairo_move_to(cr, x + radius * 0.3 * math.cos(angle), y + radius * 0.3 * math.sin(angle))
        cairo_line_to(cr, x + radius * math.cos(angle), y + radius * math.sin(angle))
        cairo_stroke(cr)
    end
    -- Handle at top
    cairo_move_to(cr, x, y - radius)
    cairo_line_to(cr, x, y - radius - size * 0.15)
    cairo_stroke(cr)
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

function draw_network_info(cr, x, y)
    local w, h = 220, 160

    -- Background square
    draw_square(cr, x, y, w, h, transparency_bg)

    -- Icon and Title
    draw_icon_network(cr, x + 15, y + 15, 20)
    draw_text(cr, x + 35, y + 20, "NETWORK", 12, transparency_value)

    -- Interface
    local iface = conky_parse('${if_existing /sys/class/net/wlp2s0}wlp2s0${else}enp1s0f0${endif}')
    draw_text(cr, x + 10, y + 45, "Interface", 12, transparency_text)
    draw_text(cr, x + 10, y + 60, iface, 12, transparency_value)

    -- Local IP
    local local_ip = conky_parse('${addr wlp2s0}')
    if local_ip == "" then
        local_ip = conky_parse('${addr enp1s0f0}')
    end
    draw_text(cr, x + 10, y + 80, "Local IP", 12, transparency_text)
    draw_text(cr, x + 10, y + 95, local_ip, 12, transparency_value)

    -- External IP
    local ext_ip = conky_parse('${exec curl -s --max-time 3 ifconfig.me 2>/dev/null || echo "N/A"}')
    draw_text(cr, x + 10, y + 115, "External IP", 12, transparency_text)
    draw_text(cr, x + 10, y + 130, ext_ip, 12, transparency_value)
end

function draw_network_bandwidth(cr, x, y)
    local w, h = 220, 120

    -- Background square
    draw_square(cr, x, y, w, h, transparency_bg)

    -- Icon and Title
    draw_icon_bandwidth(cr, x + 15, y + 15, 20)
    draw_text(cr, x + 35, y + 20, "BANDWIDTH", 12, transparency_value)

    -- Download
    local down = conky_parse('${downspeed wlp2s0}')
    if down == "0B/s" then
        down = conky_parse('${downspeed enp1s0f0}')
    end
    draw_text(cr, x + 10, y + 45, "Download", 12, transparency_text)
    draw_text(cr, x + 10, y + 60, down, 14, transparency_value)

    -- Upload
    local up = conky_parse('${upspeed wlp2s0}')
    if up == "0B/s" then
        up = conky_parse('${upspeed enp1s0f0}')
    end
    draw_text(cr, x + 10, y + 80, "Upload", 12, transparency_text)
    draw_text(cr, x + 10, y + 95, up, 14, transparency_value)
end

function draw_top_processes(cr, x, y)
    local w, h = 250, 220

    -- Background square
    draw_square(cr, x, y, w, h, transparency_bg)

    -- Icon and Title
    draw_icon_processes(cr, x + 15, y + 15, 20)
    draw_text(cr, x + 35, y + 20, "TOP PROCESSES", 12, transparency_value)

    -- Process list
    local proc_y = y + 45

    for i = 1, 10 do
        local name = conky_parse('${top name ' .. i .. '}')
        local cpu = conky_parse('${top cpu ' .. i .. '}')

        if name and name ~= "" then
            -- Truncate long names
            if string.len(name) > 14 then
                name = string.sub(name, 1, 12) .. ".."
            end
            draw_text(cr, x + 10, proc_y, name, 12, transparency_text)
            draw_text(cr, x + w - 50, proc_y, cpu .. "%", 12, transparency_value)
            proc_y = proc_y + 17
        end
    end
end

function draw_docker_containers(cr, x, y)
    local w, h = 250, 180

    -- Background square
    draw_square(cr, x, y, w, h, transparency_bg)

    -- Icon and Title
    draw_icon_docker(cr, x + 15, y + 15, 20)
    draw_text(cr, x + 35, y + 20, "DOCKER", 12, transparency_value)

    -- Container list
    local containers = conky_parse('${exec docker ps --format "{{.Names}}" 2>/dev/null || echo ""}')
    local cont_y = y + 45
    local count = 0

    if containers and containers ~= "" then
        for line in containers:gmatch("[^\n]+") do
            local name = line:match("^%s*(.-)%s*$")
            if name and name ~= "" and count < 8 then
                -- Truncate long names
                if string.len(name) > 18 then
                    name = string.sub(name, 1, 16) .. ".."
                end

                -- Status dot (green for running)
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

function draw_k8s_context(cr, x, y)
    local w, h = 250, 140

    -- Background square
    draw_square(cr, x, y, w, h, transparency_bg)

    -- Icon and Title
    draw_icon_k8s(cr, x + 15, y + 15, 20)
    draw_text(cr, x + 35, y + 20, "K8S", 12, transparency_value)

    -- Current context
    local context = conky_parse('${exec kubectl config current-context 2>/dev/null || echo "N/A"}')
    draw_text(cr, x + 10, y + 45, "Context", 12, transparency_text)
    draw_text(cr, x + 10, y + 60, context, 14, transparency_value)

    -- Namespace
    local namespace = conky_parse('${exec kubectl config view --minify --output "jsonpath={..namespace}" 2>/dev/null || echo "default"}')
    draw_text(cr, x + 10, y + 80, "Namespace", 12, transparency_text)
    draw_text(cr, x + 10, y + 95, namespace, 12, transparency_value)

    -- Nodes
    local nodes = conky_parse('${exec kubectl get nodes --no-headers 2>/dev/null | wc -l || echo "0"}')
    draw_text(cr, x + 10, y + 115, "Nodes: " .. nodes, 12, transparency_value)
end

function draw_function(cr)
    local w, h = conky_window.width, conky_window.height
    cairo_select_font_face(cr, "Dejavu Sans Book", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)

    -- Left side (centered vertically)
    local left_x = 30
    local total_left_height = 120 + 160 -- bandwidth + network info
    local left_y_start = (h - total_left_height) / 2

    draw_network_bandwidth(cr, left_x, left_y_start)
    draw_network_info(cr, left_x, left_y_start + 140)

    -- Right side (centered vertically)
    local right_x = w - 280
    local total_right_height = 220 + 180 + 140 -- processes + docker + k8s
    local right_y_start = (h - total_right_height) / 2

    draw_top_processes(cr, right_x, right_y_start)
    draw_docker_containers(cr, right_x, right_y_start + 240)
    draw_k8s_context(cr, right_x, right_y_start + 440)
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

---
name: create-conky-widget
description: Create conky widgets matching the system-widgets theme style - white, semi-transparent squares with borders, icon+title pattern, using Cairo drawing in Lua
---

# create-conky-widget

Create conky widgets matching the system-widgets theme style for the conky-manager repo.

## Style Reference

Based on `themes/system-widgets/widgets.lua`:

### Colors & Transparency
```lua
HTML_color = "#FFFFFF"
HTML_color_border = "#FFFFFF"
transparency_bg = 0.6
transparency_border = 0.1
transparency_text = 0.6
transparency_value = 0.9
mode = 1          -- 1 = background, 2 = no background
border_size = 4
```

### Operators (CRITICAL - must use these exactly)
```lua
operator = {CAIRO_OPERATOR_SOURCE, CAIRO_OPERATOR_CLEAR}
operator_transpose = {CAIRO_OPERATOR_CLEAR, CAIRO_OPERATOR_SOURCE}
```
- `operator[mode]` for drawing backgrounds and fills
- `operator_transpose[mode]` for drawing text

### Font
- `Dejavu Sans Book` with `CAIRO_FONT_SLANT_NORMAL`
- Font sizes: 12 for labels, 14 for values

## Widget Structure

Each widget follows this pattern:

```lua
function draw_<widget_name>(cr, x, y)
    local w, h = <width>, <height>

    -- 1. Background square
    draw_square(cr, x, y, w, h, transparency_bg)

    -- 2. Icon + Title
    draw_icon_<widget_name>(cr, x + 15, y + 15, 20)
    draw_text(cr, x + 35, y + 20, "TITLE", 12, transparency_value)

    -- 3. Data rows (label on left, value on right)
    local cy = y + 45
    draw_text(cr, x + 10, cy, "Label", 12, transparency_text)
    draw_text(cr, x + 10, cy + 15, value, 12, transparency_value)
end
```

## Core Drawing Functions

### draw_square (background box)
```lua
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
```

### draw_text
```lua
function draw_text(cr, x, y, text, font_size, trans)
    cairo_set_operator(cr, operator_transpose[mode])
    cairo_set_source_rgba(cr, r, g, b, trans)
    cairo_set_font_size(cr, font_size)
    cairo_move_to(cr, x, y)
    cairo_show_text(cr, text)
end
```

### Icon Pattern
```lua
function draw_icon_<name>(cr, x, y, size)
    cairo_set_operator(cr, operator_transpose[mode])  -- CRITICAL: use transpose for dark icons
    cairo_set_source_rgba(cr, r, g, b, transparency_value)
    cairo_set_line_width(cr, 1.5)
    -- Draw icon shape here (arcs, lines, filled shapes, etc.)
    -- For filled shapes: use cairo_fill(cr)
    -- For outlines: use cairo_stroke(cr)
end
```

**IMPORTANT**: Icons MUST use `operator_transpose[mode]` (not `operator[mode]`) to appear dark on the semi-transparent background. Using `operator[mode]` draws white which is invisible.

## Widget Sizes
- Width: 220-250px
- Height: varies (120-220px depending on content)
- Title at y+20, content starts at y+45

## Layout in conkyrc
```lua
conky.config = {
    minimum_width = 1920, minimum_height = 1080,
    alignment = 'top_left',
    gap_x = 0, gap_y = 50,
    -- ... standard settings
    lua_load = '~/.config/conky/<theme>/widgets.lua',
    lua_draw_hook_pre = 'start_widgets',
}
```

## Positioning (in draw_function)
```lua
function draw_function(cr)
    local w, h = conky_window.width, conky_window.height
    cairo_select_font_face(cr, "Dejavu Sans Book", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)

    -- Left side widgets
    local left_x = 30
    local left_y = 720  -- below existing widgets
    draw_<widget>(cr, left_x, left_y)

    -- Right side widgets
    local right_x = w - 280
    local right_y = 720
    draw_<widget>(cr, right_x, right_y)
end
```

## Entry Point
```lua
function conky_start_widgets()
    if conky_window == nil then return end
    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable,
        conky_window.visual, conky_window.width, conky_window.height)
    local cr = cairo_create(cs)

    local updates = conky_parse('${updates}')
    if tonumber(updates) > 5 then
        draw_function(cr)
    end
    cairo_surface_destroy(cs)
    cairo_destroy(cr)
end
```

## Data Fetching
Use `conky_parse("${exec ...}")` for external data:
```lua
local val = conky_parse("${exec python3 /path/to/script --flag 2>/dev/null}")
```

## Existing Widgets (for reference)
- `themes/system-widgets/widgets.lua` - network, bandwidth, processes, docker, k8s
- `themes/crypto-tracker/settings.lua` - crypto price with chart

## Steps to Create a New Widget

1. Create `themes/<name>/` directory
2. Create `widgets.lua` following the style above
3. Create `conkyrc` with full-screen canvas (1920x1080)
4. Create `conkyrc` symlink: `ln -sf conkyrc_actual conkyrc`
5. Position widget in `draw_function()` to not overlap existing widgets
6. Test: `conky -c ~/.config/conky/<name>/conkyrc`
7. Copy to system: `cp -r themes/<name> ~/.config/conky/`
8. Commit to repo

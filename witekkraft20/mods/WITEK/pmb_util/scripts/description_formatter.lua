
local colors = {}
colors["grey"] = "#eeeeee" -- grey
colors["green"] = "#44ff99" -- green
colors["blue"] = "#66aaff" -- blue
colors["yellow"] = "#ffff99" -- yellow
colors["red"] = "#ff4422" -- red
colors["purple"] = "#ff4499" -- purple
colors["deep blue"] = "#2200ff" -- deep blue

-- returns a formatted colored description string
function pmb_util.desc(desc, color)
    color = colors[color]
    return minetest.colorize(color or "grey", desc)
end

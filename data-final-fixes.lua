-- tf-fertilizer is provided by other mods. the mk1 field keeps it in its fuel slots,
-- so give it a fuel value in a treefarm-only fuel category if it doesn't burn already
local fertilizer = data.raw.item["tf-fertilizer"]
if fertilizer and not fertilizer.fuel_value then
  fertilizer.fuel_category = "tf-fertilizer"
  fertilizer.fuel_value = "1J"
end

///|
/// Returns the font atlas owned by the current ImGui IO (`io.Fonts`).
#borrow(io)
pub extern "C" fn io_get_fonts(io : ImGuiIO) -> ImFontAtlas = "im_io_get_fonts"

///|
/// Sets the default font used by ImGui for all text (`io.FontDefault`).
#borrow(io)
pub extern "C" fn io_set_font_default(io : ImGuiIO, font : ImFont) -> Unit = "im_io_set_font_default"

///|
/// Number of fonts currently loaded in the atlas.
#borrow(atlas)
pub extern "C" fn font_atlas_get_font_count(atlas : ImFontAtlas) -> Int = "im_font_atlas_get_font_count"

///|
/// Returns the font at the given atlas index (0-based).
#borrow(atlas)
pub extern "C" fn font_atlas_get_font(atlas : ImFontAtlas, index : Int) -> ImFont = "im_font_atlas_get_font"

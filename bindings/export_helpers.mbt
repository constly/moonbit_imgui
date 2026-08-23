///|
/// Hand-written extern declarations matching export_helpers.cpp.
/// NEW HELPERS GO HERE: add the extern here (and the C function in
/// export_helpers.cpp); moon.pkg does not need to change.

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

///|
/// Sets the position of the window to be opened next (ImGui_SetNextWindowPos).
/// `cond` is an ImGuiCond bitmask (1 = Always, 2 = Once, 4 = FirstUseEver).
pub extern "C" fn ui_set_next_window_pos(x : Float, y : Float, cond : Int) -> Unit = "im_ui_set_next_window_pos"

///|
/// Sets the size of the window to be opened next (ImGui_SetNextWindowSize).
/// `cond` is an ImGuiCond bitmask (1 = Always, 2 = Once, 4 = FirstUseEver).
pub extern "C" fn ui_set_next_window_size(w : Float, h : Float, cond : Int) -> Unit = "im_ui_set_next_window_size"

///|
/// Returns the current ImGui display size (io.DisplaySize) in pixels.
#borrow(io, out_w, out_h)
pub extern "C" fn io_get_display_size(io : ImGuiIO, out_w : Ref[Float], out_h : Ref[Float]) -> Unit = "im_io_get_display_size"

///|
/// Begins a child window with the given size (negative = fill remaining).
/// Returns false when the child is not visible.
#borrow(id)
pub extern "C" fn ui_begin_child(
  id : Bytes,
  w : Float,
  h : Float,
  child_flags : Int,
  window_flags : Int,
) -> Bool = "im_ui_begin_child"

///|
/// Ends the current child window.
pub extern "C" fn ui_end_child() -> Unit = "im_ui_end_child"

///|
/// An invisible button spanning the given size (negative = fill remaining).
/// Used for drag handles / splitters.
#borrow(id)
pub extern "C" fn ui_invisible_button(id : Bytes, w : Float, h : Float, flags : Int) -> Bool = "im_ui_invisible_button"

///|
/// Returns how far the mouse has been dragged while the given button is held.
#borrow(out_x, out_y)
pub extern "C" fn ui_get_mouse_drag_delta(
  button : Int,
  lock_threshold : Float,
  out_x : Ref[Float],
  out_y : Ref[Float],
) -> Unit = "im_ui_get_mouse_drag_delta"

///|
/// Returns the available content region size (ImGui_GetContentRegionAvail).
#borrow(out_w, out_h)
pub extern "C" fn ui_get_content_region_avail(out_w : Ref[Float], out_h : Ref[Float]) -> Unit = "im_ui_get_content_region_avail"

///|
/// Pushes the window padding style var to (x, y). Required before a window
/// when you want zero padding (para that children fill the window edge to
/// edge). Must be paired with a `ui_pop_style_var(1)` after the window.
pub extern "C" fn ui_push_window_padding_xy(x : Float, y : Float) -> Unit = "im_ui_push_window_padding_xy"

///|
/// Pops `count` style vars pushed by the current window.
pub extern "C" fn ui_pop_style_var(count : Int) -> Unit = "im_ui_pop_style_var"

///|
/// Sets the cursor position relative to the current window's content region.
pub extern "C" fn ui_set_cursor_pos(x : Float, y : Float) -> Unit = "im_ui_set_cursor_pos"

///|
/// A draggable splitter between two panes. `size1`/`size2` are the current
/// widths (in/out); dragging updates them while honoring the minimum sizes.
/// `split_vertically` selects a horizontal splitter (left/right panes).
/// Returns true while the user is dragging it.
#borrow(id, size1, size2)
pub extern "C" fn ui_splitter(
  id : Bytes,
  split_vertically : Bool,
  thickness : Float,
  size1 : Ref[Float],
  size2 : Ref[Float],
  min_size1 : Float,
  min_size2 : Float,
  splitter_long_axis_size : Float,
) -> Bool = "im_ui_splitter"

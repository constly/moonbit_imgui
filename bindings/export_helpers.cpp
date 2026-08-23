/* Hand-written C helpers for MoonBit externs that dear_bindings does not
   generate wrappers for (struct fields, or functions taking ImVec2 which
   MoonBit cannot construct directly).
   Compiled as C++ but must keep C linkage so the MoonBit externs resolve.
   NEW HELPERS GO HERE: add the function to this file (and to
   export_helpers.mbt); there is no need to touch moon.pkg again. */
#define IMGUI_DEFINE_MATH_OPERATORS
#include "imgui.h"
#include "imgui_internal.h"

extern "C" {

// --- ImGuiIO / font fields ---------------------------------------------------

ImFontAtlas* im_io_get_fonts(ImGuiIO* io) {
  return io->Fonts;
}

void im_io_set_font_default(ImGuiIO* io, ImFont* font) {
  io->FontDefault = font;
}

int im_font_atlas_get_font_count(ImFontAtlas* atlas) {
  return atlas->Fonts.Size;
}

ImFont* im_font_atlas_get_font(ImFontAtlas* atlas, int index) {
  return atlas->Fonts[index];
}

// --- window layout (ImVec2 cannot be constructed from MoonBit) ----------------

void im_ui_set_next_window_pos(float x, float y, int cond) {
  ::ImGui::SetNextWindowPos(ImVec2(x, y), (ImGuiCond)cond);
}

void im_ui_set_next_window_size(float w, float h, int cond) {
  ::ImGui::SetNextWindowSize(ImVec2(w, h), (ImGuiCond)cond);
}

void im_io_get_display_size(ImGuiIO* io, float* out_w, float* out_h) {
  *out_w = io->DisplaySize.x;
  *out_h = io->DisplaySize.y;
}

bool im_ui_begin_child(const char* id, float w, float h, int child_flags,
                       int window_flags) {
  // Negative sizes mean "fill the remaining available space" (ImGui default).
  return ::ImGui::BeginChild(id, ImVec2(w, h), (ImGuiChildFlags)child_flags,
                             (ImGuiWindowFlags)window_flags);
}

void im_ui_end_child() {
  ::ImGui::EndChild();
}

bool im_ui_invisible_button(const char* id, float w, float h, int flags) {
  return ::ImGui::InvisibleButton(id, ImVec2(w, h), (ImGuiButtonFlags)flags);
}

void im_ui_get_mouse_drag_delta(int button, float lock_threshold,
                                float* out_x, float* out_y) {
  ImVec2 delta = ::ImGui::GetMouseDragDelta((ImGuiMouseButton)button,
                                            lock_threshold);
  *out_x = delta.x;
  *out_y = delta.y;
}

// --- splitters (based on the Dear ImGui demo's SplitterBehavior usage) --------

// Returns the window content region available size (ImGui_GetContentRegionAvail).
void im_ui_get_content_region_avail(float* out_w, float* out_h) {
  ImVec2 avail = ::ImGui::GetContentRegionAvail();
  *out_w = avail.x;
  *out_h = avail.y;
}

// Push/pop the window padding style var (ImVec2, so cannot go through the
// float push_style_var). Used to remove the default 8px window padding so the
// child panes fill the whole window edge to edge.
void im_ui_push_window_padding_xy(float x, float y) {
  ::ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(x, y));
}

void im_ui_pop_style_var(int count) {
  ::ImGui::PopStyleVar(count);
}

// Sets the cursor position (relative to the current window's content region)
// in one call. `ImGui::SetCursorPos` takes an ImVec2, which MoonBit cannot
// construct, so this thin helper exposes the x/y pair directly.
void im_ui_set_cursor_pos(float x, float y) {
  ::ImGui::SetCursorPos(ImVec2(x, y));
}

// A draggable splitter between two panes. `size1`/`size2` are the current
// widths (in/out); dragging updates them while honoring the minimum sizes.
// `split_vertically` selects a horizontal splitter (left/right panes).
// Returns true while the user is dragging it.
bool im_ui_splitter(const char* id, bool split_vertically, float thickness,
                    float* size1, float* size2, float min_size1,
                    float min_size2, float splitter_long_axis_size) {
  ImGuiContext& g = *::ImGui::GetCurrentContext();
  ImGuiWindow* window = g.CurrentWindow;
  ImGuiID splitter_id = window->GetID(id);
  ImRect bb;
  bb.Min = window->DC.CursorPos +
           (split_vertically ? ImVec2(*size1, 0.0f) : ImVec2(0.0f, *size1));
  bb.Max = bb.Min +
           ::ImGui::CalcItemSize(
               split_vertically ? ImVec2(thickness, splitter_long_axis_size)
                                : ImVec2(splitter_long_axis_size, thickness),
               0.0f, 0.0f);
  return ::ImGui::SplitterBehavior(bb, splitter_id,
                                   split_vertically ? ImGuiAxis_X
                                                    : ImGuiAxis_Y,
                                   size1, size2, min_size1, min_size2, 0.0f);
}

} // extern "C"

/* Small helpers exposing ImGuiIO font fields that dear_bindings does not
   generate wrappers for (they are struct fields, not functions).
   Compiled as C++ but must keep C linkage so the MoonBit externs
   ("im_io_get_fonts" / "im_io_set_font_default") resolve. */
#include "imgui.h"

extern "C" {

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

} // extern "C"

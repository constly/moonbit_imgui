///|
/// Window state persisted in an INI file under the `[window]` section.
/// Other sections/keys in the same file are preserved (read-modify-write),
/// so the file can be shared with other settings.
pub struct WindowState {
  x : Int
  y : Int
  width : Int
  height : Int
  maximized : Bool
}

///|
let window_section : String = "window"

///|
/// Load window state from an INI file. Missing or invalid entries fall back
/// to the provided defaults.
pub fn load_window_state(
  state_file : String,
  default_x : Int,
  default_y : Int,
  default_width : Int,
  default_height : Int,
) -> WindowState {
  let ini = read_ini(state_file)
  let maximized = match ini.get_bool(section=window_section, "maximized") {
    Some(value) => value
    None => false
  }
  {
    x: parse_int_or(ini.get(section=window_section, "x"), default_x),
    y: parse_int_or(ini.get(section=window_section, "y"), default_y),
    width: parse_int_or(ini.get(section=window_section, "width"), default_width),
    height: parse_int_or(
      ini.get(section=window_section, "height"),
      default_height,
    ),
    maximized,
  }
}

///|
/// Save window state into an INI file, updating only the `[window]` section
/// and preserving all other sections/keys. Returns false on failure.
pub fn save_window_state(state_file : String, state : WindowState) -> Bool {
  let ini = read_ini(state_file)
  ini.set(section=window_section, "x", state.x.to_string())
  ini.set(section=window_section, "y", state.y.to_string())
  ini.set(section=window_section, "width", state.width.to_string())
  ini.set(section=window_section, "height", state.height.to_string())
  ini.set(
    section=window_section,
    "maximized",
    if state.maximized {
      "true"
    } else {
      "false"
    },
  )
  write_text_file(state_file, ini.to_string())
}

///|
/// True if the rectangle (x, y, width, height) intersects the primary
/// monitor's work area (i.e. the window would not be unreachable off-screen).
pub fn window_visible_on_screen(
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> Bool {
  let monitor = @glfw.get_primary_monitor()
  if monitor.is_null() {
    return true
  }
  let wx = Ref(0)
  let wy = Ref(0)
  let ww = Ref(0)
  let wh = Ref(0)
  @glfw.get_monitor_workarea(monitor, wx, wy, ww, wh)
  let area_x = wx.val
  let area_y = wy.val
  let area_w = ww.val
  let area_h = wh.val
  x + width > area_x &&
  x < area_x + area_w &&
  y + height > area_y &&
  y < area_y + area_h
}

///|
/// Read the INI file into an IniFile. Corrupt/missing files yield an empty
/// IniFile instead of raising.
fn read_ini(state_file : String) -> @ini.IniFile {
  match read_text_file(state_file) {
    Some(content) => @ini.parse(content) catch { _ => @ini.IniFile::new() }
    None => @ini.IniFile::new()
  }
}

///|
fn parse_int_or(value : String?, default : Int) -> Int {
  match value {
    Some(v) => @string.parse_int(v) catch { _ => default }
    None => default
  }
}

///|
/// Read a whole text file as UTF-8, or None if it cannot be opened.
pub fn read_text_file(path : String) -> String? {
  Some(@fs.read_file_to_string(path)) catch {
    _ => None
  }
}

///|
/// Overwrite a text file with UTF-8 content. Returns false on failure.
pub fn write_text_file(path : String, content : String) -> Bool {
  try {
    @fs.write_string_to_file(path, content)
    true
  } catch {
    _ => false
  }
}

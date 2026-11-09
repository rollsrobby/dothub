// Compile the real patched update method against minimal rendering stand-ins.
#include <cassert>
#include <iostream>
#include <string>

namespace fmt {
std::string runtime(std::string s) { return s; }
template<class T> T arg(const char*, T value) { return value; }
template<class... Args>
std::string format(std::string, unsigned count, Args...) {
  return std::to_string(count);
}
}

struct Style {
  bool has_class(std::string) { return false; }
  void remove_class(std::string) {}
  void add_class(std::string) {}
};
struct Label {
  Style style;
  std::string text;
  Style* get_style_context() { return &style; }
  void set_markup(std::string s) { text = s; }
};
struct Box {
  bool visible = true;
  void set_visible(bool v) { visible = v; }
};
struct ALabel { void update() {} };

namespace waybar::modules {
struct SystemdFailedUnits : ALabel {
  std::string last_status, overall_state, format_ok, format_, system_state, user_state;
  unsigned nr_failed = 0, nr_failed_system = 0, nr_failed_user = 0;
  bool hide_on_ok = true;
  Box event_box_;
  Label label_;
  void update();
};

// Generated from Waybar's patched source, including the closing namespace.
#include "systemd-update.inc"

int main() {
  waybar::modules::SystemdFailedUnits m;
  m.overall_state = "degraded";
  m.nr_failed = 1;
  m.update();

  // Counts must refresh even while the overall state remains degraded.
  m.nr_failed = 2;
  m.update();
  if (m.label_.text != "2") {
    std::cerr << "FAIL: failed-unit count stays at first value\n";
    return 1;
  }

  // A new failure must restore the icon after a healthy state hid it.
  m.overall_state = "ok";
  m.update();
  assert(!m.event_box_.visible);
  m.overall_state = "degraded";
  m.update();
  assert(m.event_box_.visible);
  std::cout << "PASS: count refresh and failed/healthy/failed visibility\n";
}

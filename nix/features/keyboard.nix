{
  flake.nixosModules.keyboard = {
    # Match the model and main keyboard interface, not its serial or USB port.
    # A single alias intentionally supports one Unicorne connected at a time.
    services.udev.extraRules = ''
      SUBSYSTEM=="input", KERNEL=="event*", ENV{ID_INPUT_KEYBOARD}=="1", ENV{ID_VENDOR_ID}=="4273", ENV{ID_MODEL_ID}=="7563", ENV{ID_USB_INTERFACE_NUM}=="00", SYMLINK+="input/boardsource-unicorne"
    '';

    services.kanata = {
      enable = true;
      keyboards.default = {
        devices = [
          "/dev/input/by-path/platform-i8042-serio-0-event-kbd"
          "/dev/input/boardsource-unicorne"
        ];
        extraDefCfg = "process-unmapped-keys yes";
        config = ''
          (defsrc
            caps
            lctl rctl lalt ralt lmet rmet lsft rsft
            q w e r t y u i o p)

          (defalias
            mw1 (switch
              ((and (input real lalt) (not (input real ralt) (input real lctl) (input real rctl) (input real lmet) (input real rmet)))) (unmod (lalt) ralt q) break
              ((and (or (input real lsft) (input real rsft)) (or (input real lctl) (input real rctl)) (or (input real lalt) (input real ralt)) (or (input real lmet) (input real rmet)))) (unmod lsft lmet 1) break
              ((and (or (input real lctl) (input real rctl)) (or (input real lalt) (input real ralt)) (or (input real lmet) (input real rmet)))) (unmod lmet 1) break
              () q break)
            mw2 (switch
              ((and (or (input real lsft) (input real rsft)) (or (input real lctl) (input real rctl)) (or (input real lalt) (input real ralt)) (or (input real lmet) (input real rmet)))) (unmod lsft lmet 2) break
              ((and (or (input real lctl) (input real rctl)) (or (input real lalt) (input real ralt)) (or (input real lmet) (input real rmet)))) (unmod lmet 2) break
              () w break)
            mw3 (switch
              ((and (or (input real lsft) (input real rsft)) (or (input real lctl) (input real rctl)) (or (input real lalt) (input real ralt)) (or (input real lmet) (input real rmet)))) (unmod lsft lmet 3) break
              ((and (or (input real lctl) (input real rctl)) (or (input real lalt) (input real ralt)) (or (input real lmet) (input real rmet)))) (unmod lmet 3) break
              () e break)
            mw4 (switch
              ((and (or (input real lsft) (input real rsft)) (or (input real lctl) (input real rctl)) (or (input real lalt) (input real ralt)) (or (input real lmet) (input real rmet)))) (unmod lsft lmet 4) break
              ((and (or (input real lctl) (input real rctl)) (or (input real lalt) (input real ralt)) (or (input real lmet) (input real rmet)))) (unmod lmet 4) break
              () r break)
            mw5 (switch
              ((and (or (input real lsft) (input real rsft)) (or (input real lctl) (input real rctl)) (or (input real lalt) (input real ralt)) (or (input real lmet) (input real rmet)))) (unmod lsft lmet 5) break
              ((and (or (input real lctl) (input real rctl)) (or (input real lalt) (input real ralt)) (or (input real lmet) (input real rmet)))) (unmod lmet 5) break
              () t break)
            mw6 (switch
              ((and (input real lalt) (not (input real ralt) (input real lctl) (input real rctl) (input real lmet) (input real rmet)))) (unmod (lalt) ralt y) break
              ((and (or (input real lsft) (input real rsft)) (or (input real lctl) (input real rctl)) (or (input real lalt) (input real ralt)) (or (input real lmet) (input real rmet)))) (unmod lsft lmet 6) break
              ((and (or (input real lctl) (input real rctl)) (or (input real lalt) (input real ralt)) (or (input real lmet) (input real rmet)))) (unmod lmet 6) break
              () y break)
            mw7 (switch
              ((and (or (input real lsft) (input real rsft)) (or (input real lctl) (input real rctl)) (or (input real lalt) (input real ralt)) (or (input real lmet) (input real rmet)))) (unmod lsft lmet 7) break
              ((and (or (input real lctl) (input real rctl)) (or (input real lalt) (input real ralt)) (or (input real lmet) (input real rmet)))) (unmod lmet 7) break
              () u break)
            mw8 (switch
              ((and (or (input real lsft) (input real rsft)) (or (input real lctl) (input real rctl)) (or (input real lalt) (input real ralt)) (or (input real lmet) (input real rmet)))) (unmod lsft lmet 8) break
              ((and (or (input real lctl) (input real rctl)) (or (input real lalt) (input real ralt)) (or (input real lmet) (input real rmet)))) (unmod lmet 8) break
              () i break)
            mw9 (switch
              ((and (or (input real lsft) (input real rsft)) (or (input real lctl) (input real rctl)) (or (input real lalt) (input real ralt)) (or (input real lmet) (input real rmet)))) (unmod lsft lmet 9) break
              ((and (or (input real lctl) (input real rctl)) (or (input real lalt) (input real ralt)) (or (input real lmet) (input real rmet)))) (unmod lmet 9) break
              () o break)
            mw0 (switch
              ((and (input real lalt) (not (input real ralt) (input real lctl) (input real rctl) (input real lmet) (input real rmet)))) (unmod (lalt) ralt p) break
              ((and (or (input real lsft) (input real rsft)) (or (input real lctl) (input real rctl)) (or (input real lalt) (input real ralt)) (or (input real lmet) (input real rmet)))) (unmod lsft lmet 0) break
              ((and (or (input real lctl) (input real rctl)) (or (input real lalt) (input real ralt)) (or (input real lmet) (input real rmet)))) (unmod lmet 0) break
              () p break))

          (deflayermap (default-layer)
           ;; tap caps lock as esc, hold caps lock as left control
           ;; 0 = no quick-tap (like QMK QUICK_TAP_TERM 0)
           ;; 200 = hold timeout (like QMK TAPPING_TERM 200)
           ;; tap-hold-press = hold on other key press (like QMK HOLD_ON_OTHER_KEY_PRESS)
            caps (tap-hold-press 0 200 esc lctl)
            q @mw1
            w @mw2
            e @mw3
            r @mw4
            t @mw5
            y @mw6
            u @mw7
            i @mw8
            o @mw9
            p @mw0)
        '';
      };
    };
  };
}

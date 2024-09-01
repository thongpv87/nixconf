$env.config = {
  show_banner: false

  plugins: {
  }

  edit_mode: vi
  keybindings: [
      {
        name: unbind_ctrl_i
        modifier: control
        keycode: char_i
        mode: [ vi_normal, vi_insert]
        event: null
      }
    {
      name: open_editor
      modifier: control
      keycode: char_i
      mode: [ vi_normal, vi_insert]
      event: { send: openeditor }
    }

    {
      name: move_one_word_right_or_take_history_hint
      modifier: none
      keycode: char_w
      mode: [ vi_normal ]
      event: { 
        until: [
          { send: historyhintwordcomplete }
          { edit: movewordright select: false}
        ]
      }
    }
    {
      name: move_one_word_left_or_take_history_hint
      modifier: none
      keycode: char_b
      mode: [ vi_normal ]
      event: { edit: movewordleft }
    }
  ]
}

alias nix-shell = nix-shell --run nu
alias vi = nvim

def rlw [prog] {
  which $prog | readlink -f $in.0.path
}

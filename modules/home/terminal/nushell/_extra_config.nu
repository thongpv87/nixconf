$env.config = {
  plugins: {
  }

  edit_mode: vi
  keybindings: [
    {
      name: move_one_word_right_or_take_history_hint
      modifier: none
      keycode: char_w
      mode: [ vi_normal ]
      event: { edit: movewordright }
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

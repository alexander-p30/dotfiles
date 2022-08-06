require("neo-tree").setup({
  popup_border_style = "rounded",
  filesystem = {
    hijack_netrw_behavior = "open_current"
  },
  window = {
    mappings = {
      ["l"] = "open",
      ["h"] = "close_node",
      ["c"] = {
        "copy",
        config = {
          show_path = "relative"
        }
      },
      ["m"] = {
        "move",
        config = {
          show_path = "relative"
        }
      },
    }
  },
})


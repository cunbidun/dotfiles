inputs: final: prev: {
  vimPlugins =
    prev.vimPlugins
    // {
      auto-dark-mode-nvim = prev.vimUtils.buildVimPlugin {
        pname = "auto-dark-mode.nvim";
        src = inputs.auto-dark-mode-nvim;
        version = inputs.auto-dark-mode-nvim.shortRev;
      };
      copilot-lua = prev.vimUtils.buildVimPlugin {
        pname = "copilot-lua";
        src = inputs.copilot-lua;
        version = inputs.copilot-lua.shortRev;
      };
      blink-copilot = prev.vimUtils.buildVimPlugin {
        pname = "blink-copilot";
        src = inputs.blink-copilot;
        version = inputs.blink-copilot.shortRev;
      };
    };
}

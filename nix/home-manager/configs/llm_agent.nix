{
  config,
  pkgs,
  ...
}: let
  githubTokenPath = "${config.home.homeDirectory}/.config/opencode/github_read_only_token";
  chromeBinary = "${pkgs.google-chrome}/bin/google-chrome-stable";
  chromeDevToolsProfile = "${config.home.homeDirectory}/.cache/chrome-devtools-mcp/opencode-profile";
  codexChromeDevToolsProfile = "${config.home.homeDirectory}/.cache/chrome-devtools-mcp/codex-profile";
  npx = "${pkgs.nodejs_24}/bin/npx";
  lspPath = pkgs.lib.makeBinPath [
    pkgs.nixd
    pkgs.pyright
    pkgs.lua-language-server
    pkgs.typescript
    pkgs.typescript-language-server
    pkgs.vscode-langservers-extracted
    pkgs.yaml-language-server
    pkgs.dockerfile-language-server
  ];
  mcpPath = pkgs.lib.makeBinPath [
    pkgs.nodejs_24
    pkgs.bash
    pkgs.coreutils
  ];
  codexToml = pkgs.formats.toml {};
  codexConfigFile = codexToml.generate "codex-config.toml" {
    model = "gpt-5.5";
    model_reasoning_effort = "medium";
    personality = "pragmatic";

    features = {
      multi_agent = true;
      child_agents_md = true;
      apps = true;
    };

    shell_environment_policy = {
      "inherit" = "all";
      ignore_default_excludes = true;
      experimental_use_profile = true;
    };

    sandbox_workspace_write.network_access = true;

    mcp_servers."chrome-devtools" = {
      command = npx;
      args = [
        "-y"
        "chrome-devtools-mcp@latest"
        "--executable-path=${chromeBinary}"
        "--user-data-dir=${codexChromeDevToolsProfile}"
        "--no-usage-statistics"
        "--no-performance-crux"
      ];
      env.PATH = mcpPath;
      startup_timeout_sec = 20;
      tool_timeout_sec = 60;
      enabled = true;
    };

    plugins = {
      "gmail@openai-curated".enabled = true;
      "github@openai-curated".enabled = true;
    };

    tui.model_availability_nux."gpt-5.5" = 4;
  };
in {
  home.packages = with pkgs; [
    nixd
    pyright
    lua-language-server
    typescript
    typescript-language-server
    vscode-langservers-extracted
    yaml-language-server
    dockerfile-language-server
  ];

  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    lsp = {
      nixd = {
        command = ["${pkgs.nixd}/bin/nixd"];
        extensions = [".nix"];
      };
      pyright = {
        command = ["${pkgs.pyright}/bin/pyright-langserver" "--stdio"];
        extensions = [".py" ".pyi"];
      };
      lua-ls = {
        command = ["${pkgs.lua-language-server}/bin/lua-language-server"];
        extensions = [".lua"];
      };
      typescript = {
        command = ["${pkgs.typescript-language-server}/bin/typescript-language-server" "--stdio"];
        extensions = [".ts" ".tsx" ".js" ".jsx" ".mjs" ".cjs" ".mts" ".cts"];
        env.PATH = lspPath;
      };
      json = {
        command = ["${pkgs.vscode-langservers-extracted}/bin/vscode-json-language-server" "--stdio"];
        extensions = [".json" ".jsonc"];
      };
      yaml-ls = {
        command = ["${pkgs.yaml-language-server}/bin/yaml-language-server" "--stdio"];
        extensions = [".yaml" ".yml"];
      };
      css = {
        command = ["${pkgs.vscode-langservers-extracted}/bin/vscode-css-language-server" "--stdio"];
        extensions = [".css" ".scss" ".less"];
      };
      html = {
        command = ["${pkgs.vscode-langservers-extracted}/bin/vscode-html-language-server" "--stdio"];
        extensions = [".html" ".htm"];
      };
      docker = {
        command = ["${pkgs.dockerfile-language-server}/bin/docker-langserver" "--stdio"];
        extensions = ["Dockerfile" ".dockerfile"];
      };
    };
    mcp = {
      chrome-devtools = {
        type = "local";
        command = [
          npx
          "-y"
          "chrome-devtools-mcp@latest"
          "--executable-path=${chromeBinary}"
          "--user-data-dir=${chromeDevToolsProfile}"
          "--no-usage-statistics"
          "--no-performance-crux"
        ];
        environment.PATH = mcpPath;
        timeout = 20000;
        enabled = true;
      };

      github = {
        type = "remote";
        url = "https://api.githubcopilot.com/mcp/readonly";
        oauth = false;
        headers = {
          Authorization = "Bearer {file:${githubTokenPath}}";
          X-MCP-Toolsets = "context,repos,issues,pull_requests,users";
          X-MCP-Readonly = "true";
        };
        enabled = true;
      };
    };
  };
  home.file.".codex/config.toml" = {
    source = codexConfigFile;
    force = true;
  };
}

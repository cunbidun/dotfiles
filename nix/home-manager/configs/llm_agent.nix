{
  config,
  lib,
  pkgs,
  inputs,
  userdata,
  ...
}:
let
  configHome = config.xdg.configHome;
  cacheHome = config.xdg.cacheHome;
  githubTokenPath = "${configHome}/opencode/github_read_only_token";
  ninerouterTokenPath = "${configHome}/opencode/ninerouter_api_key";
  chromeBinary = "${pkgs.google-chrome}/bin/google-chrome-stable";
  chromeDevToolsProfile = "${cacheHome}/chrome-devtools-mcp/opencode-profile";
  codexChromeDevToolsProfile = "${cacheHome}/chrome-devtools-mcp/codex-profile";
  codexMarketplaceDir = "${config.home.homeDirectory}/.codex/marketplaces/ponytail";
  ponytailPluginCache = "${config.home.homeDirectory}/.codex/plugins/cache/ponytail/ponytail/4.8.3";
  npx = "${pkgs.nodejs}/bin/npx";
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
    pkgs.nodejs
    pkgs.bash
    pkgs.coreutils
  ];
  codexToml = pkgs.formats.toml { };
  codexConfigFile = codexToml.generate "codex-config.toml" {
    model_provider = "9router";
    model = "cx/gpt-5.5";
    model_reasoning_effort = "medium";
    personality = "pragmatic";

    model_providers."9router" = {
      name = "9router";
      base_url = "http://home-server.${userdata.tailnetDomain}:20128/v1";
      env_key = "NINEROUTER_API_KEY";
    };

    features = {
      multi_agent = true;
      apps = true;
    };

    shell_environment_policy = {
      "inherit" = "all";
      ignore_default_excludes = true;
      experimental_use_profile = true;
    };

    projects."${config.home.homeDirectory}".trust_level = "trusted";
    projects."${configHome}".trust_level = "trusted";

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
        "--headless"
      ];
      env.PATH = mcpPath;
      startup_timeout_sec = 20;
      tool_timeout_sec = 60;
      enabled = true;
    };

    mcp_servers."nixos" = {
      command = "${pkgs.uv}/bin/uvx";
      args = [ "mcp-nixos" ];
      enabled = true;
    };

    mcp_servers."github" = {
      url = "https://api.githubcopilot.com/mcp/readonly";
      bearer_token_env_var = "GITHUB_COPILOT_MCP_TOKEN";
      enabled = true;
    };

    marketplaces.ponytail = {
      source_type = "local";
      source = codexMarketplaceDir;
    };

    plugins = {
      "gmail@openai-curated".enabled = true;
      "github@openai-curated".enabled = true;
      "linear@openai-curated".enabled = true;
      "google-calendar@openai-curated".enabled = true;
      "google-drive@openai-curated".enabled = true;
      "slack@openai-curated".enabled = true;
      "ponytail@ponytail".enabled = true;
    };

    hooks.state = {
      "ponytail@ponytail:hooks/claude-codex-hooks.json:session_start:0:0".trusted_hash =
        "sha256:35ad4fd900da217d98e6eb60198465bd10d55e21eacd72758621dc385145cc05";
      "ponytail@ponytail:hooks/claude-codex-hooks.json:user_prompt_submit:0:0".trusted_hash =
        "sha256:22db2f951755c593f9deba5e69cd1be1c87e0c9b2f5538a13b5dd9911141793f";
      "ponytail@ponytail:hooks/claude-codex-hooks.json:subagent_start:0:0".trusted_hash =
        "sha256:28c43eada804ad00a4e651d6af6320c01e763b1df060af0ab74865a55bc1c9a9";
    };

    tui.model_availability_nux."cx/gpt-5.5" = 4;
  };
in
{
  home.packages = with pkgs; [
    nixd
    pyright
    lua-language-server
    typescript
    typescript-language-server
    vscode-langservers-extracted
    yaml-language-server
    dockerfile-language-server
    nodejs
    uv
  ];

  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    permission = "allow";
    plugin = [ "${inputs.obra-superpowers}/.opencode/plugins/superpowers.js" ];
    lsp = {
      nixd = {
        command = [ "${pkgs.nixd}/bin/nixd" ];
        extensions = [ ".nix" ];
      };
      pyright = {
        command = [
          "${pkgs.pyright}/bin/pyright-langserver"
          "--stdio"
        ];
        extensions = [
          ".py"
          ".pyi"
        ];
      };
      lua-ls = {
        command = [ "${pkgs.lua-language-server}/bin/lua-language-server" ];
        extensions = [ ".lua" ];
      };
      typescript = {
        command = [
          "${pkgs.typescript-language-server}/bin/typescript-language-server"
          "--stdio"
        ];
        extensions = [
          ".ts"
          ".tsx"
          ".js"
          ".jsx"
          ".mjs"
          ".cjs"
          ".mts"
          ".cts"
        ];
        env.PATH = lspPath;
      };
      json = {
        command = [
          "${pkgs.vscode-langservers-extracted}/bin/vscode-json-language-server"
          "--stdio"
        ];
        extensions = [
          ".json"
          ".jsonc"
        ];
      };
      yaml-ls = {
        command = [
          "${pkgs.yaml-language-server}/bin/yaml-language-server"
          "--stdio"
        ];
        extensions = [
          ".yaml"
          ".yml"
        ];
      };
      css = {
        command = [
          "${pkgs.vscode-langservers-extracted}/bin/vscode-css-language-server"
          "--stdio"
        ];
        extensions = [
          ".css"
          ".scss"
          ".less"
        ];
      };
      html = {
        command = [
          "${pkgs.vscode-langservers-extracted}/bin/vscode-html-language-server"
          "--stdio"
        ];
        extensions = [
          ".html"
          ".htm"
        ];
      };
      docker = {
        command = [
          "${pkgs.dockerfile-language-server}/bin/docker-langserver"
          "--stdio"
        ];
        extensions = [
          "Dockerfile"
          ".dockerfile"
        ];
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
          "--headless"
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

      nixos = {
        type = "local";
        command = [ "${pkgs.uv}/bin/uvx" "mcp-nixos" ];
        enabled = true;
      };
    };
  };

  programs.opencode = {
    enable = true;
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
    skills = "${inputs.obra-superpowers}/skills";
    tui = {
      theme = "system";
    };
  };

  home.sessionVariablesExtra = ''
    if [ -r "${ninerouterTokenPath}" ]; then
      export NINEROUTER_API_KEY="$(tr -d '\n' < "${ninerouterTokenPath}")"
    fi

    if [ -r "${githubTokenPath}" ]; then
      export GITHUB_COPILOT_MCP_TOKEN="$(tr -d '\n' < "${githubTokenPath}")"
    fi
  '';

  home.file.".codex/config.toml" = {
    source = codexConfigFile;
    force = true;
  };

  home.activation.installPonytailCodexPlugin = lib.hm.dag.entryAfter [ "installPackages" ] ''
    if [ -e "${codexMarketplaceDir}" ]; then
      run chmod -R u+w "${codexMarketplaceDir}"
    fi
    if [ -e "${ponytailPluginCache}" ]; then
      run chmod -R u+w "${ponytailPluginCache}"
    fi
    run rm -rf "${codexMarketplaceDir}"
    run rm -rf "${ponytailPluginCache}"
    run mkdir -p "$(dirname "${codexMarketplaceDir}")"
    run mkdir -p "${ponytailPluginCache}"
    run cp -R "${inputs.ponytail}" "${codexMarketplaceDir}"
    run cp -R "${inputs.ponytail}/." "${ponytailPluginCache}/"
    run chmod -R u+w "${codexMarketplaceDir}" "${ponytailPluginCache}"
  '';
}

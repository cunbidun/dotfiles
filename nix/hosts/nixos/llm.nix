{
  config,
  pkgs,
  ...
}: let
  openWebuiPort = 8000;

  qwen36 = {
    repo = "unsloth/Qwen3.6-27B-GGUF";
    file = "Qwen3.6-27B-UD-IQ2_XXS.gguf";
    alias = "qwen3.6-27b-iq2";
  };

  qwen36Gguf = pkgs.fetchurl {
    url = "https://huggingface.co/${qwen36.repo}/resolve/main/${qwen36.file}";
    hash = "sha256-lov8cSgyAxr+vsM52jrmHGgiq5oRjh1ytr4qd4GpbjA=";
  };

  qwen36OllamaModelfile = pkgs.writeText "qwen3.6-27b-iq2.Modelfile" ''
    FROM ${qwen36Gguf}

    TEMPLATE """{{- if .Messages }}
    {{- if or .System .Tools }}<|im_start|>system
    Reasoning is enabled. Think before answering when useful, and expose reasoning in the model's normal thinking channel.
    {{- if .System }}
    {{ .System }}
    {{- end }}
    {{- if .Tools }}
    # Tools

    You may call one or more functions to assist with the user query.

    You are provided with function signatures within <tools></tools> XML tags:
    <tools>
    {{- range .Tools }}
    {"type": "function", "function": {{ .Function }}}
    {{- end }}
    </tools>

    For each function call, return a json object with function name and arguments within <tool_call></tool_call> XML tags:
    <tool_call>
    {"name": <function-name>, "arguments": <args-json-object>}
    </tool_call>
    {{- end }}<|im_end|>
    {{ end }}
    {{- range $i, $_ := .Messages }}
    {{- $last := eq (len (slice $.Messages $i)) 1 -}}
    {{- if eq .Role "user" }}<|im_start|>user
    {{ .Content }}
    /think<|im_end|>
    {{ else if eq .Role "assistant" }}<|im_start|>assistant
    {{ if .Content }}{{ .Content }}
    {{- else if .ToolCalls }}<tool_call>
    {{ range .ToolCalls }}{"name": "{{ .Function.Name }}", "arguments": {{ .Function.Arguments }}}
    {{ end }}</tool_call>
    {{- end }}{{ if not $last }}<|im_end|>
    {{ end }}
    {{- else if eq .Role "tool" }}<|im_start|>user
    <tool_response>
    {{ .Content }}
    </tool_response><|im_end|>
    {{ end }}
    {{- if and (ne .Role "assistant") $last }}<|im_start|>assistant
    {{ end }}
    {{- end }}
    {{- else }}
    {{- if .System }}<|im_start|>system
    {{ .System }}<|im_end|>
    {{ end }}{{ if .Prompt }}<|im_start|>user
    {{ .Prompt }}
    /think<|im_end|>
    {{ end }}<|im_start|>assistant
    {{ end }}{{ .Response }}{{ if .Response }}<|im_end|>{{ end }}"""

    PARAMETER num_ctx 4096
    PARAMETER num_gpu -1
    PARAMETER num_thread 12
  '';
in {
  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;
    host = "127.0.0.1";
    port = 11434;
    rocmOverrideGfx = "10.3.0";
    environmentVariables = {
      OLLAMA_CONTEXT_LENGTH = "4096";
      OLLAMA_NUM_PARALLEL = "1";
      OLLAMA_MAX_LOADED_MODELS = "1";
    };
  };

  systemd.services.ollama.serviceConfig.SupplementaryGroups = [
    "render"
    "video"
  ];

  systemd.services.ollama-qwen36-model = {
    description = "Create Ollama model ${qwen36.alias} from pinned GGUF";
    after = ["ollama.service"];
    wants = ["ollama.service"];
    wantedBy = ["multi-user.target"];
    path = [config.services.ollama.package];
    environment = {
      HOME = config.services.ollama.home;
      OLLAMA_HOST = "http://${config.services.ollama.host}:${toString config.services.ollama.port}";
    };
    script = ''
      ollama create ${qwen36.alias} -f ${qwen36OllamaModelfile}
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  systemd.tmpfiles.rules = [
    "r /var/lib/ollama/import/Qwen3.6-27B-UD-IQ2_XXS.gguf - - - - -"
    "r /var/lib/ollama/import/qwen3.6-27b-iq2.Modelfile - - - - -"
  ];

  services.open-webui = {
    enable = true;
    package = pkgs.nixpkgs-master.open-webui;
    host = "0.0.0.0";
    port = openWebuiPort;
    environment = {
      WEBUI_AUTH = "False";
      ENABLE_SIGNUP = "False";
      ENABLE_OLLAMA_API = "True";
      ENABLE_OPENAI_API = "False";
      OLLAMA_BASE_URL = "http://${config.services.ollama.host}:${toString config.services.ollama.port}";
      DEFAULT_MODELS = qwen36.alias;
      ANONYMIZED_TELEMETRY = "False";
      BYPASS_MODEL_ACCESS_CONTROL = "True";
      DO_NOT_TRACK = "True";
      SCARF_NO_ANALYTICS = "True";
      FRONTEND_BUILD_DIR = "${config.services.open-webui.stateDir}/build";
      DATA_DIR = "${config.services.open-webui.stateDir}/data";
      STATIC_DIR = "${config.services.open-webui.stateDir}/static";
    };
  };

  systemd.services.open-webui = {
    after = [
      "ollama.service"
      "ollama-qwen36-model.service"
    ];
    wants = [
      "ollama.service"
      "ollama-qwen36-model.service"
    ];
  };

  environment.systemPackages = [pkgs.ollama-rocm];
}

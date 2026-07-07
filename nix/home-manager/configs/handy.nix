{
  lib,
  pkgs,
  ...
}: let
  scripts = import ../scripts.nix {inherit pkgs;};
  settings = {
    always_on_microphone = false;
    app_language = "en-US";
    append_trailing_space = false;
    audio_feedback = true;
    audio_feedback_volume = 1.0;
    auto_submit = false;
    auto_submit_key = "enter";
    autostart_enabled = false;
    bindings = {
      cancel = {
        current_binding = "escape";
        default_binding = "escape";
        description = "Cancels the current recording.";
        id = "cancel";
        name = "Cancel";
      };
      transcribe = {
        current_binding = "ctrl+space";
        default_binding = "ctrl+space";
        description = "Converts your speech into text.";
        id = "transcribe";
        name = "Transcribe";
      };
      transcribe_with_post_process = {
        current_binding = "ctrl+shift+space";
        default_binding = "ctrl+shift+space";
        description = "Converts your speech into text and applies AI post-processing.";
        id = "transcribe_with_post_process";
        name = "Transcribe with Post-Processing";
      };
    };
    clamshell_microphone = null;
    clipboard_handling = "copy_to_clipboard";
    custom_filler_words = null;
    custom_words = [];
    debug_mode = false;
    experimental_enabled = false;
    external_script_path = null;
    extra_recording_buffer_ms = 0;
    history_limit = 5;
    keyboard_implementation = "tauri";
    lazy_stream_close = false;
    log_level = "debug";
    model_unload_timeout = "min5";
    mute_while_recording = false;
    onboarding_completed = true;
    ort_accelerator = "auto";
    overlay_position = "none";
    overlay_style = "none";
    paste_delay_ms = 60;
    paste_method = "none";
    post_process_api_keys = {
      anthropic = "";
      bedrock_mantle = "";
      cerebras = "";
      custom = "";
      groq = "";
      openai = "";
      openrouter = "";
      zai = "";
    };
    post_process_enabled = false;
    post_process_models = {
      anthropic = "";
      bedrock_mantle = "";
      cerebras = "";
      custom = "";
      groq = "";
      openai = "";
      openrouter = "";
      zai = "";
    };
    post_process_prompts = [
      {
        id = "default_improve_transcriptions";
        name = "Improve Transcriptions";
        prompt = ''
          Clean this transcript:
          1. Fix spelling, capitalization, and punctuation errors
          2. Convert number words to digits (twenty-five -> 25, ten percent -> 10%, five dollars -> $5)
          3. Replace spoken punctuation with symbols (period -> ., comma -> ,, question mark -> ?)
          4. Remove filler words (um, uh, like as filler)
          5. Keep the language in the original version (if it was french, keep it in french for example)

          Preserve exact meaning and word order. Do not paraphrase or reorder content.

          Return only the cleaned transcript.

          Transcript:
          ''${output}
        '';
      }
    ];
    post_process_provider_id = "openai";
    post_process_providers = [
      {
        allow_base_url_edit = false;
        base_url = "https://api.openai.com/v1";
        id = "openai";
        label = "OpenAI";
        models_endpoint = "/models";
        supports_structured_output = true;
      }
      {
        allow_base_url_edit = false;
        base_url = "https://api.z.ai/api/paas/v4";
        id = "zai";
        label = "Z.AI";
        models_endpoint = "/models";
        supports_structured_output = true;
      }
      {
        allow_base_url_edit = false;
        base_url = "https://openrouter.ai/api/v1";
        id = "openrouter";
        label = "OpenRouter";
        models_endpoint = "/models";
        supports_structured_output = true;
      }
      {
        allow_base_url_edit = false;
        base_url = "https://api.anthropic.com/v1";
        id = "anthropic";
        label = "Anthropic";
        models_endpoint = "/models";
        supports_structured_output = false;
      }
      {
        allow_base_url_edit = false;
        base_url = "https://api.groq.com/openai/v1";
        id = "groq";
        label = "Groq";
        models_endpoint = "/models";
        supports_structured_output = false;
      }
      {
        allow_base_url_edit = false;
        base_url = "https://api.cerebras.ai/v1";
        id = "cerebras";
        label = "Cerebras";
        models_endpoint = "/models";
        supports_structured_output = true;
      }
      {
        allow_base_url_edit = false;
        base_url = "https://bedrock-mantle.us-east-1.api.aws/v1";
        id = "bedrock_mantle";
        label = "AWS Bedrock (Mantle)";
        models_endpoint = "/models";
        supports_structured_output = false;
      }
      {
        allow_base_url_edit = true;
        base_url = "http://localhost:11434/v1";
        id = "custom";
        label = "Custom";
        models_endpoint = "/models";
        supports_structured_output = false;
      }
    ];
    post_process_selected_prompt_id = null;
    push_to_talk = true;
    recording_retention_period = "preserve_limit";
    selected_language = "auto";
    selected_microphone = null;
    selected_model = "handy-computer/parakeet-unified-en-0.6b-gguf/parakeet-unified-en-0.6b-Q8_0.gguf";
    selected_output_device = null;
    settings_schema_version = 1;
    show_tray_icon = true;
    show_whats_new_on_update = true;
    sound_theme = "marimba";
    start_hidden = true;
    transcribe_accelerator = "auto";
    transcribe_gpu_device = -1;
    translate_to_english = false;
    typing_tool = "auto";
    update_checks_enabled = true;
    vad_enabled = true;
    whats_new_last_seen_version = "0.9.0";
    word_correction_threshold = 0.18;
  };
in {
  home.packages = [
    pkgs.handy
    scripts.handy-transcribe
  ];

  xdg.dataFile."com.pais.handy/settings_store.json".text = builtins.toJSON {
    inherit settings;
  };

  systemd.user.services.handy = {
    Unit = {
      Description = "Handy speech to text";
      After = ["graphical-session.target"];
      Requisite = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
      X-SwitchMethod = "keep-old";
    };
    Service = {
      Type = "simple";
      ExecStart = "${lib.getExe pkgs.handy} --start-hidden";
      Restart = "on-failure";
      RestartSec = "3s";
      StandardOutput = "journal";
      StandardError = "journal";
      Slice = ["app-graphical.slice"];
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}

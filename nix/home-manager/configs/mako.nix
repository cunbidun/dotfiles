{...}: {
  services.mako = {
    enable = false;

    settings = {
      width = 300;
      height = 100;
      margin = "20";
      padding = "20";
      default-timeout = 5000;

      # Positioning and layout
      anchor = "top-right";
      layer = "overlay";

      "urgency=critical" = {
        "ignore-timeout" = 1;
      };
    };
  };
}

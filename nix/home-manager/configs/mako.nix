{...}: {
  services.mako = {
    enable = true;

    settings = {
      width = 300;
      height = 100;
      margin = "20";
      padding = "20";

      # Positioning and layout
      anchor = "top-right";
      layer = "overlay";

      "urgency=critical" = {
        "ignore-timeout" = 1;
      };
    };
  };
}

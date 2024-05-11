{...}: {
  programs.firefox = {
    enable = true;
    profiles.piotr = {
      isDefault = true;
      settings = {
        "browser.disableResetPrompt" = true;
        "browser.shell.checkDefaultBrowser" = false;
        "browser.shell.defaultBrowserCheckCount" = 1;
        "dom.security.https_only_mode" = true;
        "browse.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "privacy.trackingprotection.enabled" = true;
      };
    };
  };
}

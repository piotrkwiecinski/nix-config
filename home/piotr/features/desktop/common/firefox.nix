{ pkgs, lib, ... }:
{
  programs.firefox = {
    enable = true;
    package = lib.mkDefault pkgs.unstable.firefox;
    policies = {
      AppAutoUpdate = false;
      OfferToSaveLogins = false;
      DisableFirefoxAccounts = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DisableSetDesktopBackground = true;
      PromptForDownloadLocation = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
        EmailTracking = true;
      };
      EncryptedMediaExtensions = {
        Enabled = true;
        Locked = true;
      };
      DontCheckDefaultBrowser = true;
    };
    profiles.piotr = {
      isDefault = true;
      settings = {
        "distribution.searchplugins.defaultLocale" = "en-GB";
        "general.useragent.locale" = "en-GB";
        "browser.disableResetPrompt" = true;
        "browser.shell.defaultBrowserCheckCount" = 1;
        "dom.security.https_only_mode" = true;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "privacy.trackingprotection.enabled" = true;
      };
    };
  };
}

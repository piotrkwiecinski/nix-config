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
      Certificates.ImportEnterpriseRoots = true;
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
        "security.webauth.webauthn_enable_usbtoken" = true;
        "security.webauth.enable_softtoken" = false;
        "security.webauth.u2f_softtoken_enabled" = false;
        "security.webauth.ctap2" = true;
      };
    };
  };
}

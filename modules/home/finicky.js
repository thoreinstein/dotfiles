export default {
  defaultBrowser: "Google Chrome",
  options: {
    checkForUpdates: false,
    logRequests: true,
  },
  rewrite: [
    {
      match: "forgerock.slack.com/*",
      url: (url) => {
        url.host = "pingidentity.slack.com";
        return url;
      },
    },
  ],
  handlers: [
    // Work - GitHub (ping profile)
    {
      match: ["https://github.com/*", "https://gist.github.com/*"],
      browser: {
        name: "Google Chrome",
        profile: "ping",
        openInBackground: true,
      },
    },

    // Work - Google Cloud Console (forgerock.io profile)
    {
      match: [
        "console.cloud.google.com/*",
        "https://accounts.google.com/o/oauth2/*",
        "https://storage.cloud.google.com/*",
        "https://cloudlogging.app.goo.gl/*",
      ],
      browser: {
        name: "Google Chrome",
        profile: "forgerock.io",
        openInBackground: true,
      },
    },

    // Work - Ping/ForgeRock tools (ping profile)
    {
      match: [
        "*.pingidentity.com/*",
        "*.pingfederal.com/*",
        "*.forgerock.com/*",
        "*.forgerock.io/*",
        "pingidentity.slack.com/*",
      ],
      browser: {
        name: "Google Chrome",
        profile: "ping",
        openInBackground: true,
      },
    },

    // Work - Common work tools (ping profile)
    {
      match: [
        "*.atlassian.net/*",
        "*.jira.com/*",
        "*.confluence.com/*",
        "*.zoom.us/*",
        "*.webex.com/*",
        "meet.google.com/*",
      ],
      browser: {
        name: "Google Chrome",
        profile: "ping",
        openInBackground: true,
      },
    },

    // Personal - Email (Chrome personal profile)
    {
      match: [
        "mail.google.com/*",
        "gmail.com/*",
        "mail.yahoo.com/*",
        "outlook.live.com/*",
        "outlook.office.com/*",
        "mail.proton.me/*",
        "protonmail.com/*",
      ],
      browser: {
        name: "Google Chrome",
        profile: "personal",
        openInBackground: true,
      },
    },

    // Personal - Social Media (Chrome personal profile)
    {
      match: [
        "*.twitter.com/*",
        "*.x.com/*",
        "*.facebook.com/*",
        "*.instagram.com/*",
        "*.linkedin.com/*",
        "*.reddit.com/*",
        "*.tiktok.com/*",
        "*.pinterest.com/*",
        "*.snapchat.com/*",
        "*.threads.net/*",
        "*.mastodon.social/*",
        "*.bsky.app/*",
      ],
      browser: {
        name: "Google Chrome",
        profile: "personal",
        openInBackground: true,
      },
    },

    // Personal - Shopping & Entertainment (Chrome personal profile)
    {
      match: [
        "*.amazon.com/*",
        "*.youtube.com/*",
        "*.netflix.com/*",
        "*.hulu.com/*",
        "*.disneyplus.com/*",
        "*.spotify.com/*",
        "*.apple.com/*",
        "*.ebay.com/*",
        "*.etsy.com/*",
        "*.target.com/*",
        "*.walmart.com/*",
        "*.nytimes.com/*",
        "*.washingtonpost.com/*",
        "*.theguardian.com/*",
        "*.medium.com/*",
        "*.substack.com/*",
      ],
      browser: {
        name: "Google Chrome",
        profile: "personal",
        openInBackground: true,
      },
    },
  ],
};

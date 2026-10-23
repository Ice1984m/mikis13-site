# Mikis13 Store

Mikis13.nl is a neon-purple app store with three pages: `index.html` highlights the current top app, `apps.html` lists available apps, and `binnenkort.html` lists apps in preparation.

## Mikis13 Stream

The web and Android players open user-provided HTTPS MP3, M3U, and M3U8 streams. No channels, music, or video are supplied. Users are responsible for using streams they own or are allowed to play. The stream list is stored locally on the user's device.

Open `media.html` for the web player. The Android project is in `android-app/` and uses Android Media3/ExoPlayer for MP3 and HLS playback.

## Website deployment

The static website is published through GitHub Pages by the workflow in `.github/workflows/pages.yml`. A push to `main` triggers the website checks and publication. The workflow currently publishes only after its checks pass.

## Developer Hub

`devtools.html` links to the official Kiro, Visual Studio Code, Cursor, and GitHub pages. Its clone command points to `https://github.com/Ice1984m/mikis13-site.git`.

## Security

Do not commit access tokens, passwords, private signing keys, or stream credentials to this repository.

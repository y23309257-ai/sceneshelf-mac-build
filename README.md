# SceneShelf Mac installer build

This repository contains only a manual GitHub Actions build recipe. It downloads
the already published SceneShelf runtime kit and verifies its pinned SHA-256.
It does not contain project source, user projects, media, API keys, or account credentials.

The two standard macOS runners create Apple Silicon and Intel test installers.
The packages are unsigned and are not notarized. A build success is not a claim
that installation, browser connection, or the complete app has passed Mac testing.

Run `Build SceneShelf Mac installers` manually, then download the two artifacts.
Only verified `.pkg` files and their checksums should be added to the existing Sites
download page. Do not enable a download button before its real package exists.

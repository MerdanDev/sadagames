# Pages site

Two files, served by GitHub Pages from this directory.

- `index.html` — the developer website the Play Console store listing points at.
- `app-ads.txt` — the AdMob authorization record. Nothing in it is secret: the
  publisher id is already inside every ad unit id and every shipped APK, and
  `f08c47fec0942fa0` is Google's TAG id, the same for every AdMob publisher.
  The file is an allowlist saying who may sell this inventory, so it only works
  by being public.
- `.nojekyll` — skips Jekyll, so the `.txt` is served byte for byte.

## It has to sit at the domain root

Crawlers strip the path off the developer website URL and fetch
`https://<host>/app-ads.txt`. They never look in a subdirectory.

A **project** Pages site publishes to `https://merdandev.github.io/sadagames/`,
so this file lands at `.../sadagames/app-ads.txt` and AdMob will not find it.
One of these has to be true before the record verifies:

1. **A custom domain on this repo** — add a `CNAME` file here, point the DNS at
   GitHub Pages, and set that domain as the developer website in Play Console.
   The file then serves from the root and verifies.
2. **A user site** — the same `app-ads.txt` in a repo named exactly
   `MerdanDev.github.io`, which publishes at the root already.

Until then the page is live and correct; only the AdMob check is pending.

## Turning Pages on

Settings → Pages → source: branch `main` (or `admob-ads` to see it before the
merge), folder `/docs`.

Expect lag on verification: Google recrawls within about a day, but AdMob can
take several more to move the app to Authorized.

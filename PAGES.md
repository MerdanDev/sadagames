# Pages site

Three files at the repo root, served by GitHub Pages from `main` / `(root)`.

- `index.html` — the developer website the Play Console store listing points at.
- `app-ads.txt` — the AdMob authorization record. Nothing in it is secret: the
  publisher id is already inside every ad unit id and every shipped APK, and
  `f08c47fec0942fa0` is Google's TAG id, the same for every AdMob publisher.
  The file is an allowlist saying who may sell this inventory, so it only works
  by being public.
- `.nojekyll` — skips Jekyll. With a root source Pages would otherwise try to
  build the whole repo, and the `.txt` risks being processed rather than served
  byte for byte.

Turn it on under Settings → Pages → source: branch `main`, folder `/`.

## It has to sit at the *domain* root, which this is not

Crawlers strip the path off the developer website URL and fetch
`https://<host>/app-ads.txt`. They never look in a subdirectory.

A **project** Pages site always publishes under the repo name, so these files
land at `https://merdandev.github.io/sadagames/app-ads.txt` — one level too
deep. Moving them out of `docs/` to the repo root did not change that: both
produce the same URL, because the `/sadagames/` segment comes from the repo
name, not from where the files sit in the tree.

One of these has to be true before AdMob will verify the record:

1. **A custom domain on this repo** — add a `CNAME` file next to these, point
   the DNS at GitHub Pages, and set that domain as the developer website in
   Play Console. The file then serves from the root.
2. **A user site** — the same `app-ads.txt` in a repo named exactly
   `MerdanDev.github.io`, which publishes at the root already. That repo can be
   a two-file stub; it does not need the games.

Until then the page is live and the file is correct — only the AdMob check is
pending.

Expect lag once it is reachable: Google recrawls within about a day, but AdMob
can take several more to move the app to Authorized.

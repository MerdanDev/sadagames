# Developer site and app-ads.txt

Both live in a **separate repo**, not here: [MerdanDev/MerdanDev.github.io][site].

    https://merdandev.github.io/            the developer site
    https://merdandev.github.io/app-ads.txt the AdMob authorization record

## Why not in this repo

AdMob strips the path off the developer website URL in the store listing and
fetches `https://<host>/app-ads.txt`. It never looks in a subdirectory.

A GitHub **project** site always publishes under the repo name, so anything here
serves from `https://merdandev.github.io/sadagames/…` — one level too deep to
ever be found, wherever the file sits in the tree. A **user** site publishes at
the host root, which is the whole reason the other repo exists.

This repo did carry a copy at its root for one commit. It was removed because two
copies of an authorization record is one too many: the crawler reads exactly one,
and the other only rots.

## Keeping it working

- The Play Console **developer website** must be `https://merdandev.github.io`.
  That URL is the only thing connecting the store listing to the record.
- Every mediation partner AdMob adds needs its own line in [the site repo][site].
- Nothing in `app-ads.txt` is secret — see the gotchas in
  [.claude/docs/ads.md](.claude/docs/ads.md).

The alternative, if this repo should ever serve the site itself, is a custom
domain: add a `CNAME`, point the DNS at Pages, and set that domain as the
developer website. Then the root is a real domain root and the record verifies
from here.

[site]: https://github.com/MerdanDev/MerdanDev.github.io

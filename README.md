# releases.kojalang.org

The release catalog for the [Koja](https://kojalang.org) compiler. A set of static text and JSON files that answer "which versions exist" and "what does `0.18` mean" without the GitHub API, a token, or a rate limit.

Every file is generated. The koja release workflow runs `bin/generate` after it attaches tarballs to a GitHub Release, commits the result here, and GitHub Pages serves the `main` branch.

## Endpoints

| URL                            | Body                                                 |
| ------------------------------ | ---------------------------------------------------- |
| `/latest`                      | Newest version, one line: `0.18.3`                   |
| `/latest.json`                 | Record of the newest release                         |
| `/resolve/<major>`             | Newest version in that major line, one line          |
| `/resolve/<major.minor>`       | Newest version in that minor line, one line          |
| `/resolve/<major.minor.patch>` | The same version back, so callers need one code path |
| `/versions`                    | Every version, oldest first, one per line            |
| `/index.json`                  | Every record, newest first                           |
| `/releases/<version>.json`     | Record of one release                                |

A version with no release is a 404. Only releases with prebuilt binaries appear, so the catalog starts at 0.12.1.

Responses carry `Access-Control-Allow-Origin: *` and `Cache-Control: max-age=600`, so a browser can read them and a new release is visible everywhere within ten minutes.

## Record

```json
{
  "date": "2026-09-07",
  "files": {
    "darwin-arm64": {
      "sha256": "9add273db6e8786bb31181678c792fe21f7e5bbdc3df8b515bea8dd8909945c9",
      "size": 41162115,
      "url": "https://github.com/koja-lang/koja/releases/download/v0.18.3/koja-v0.18.3-darwin-arm64.tar.gz"
    },
    "linux-arm64": { "...": "..." },
    "linux-x86_64": { "...": "..." }
  },
  "version": "0.18.3"
}
```

## Examples

```sh
# Newest release
curl -fsSL https://releases.kojalang.org/latest

# Newest 0.18.x
curl -fsSL https://releases.kojalang.org/resolve/0.18

# Download the newest release for this machine
version=$(curl -fsSL https://releases.kojalang.org/latest)
curl -fLO "https://github.com/koja-lang/koja/releases/download/v$version/koja-v$version-darwin-arm64.tar.gz"
```

## Generator

`bin/generate VERSION DIST_DIR` records one release from the tarballs and `.sha256` sidecars in `DIST_DIR`, then rebuilds every derived file. This two-argument form is the contract the koja release workflow calls. Keep it stable.

`bin/generate` with no arguments rebuilds the derived files from `releases/*.json`. Run it after a hand edit, for example after deleting a record to yank a release.

`bin/backfill` seeds `releases/` from the GitHub releases of `koja-lang/koja` and rebuilds. It needs the `gh` CLI signed in.

`test/generate_test.sh` runs the generator against a fixture and checks every output.

## License

Copyright (c) 2026 Henry Popp

This project is MIT licensed. See the [LICENSE](LICENSE) for details.

# Approved GitHub release transfer

These manual workflows transfer only the explicitly approved, hash-pinned existing PHP archives to this repository. They use short-lived links to private GitHub release assets and a repository-scoped Actions token. No PHP builds, R2 publication, Cloudsmith publication, or production build-gate changes occur. Unrelated release assets are preserved. Existing public assets were backed up and verified before authorization. Each version has independent concurrency.

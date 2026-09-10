# Tap maintenance

- Publish Linux ARM64 and AMD64 bottles for every formula release, including
  dependencies maintained in this tap. Source-only publication is not the
  normal release process. Keep source builds available as a fallback.
- Build ARM64 natively on a DGX Spark (ostrich, dodo, emu, or kiwi); build
  AMD64 natively on raptor. Do not cross-compile. Native containers are fine.
- Use Homebrew's default bottle CPU baseline and the pinned build images in
  `scripts/build-bottles`. Do not use host-specific CPU tuning.
- Test installation from the actual published bottles, check receipts and
  linkage, and run `scripts/test-fabric` on the fleet before declaring a
  release complete.
- Commit and push work as it progresses. Never overwrite published bottle
  assets; use a new release tag and Homebrew bottle rebuild number.
- Prefer MIT for new tap code. Preserve upstream licenses.

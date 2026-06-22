# Obtainium — install patched APKs from GitHub Releases

Pre-built patched APKs are published as [GitHub Release](https://github.com/bigyank/SamsungAppsPatcher/releases) assets. Use [Obtainium](https://github.com/ImranR98/Obtainium) to install and update them like a normal app store.

## Add Samsung Health (patched)

1. Install [Obtainium](https://github.com/ImranR98/Obtainium/releases) on your Samsung phone.
2. **+** → **App source URL**:

   ```
   https://github.com/bigyank/SamsungAppsPatcher
   ```

3. Source type: **GitHub** (Obtainium should detect this).
4. Filter / asset pattern (if prompted):

   ```
   Samsung-Health.*patched\.apk
   ```

5. Enable the app → **Install**. Uninstall stock Samsung Health first (signature mismatch).

## Add Galaxy Wearable or Accessory Service

Same repo URL. Use asset patterns:

| App | Pattern |
|-----|---------|
| Galaxy Wearable | `Galaxy-Wearable.*patched\.apk` |
| Accessory Service | `Samsung-Accessory-Service.*patched\.apk` |

Install **Accessory Service → Galaxy Wearable → Samsung Health** before watch plugins.

## Updates

Obtainium checks GitHub Releases for new `Samsung-Health-*-patched.apk` assets. When a maintainer publishes a new release (new Samsung Health version), Obtainium offers an update.

## Morphe alternative (Health only)

For on-device patching without pre-built APKs, use [morphe-patches-samsung](https://github.com/bigyank/morphe-patches-samsung) instead. Obtainium is for users who want signed release APKs from this repo.

## Maintainer: publish a release

### One-time GitHub secrets

| Secret | Purpose |
|--------|---------|
| `KEYSTORE_JKS_B64` | Base64 of community `keystore.jks` (SamsungPatch cert) |
| `KEYSTORE_STORE_PASS` | Keystore store password |
| `KEYSTORE_KEY_PASS` | Key password (same as store if single password) |
| `SHEALTH_APK_URL` | Direct download URL for unpatched Health APK (see below) |
| `WEARABLE_APK_URL` | Optional: unpatched Galaxy Wearable APK |
| `ACCESSORYSERVICE_APK_URL` | Optional: unpatched Accessory Service APK |

Encode keystore:

```bash
base64 -i keystore.jks | pbcopy   # paste into KEYSTORE_JKS_B64
```

APK URLs: download the target version from [APKMirror](https://www.apkmirror.com/), copy the **direct APK link** (right-click → copy link on the download button), and store as a secret. Update `versions.json` when Samsung ships a new build.

### Trigger build

**Actions → Build patched APKs → Run workflow**

- **apps:** `shealth` or `shealth wearable accessoryservice`
- **tag:** e.g. `apks-6.32.0.001` to create a GitHub Release Obtainium can track

Or push a tag:

```bash
git tag apks-6.32.0.001
git push bigyank apks-6.32.0.001
```

Artifacts land in **Releases** as `Samsung-Health-6.32.0.001-patched.apk`, etc.

## Version pins

See [versions.json](./versions.json) for the Health / Wearable versions CI expects. Bump when adding a new Samsung build.

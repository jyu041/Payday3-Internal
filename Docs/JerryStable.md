# Jerry stable branch

This fork keeps `v3` as the clean upstream mirror and uses `jerry-stable` for local stability fixes.

## Current local patches

- Guard the original AI pawn-action call with `OmegaRenderHook::InvokeGuarded` so an access violation inside the game function is skipped instead of terminating PAYDAY 3.
- Route Instant Minigame completion through the active minigame widget's `SetMiniGameState(Success)` API after a short settle delay, with guarded execution and no fallback to the crash-prone direct `ASBZPlayerState::Server_SetMiniGameState` RPC.
- Emit PDB symbols for release builds so future crash dumps can resolve `version.dll` frames to source lines.
- Provide `Scripts/BuildAndDeployLocal.ps1` to build, test, back up the installed proxy, deploy the new proxy and verify its SHA-256.

Instant Minigame remains disabled by default. The direct PlayerState success RPC reproduced a pure-virtual/null-dereference crash on safes, so `jerry-stable` now avoids that RPC entirely. The widget-based path is still experimental until runtime-tested.

## Remotes

Recommended local remotes:

```text
origin   https://github.com/jyu041/Payday3-Internal.git
upstream https://github.com/Omega172/Payday3-Internal.git
```

## Normal local update/build

After `jerry-stable` has already been set up locally:

```powershell
git checkout jerry-stable
git pull --ff-only origin jerry-stable
.\Scripts\BuildAndDeployLocal.ps1
```

## Updating from upstream

Do not automatically merge upstream into `jerry-stable` without reviewing the affected files first. The preferred flow is:

```powershell
git fetch upstream

git checkout v3
git reset --hard upstream/v3
git push origin v3 --force-with-lease

git checkout jerry-stable
git rebase v3
```

Review any conflicts and check whether upstream has implemented equivalents of the local patches. If an upstream fix supersedes a local commit, drop the redundant local commit instead of preserving two versions of the same fix.

After the rebase and a successful build/test:

```powershell
git push origin jerry-stable --force-with-lease
```

# Jerry stable branch

This fork keeps `v3` as the clean upstream mirror and uses `jerry-stable` for local stability fixes.

## Current local patches

- Guard the original AI pawn-action call with `OmegaRenderHook::InvokeGuarded` so an access violation inside the game function is skipped instead of terminating PAYDAY 3.
- Drive supported Instant Minigames through their concrete gameplay actions instead of forcing a terminal minigame state: lockpicks use `GainProgress`, safes submit the widget's generated correct dial value through `OnSelectNumber`, widget discovery is retried, and all automation is bounded/fail-closed.
- Emit PDB symbols for release builds so future crash dumps can resolve `version.dll` frames to source lines.
- Provide `Scripts/BuildAndDeployLocal.ps1` to build, test, back up the installed proxy, deploy the new proxy and verify its SHA-256.

Instant Minigame remains disabled by default. Runtime testing on 2026-11-10 showed that both the direct PlayerState success RPC and the generic widget `SetMiniGameState(Success)` route can converge on the same safe-cracking pure-virtual site at PAYDAY3 `+0x1442AD6`; the generic widget route also intermittently missed a not-yet-spawned widget and then failed to retry. `jerry-stable` therefore avoids terminal-state forcing entirely for this feature and uses bounded widget-native progression. This replacement path is still experimental until runtime-tested.

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

# Scenario 2

This demonstrates the issue using an ApplicationSet, instead of by hand.

If the ApplicationSet uses a git generator with the same source as the
Applications it generates, newly-added apps won't be hydrated unless they get
created before the existing apps are hydrated.

## Setup

 1. Apply the AppProject from `appproject.yaml`
 2. Apply the ApplicationSet from `appset.yaml`
 3. Wait for the Application `scenario-2-one` under the `argocd` namespace to sync.

## Reproduction

 1. Rename `apps/two.yaml.disabled` to `apps/two.yaml`
 2. Commit the rename, creating a new DRY commit.
 3. Refresh and sync the `scenario-2-two` app manually. (this step is important)
 4. Wait for the `scenario-2-two` app to be created and refreshed.

## Expected Result

 - The manifests for `scenario-2-two` will be hydrated, creating a new commit
   on the `hydrated` branch with the rendered manifests under
   `manifests/scenario-2/two/`.

 - The `scenario-2-two` app is synced, creating a `scenario-2-two` ConfigMap
   in the `test` namespace.

## Actual Result

 - No new commit is created on the `hydrated` branch, but the `scenario-2-two`
   app's Source Hydrator status in the web UI shows that it was successfully
   hydrated.

 - The `scenario-2-two` app fails to sync because the manifests don't exist
   on the `hydrated` (syncSource) branch.

 - Requesting a Hard Refresh of `scenario-2-two` updates the timestamp of the
   Source Hydrator status to say "hydrated a few seconds ago", but does not
   hydrate the missing manifests.

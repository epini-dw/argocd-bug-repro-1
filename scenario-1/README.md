# Scenario 1

This manually demonstrates the underlying issue.

When a commit is hydrated, the `hydration.metadata` git note attached to the
hydration commit is updated to reference the DRY commit. When hydration is
later attempted against the same DRY commit, the commitserver will skip pushing
any changes.

Due to this, if new Application with the same hydration key
(DRY source, hydration target branch) is later added without creating a new
DRY commit, the Application won't be properly hydrated.

## Setup

 1. Apply the AppProject from `appproject.yaml`

## Reproduction

 1. Apply the Application from `app-foo.yaml`
 2. Wait for the Application `scenario-1-foo` under the `argocd` namespace to sync.
 3. Apply the Application from `app-bar.yaml`

## Expected Result

 - The manifests for `scenario-1-bar` will be hydrated, creating a new commit
   on the `hydrated` branch with the rendered manifests under
   `manifests/scenario-1/bar/`.

 - The `scenario-1-bar` app is synced, creating a `scenario-1-bar` ConfigMap
   in the `test` namespace.

## Actual Result

 - No new commit is created on the `hydrated` branch, but the `scenario-1-bar`
   app's Source Hydrator status in the web UI shows that it was successfully
   hydrated.

 - The `scenario-1-bar` app fails to sync because the manifests don't exist
   on the `hydrated` (syncSource) branch.

 - Requesting a Hard Refresh of `scenario-1-bar` updates the timestamp of the
   Source Hydrator status to say "hydrated a few seconds ago", but does not
   hydrate the missing manifests.

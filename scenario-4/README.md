# Scenario 4

This demonstrates a related problem caused by the same underlying issue, where
changing the Helm (or CMP plugin) parameters in an Application's drySource will
also not be properly hydrated.

I found this problem as the result of a race condition when using an
ApplicationSet to generate an Application from the same repo as the
ApplicationSet's git generator.

## Setup

 1. Apply the AppProject from `appproject.yaml`

## Reproduction

 1. Apply the Application from `app.yaml`
 2. Wait for the Application `scenario-4-app` under the `argocd` namespace to sync.
 3. Apply the Application from `app-modified.yaml`

## Expected Result

 - The changes in the Application's drySource parameters will be reflected with
   the `scenario-4` ConfigMap now having `message: Goodnight, moon.` instead of
   `message: Hello world!`

## Actual Result

 - No new commit is created on the `hydrated` branch, but the `scenario-4-app`
   app's Source Hydrator status in the web UI shows that it was successfully
   hydrated.

 - The `scenario-4` ConfigMap still has `message: Hello world!`

 - Requesting a Hard Refresh of `scenario-4-app` updates the timestamp of the
   Source Hydrator status to say "hydrated a few seconds ago", but does not
   change the ConfigMap contents.

# Scenario 3

This demonstrates the issue using the app-of-apps pattern.

## Setup

 1. Apply the AppProject from `appproject.yaml`

## Reproduction

 1. Apply the app-of-apps from `app-of-apps.yaml`

## Expected Result

 - The app-of-apps creates `scenario-3-one`, which is then hydrated and synced.

## Actual Result

 - The app-of-apps creates `scenario-3-one`, but because the app-of-apps already
   hydrated the commit to create the app itself, `scenario-3-one` won't have
   its manifests hydrated.

 - Requesting a Hard Refresh of `scenario-3-one` updates the timestamp of the
   Source Hydrator status to say "hydrated a few seconds ago", but does not
   hydrate the missing manifests.

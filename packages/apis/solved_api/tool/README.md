# Public solved.ac contract capture

This tool converts a browser HAR into reviewable request metadata and JSON
response fixtures. A reviewed plan explicitly names every expected scenario;
the capture succeeds only when each planned public HTTPS `GET` exchange matches
exactly once.

Capture traffic in a signed-out private browser window and export the HAR with
response content. Never commit the raw HAR. The plan is part of the security
boundary, so review every path and query value and never put credentials or
private identifiers in it.

## Inventory observed candidates

Before writing a plan, produce a value-free inventory of the signed-out HAR:

```sh
dart run tool/inventory_public_har.dart \
  --input /path/to/public.har \
  --host solved.ac
```

The inventory accepts only public-safe HTTPS `GET` requests with JSON
responses. It groups exact contract shapes by path, sorted query names and
value counts, status, normalized JSON media type, and top-level JSON type. It
never writes query values, response values, bodies, headers, cookies, full
URLs, timestamps, or local paths. Fixed exclusion counters describe why other
HAR entries were not candidates without identifying an entry.

The inventory is a discovery aid, not an automatically trusted plan. Match
each candidate back to the browser action that caused it, inspect the raw HAR
locally, and manually copy only reviewed public values into a plan. The plan
and the exact-one-match capture checks remain the enforcement boundary.

### Observation checklist

These are UI scenarios, not claims about API paths or JSON field names. Record
one action at a time so its public requests can be attributed unambiguously.

1. User profile: load a stable public profile signed out, then observe its
   summary, rating, activity, tag/problem statistics, achievements, and
   contribution sections. Include successful, missing-user, and sparse-profile
   cases where the UI offers them.
2. Search: exercise public suggestions and result views for user, problem, and
   tag searches, including a normal result and an empty result.
3. Auxiliary views: visit the public profile-linked views used by the app,
   such as activity, top problems, organizations, badges/backgrounds, and the
   public contest or service-statistics views that are actually reachable.

Current UI/domain evidence and wire evidence must stay separate:

- The current [contribution guideline](https://solved.ac/en/guideline), public
  profiles, and [Over Rating help](https://solved.ac/en/help/stats/over-rating)
  establish user-facing meanings such as Reputation, Helpful marks, vouching,
  rating components, and Over Rating. They do not establish endpoint paths,
  request parameters, JSON names, nullability, or types. In particular, old
  contribution-rating fields must not be renamed to Reputation by inference.
- Only a reviewed public HAR exchange establishes the observed wire contract.
  Inventory metadata helps locate that evidence but is not itself a response
  fixture or a schema guarantee.

Create a plan without guessing endpoint names. Use only paths, query values,
and statuses observed in the public browser traffic:

```json
{
  "schemaVersion": 1,
  "host": "solved.ac",
  "operations": [
    {
      "id": "observed-scenario-success",
      "path": "/exact/observed/path",
      "query": {
        "handle": ["public-handle"]
      },
      "status": 200
    }
  ]
}
```

From `packages/apis/solved_api`, run:

```sh
dart run tool/capture_public_contract.dart \
  --input /path/to/public.har \
  --plan /path/to/reviewed-plan.json \
  --output test/fixtures/public-capture
```

The output path must not exist. Files are staged beside the destination and
published as one directory only after every planned exchange has passed the
checks. Request query values are replaced with `<redacted>`, response fields
whose names look sensitive are redacted recursively, and credential-bearing or
structurally incomplete planned requests fail the whole capture.

Review `manifest.json` and every response fixture before committing them. A
capture is evidence of the observed public contract, not permission to call
private or state-changing endpoints.

## Compare two captures

Reuse the same operation `id` for the same semantic scenario in both reviewed
plans. Once both sanitized capture directories exist, compare their observed
request contracts and response shapes:

```sh
dart run tool/diff_public_contract.dart \
  --before test/fixtures/public-capture-v3 \
  --after test/fixtures/public-capture-v4
```

The command writes deterministic JSON to standard output. It reports added,
removed, and modified operation IDs; request paths, query parameter names and
arities, and statuses; and response field type or observed-presence changes.
It never emits response values, query values, local paths, or timestamps.

Response locations use JSON Pointer escaping (`~0` for `~` and `~1` for `/`)
with `*` as an array-item wildcard. A literal `*` object key is escaped as
`~2`. `required` and `optional` describe only the supplied capture samples;
they do not claim an upstream schema guarantee. An array with no observed
items has an explicit wildcard with `types: []` and `presence: "unobserved"`.
When either capture has that wildcard state, the diff reports the wildcard
transition but suppresses descendant changes that the empty sample cannot
prove. Array item counts and changes to scalar values are intentionally
ignored.

The diff accepts only directories produced by the capture workflow. It rejects
unknown files, symlinks, unredacted query values, malformed manifests, and
fixture references that do not exactly match their operation IDs.

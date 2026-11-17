# Public solved.ac contract capture

This tool converts a browser HAR into reviewable request metadata and JSON
response fixtures. A reviewed plan explicitly names every expected scenario;
the capture succeeds only when each planned public HTTPS `GET` exchange matches
exactly once.

Capture traffic in a signed-out private browser window and export the HAR with
response content. Never commit the raw HAR. The plan is part of the security
boundary, so review every path and query value and never put credentials or
private identifiers in it.

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
they do not claim an upstream schema guarantee. Array item counts and changes
to scalar values are intentionally ignored.

The diff accepts only directories produced by the capture workflow. It rejects
unknown files, symlinks, unredacted query values, malformed manifests, and
fixture references that do not exactly match their operation IDs.

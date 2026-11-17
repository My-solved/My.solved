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

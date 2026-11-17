# v4 contract fixtures

`official_openapi_contract.json` is a deterministic subset downloaded from the
official solved.ac OpenAPI document by
`tool/fetch_official_v4_contract.dart`.

The other JSON files are synthetic, schema-shaped decoder fixtures. Their field
names, required values, types, and nullability follow that pinned document, but
their example values are not captured production responses. Keep that
distinction explicit until credentialed proxy traffic can be captured and
reviewed safely.

# Changes, 8 October 2026

## Public-source link fix

The public source declared two NuRpcService methods but did not define them. A clean build reached the final link and failed with unresolved symbols on any platform. Existing binaries were unaffected.

The fix restores `cacheExplorerLookup` and `explorerLookupHtml`. Explorer lookups can again be saved to SQLite and formatted for display. SQL values are bound; the title and source JSON are HTML-escaped.

The focused regression harness compiles these method bodies from the source file and uses a temporary database. It checks inserts, upserts, separate lookup types, Unicode and quoted identifiers, HTML escaping, connection cleanup, and failed writes. It does not replace an application launch test.

## Writing

New prose follows `writing-style.md`, which combines the four owner-supplied guides. Existing release history and dated notes remain unchanged.

Build and deployment results are recorded in the operations handoff after verification. This entry does not claim an upstream merge or a new public binary release.

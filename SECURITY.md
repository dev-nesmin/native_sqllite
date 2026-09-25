# Security Policy

## Supported versions

native_sqlite has not published its first stable release. Until then, security
fixes are made on the `main` branch. After publication, this file will list the
supported release lines.

## Reporting a vulnerability

Please report vulnerabilities privately with GitHub's **Security → Report a
vulnerability** flow for this repository. Do not open a public issue before a
fix and disclosure plan are agreed.

Include the affected package and platform, package and Flutter versions,
impact, reproduction steps, and a minimal proof of concept. Remove secrets and
personal data from logs or database samples. The maintainers will acknowledge
the report, investigate it, and coordinate remediation and disclosure through
the private advisory.

## Inspector-specific guidance

The bundled database inspector is a debug-only DevTools extension. A report
about it should never include a live VM-service URI, authentication token, or
real application database. Reproduce with synthetic data and state whether
the issue crosses the expected local-debug boundary.

Applications must not enable debug service extensions or expose the Dart VM
service in production. Treat database contents, SQL parameters, filesystem
paths, and exported database files as sensitive.

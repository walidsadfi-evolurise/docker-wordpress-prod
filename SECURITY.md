# Security

Report vulnerabilities in this stack's configuration to walid.sadfi@evolurise.com rather than in a public issue. Expect an answer within 5 working days.

Known boundaries: this is a single-host stack; the backup container holds S3 credentials (scope them to one bucket); WordPress and plugin updates remain your responsibility (`make wp ARGS="plugin update --all"`).

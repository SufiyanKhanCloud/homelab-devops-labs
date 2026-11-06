# Security Policy

## Scope

This repository contains documentation, configuration examples, and sanitized implementation details from a personal learning homelab.

It is intended for educational purposes and is not a production security baseline.

## Reporting a Security Concern

If you discover a security issue in this repository, please report it privately to the repository owner rather than publishing sensitive details in a public issue.

Include a brief description of the affected file or component and steps to reproduce the issue where possible.

Avoid sharing credentials, private keys, personal information, or other sensitive data in the report.

## Sensitive Information

This repository must not contain:

- Passwords, API tokens, or authentication secrets.
- SSH private keys or Tailscale authentication keys.
- Database backups containing real data.
- Environment files containing credentials.
- Personal information or unnecessary infrastructure identifiers.
- Internal IP addresses, private hostnames, or account identifiers.
- Raw logs, terminal output, or screenshots that expose sensitive information.

## Git History and Public Contributions

Sensitive information must not be committed, even temporarily.

Before committing or pushing changes:

- Review modified files and the complete diff.
- Check for accidentally included credentials and private infrastructure details.
- Review screenshots, logs, and configuration examples before publication.
- Use placeholders for environment-specific values.

If sensitive information is accidentally exposed, remove it from the repository and Git history where appropriate, and rotate or revoke affected credentials. Removing a secret from the latest commit does not guarantee that it has been removed from public Git history or existing clones.

## Lab Safety

Experiments are performed on infrastructure controlled by the author or systems for which explicit authorization has been granted.

Commands and configurations are reviewed before being shared publicly. Destructive operations are treated carefully, particularly those involving persistent database volumes and backups.

## Limitations

This policy does not mean that the homelab is production infrastructure or that every configuration is suitable for production use.

Experiments, limitations, historical test results, and unverified assumptions are documented honestly. Security findings should not be treated as current assessments unless they have been verified against the relevant current implementation.

# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in SwiftMusicNotation, please report it responsibly:

1. **Do not** open a public GitHub issue for security vulnerabilities
2. Email the maintainers directly or use GitHub's private vulnerability reporting
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Any suggested fixes (optional)

## Security Considerations

SwiftMusicNotation processes external data (MusicXML files, fonts) and implements several security measures:

### MusicXML Import
- Path traversal protection for MXL archive extraction
- Bounds checking on numeric values to prevent DoS
- XML parsing uses Foundation's XMLParser (no external entity resolution by default)

### Font Loading
- Font name validation to prevent path injection
- File size limits on metadata files (10 MB max)

### Best Practices for Users
- Validate MusicXML files from untrusted sources before processing
- Use sandboxed environments when processing user-uploaded files
- Keep SwiftMusicNotation updated to receive security fixes

## Response Timeline

- **Acknowledgment**: Within 48 hours
- **Initial Assessment**: Within 1 week
- **Fix Timeline**: Depends on severity, typically 1-4 weeks
- **Disclosure**: Coordinated with reporter after fix is released

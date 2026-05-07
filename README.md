# 403 Bypass Automation

Advanced 403/401 bypass testing and differential analysis tool designed for security researchers, penetration testers, and red team operations.

This tool automates common path normalization, header-based access control bypass, and HTTP method manipulation techniques used to identify misconfigured reverse proxies, WAFs, CDN rules, and backend authorization inconsistencies.

## Features

* Path normalization bypass testing
* Header-based access control bypass checks
* Multiple HTTP method testing
* Differential response analysis
* WordPress-specific endpoint discovery
* WAF fingerprint detection
* Wayback Machine integration
* Colored terminal output
* Redirect detection
* Lightweight Bash implementation

## Supported Techniques

* `X-Original-URL`
* `X-Rewrite-URL`
* `X-Forwarded-For`
* Path traversal normalization
* Encoded path bypasses
* HTTP verb tampering
* Reverse proxy trust abuse
* IIS/nginx rewrite inconsistencies

## Usage

```bash
chmod +x bypass.sh
./bypass.sh https://target.com/admin
```

## Example

```bash
./bypass.sh https://example.com/wp-admin
```

## Disclaimer

This tool is intended for authorized security testing, research, and educational purposes only. Users are responsible for ensuring they have proper authorization before testing any target systems.

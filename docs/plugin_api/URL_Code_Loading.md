# URL-Based Code Loading

A Makerchip IDE link can provide initial code. This is useful for providing "Open in Makerchip" links in third-party websites or GitHub README.md files.

## Hash Parameters

**Recommended approach** - hash parameters are never sent to the server:

```
https://makerchip.com/ide#code_url=https://example.com/code.tlv
https://makerchip.com/ide#code=<base64url-encoded-code>
https://makerchip.com/ide#code_url=https://example.com/code.tlv&read_only=true
```

## Parameters

- **`code_url`** - URL to fetch code from (requires CORS: `Access-Control-Allow-Origin: *`)
- **`code`** - Base64url-encoded inline code (replace `+/=` with `-_` and strip padding)
- **`read_only`** - Set to `true` to disable editing (default: editable, no storage)

## JavaScript Helper

```javascript
function encodeBase64Url(str) {
  const bytes = new TextEncoder().encode(str);
  const binary = String.fromCharCode(...bytes);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

const url = `https://makerchip.com/ide#code=${encodeBase64Url(tlvCode)}`;
```

## Behavior

- Hash fragments are automatically cleared after loading
- Code loaded via URL is editable by default (unless `read_only=true`)
- No server storage - refreshing the page returns to default code

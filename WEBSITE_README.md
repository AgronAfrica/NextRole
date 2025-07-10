# NextRole Website

This repository contains the support website for the NextRole iOS app.

## Pages

- **Support**: `support.html` - Main support page with FAQ and contact information
- **Privacy Policy**: `privacy.html` - Privacy policy for the NextRole app
- **Terms of Service**: `terms.html` - Terms of service for the NextRole app

## Setup for GitHub Pages

1. Push this repository to GitHub
2. Go to repository Settings > Pages
3. Select "Deploy from a branch"
4. Choose "main" branch and "/ (root)" folder
5. Click "Save"

Your website will be available at: `https://[username].github.io/[repository-name]`

## URLs for App Store

Update your App Store Connect metadata with these URLs:

- **Support URL**: `https://[username].github.io/[repository-name]/support.html`
- **Privacy Policy**: `https://[username].github.io/[repository-name]/privacy.html`
- **Terms of Service**: `https://[username].github.io/[repository-name]/terms.html`

## Custom Domain (Optional)

To use a custom domain like `nextrole.app`:

1. Purchase the domain
2. Add a CNAME record pointing to `[username].github.io`
3. In GitHub repository Settings > Pages, add your custom domain
4. Update the URLs in your app to use the custom domain

## Local Development

To test locally, simply open the HTML files in a web browser or use a local server:

```bash
python -m http.server 8000
```

Then visit `http://localhost:8000` 
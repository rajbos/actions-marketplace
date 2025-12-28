# Contributing to Actions Marketplace

Thank you for your interest in contributing to the Actions Marketplace project!

## Development Guidelines

### Adding New Static Pages

When adding new static HTML pages or JavaScript files to the marketplace:

1. **Create your HTML/JS files** in the root directory (e.g., `detail.html`, `detail.js`)

2. **Update the sync workflow** (`.github/workflows/sync-to-gh-pages.yml`):
   - Add the new files to the `paths` trigger section
   - Add copy commands for the new files in the "Copy static files to gh-pages" step
   - Add cache-busting sed commands for CSS/JS references in the new HTML files
   - Add deployment metadata injection for the new HTML files (both perl and sed commands)

3. **Cache Busting**: Ensure all CSS and JavaScript references in HTML files use version parameters:
   ```html
   <link rel="stylesheet" href="style.css?v=20251221">
   <script src="script.js?v=20251221"></script>
   ```
   These will be automatically updated by the workflow with timestamps.

### Example: Adding a New Page

If you add `newpage.html` and `newpage.js`:

1. In `.github/workflows/sync-to-gh-pages.yml`, update the paths:
```yaml
paths:
  - 'index.html'
  - 'detail.html'
  - 'newpage.html'  # Add this
  - 'script.js'
  - 'detail.js'
  - 'newpage.js'  # Add this
  - 'style.css'
```

2. Add copy commands:
```bash
cp newpage.html gh-pages-branch/
cp newpage.js gh-pages-branch/
```

3. Add cache-busting:
```bash
sed -i "s/\(style\.css?v=\)[^\"]*/\1${TIMESTAMP}/" gh-pages-branch/newpage.html
sed -i "s/\(newpage\.js?v=\)[^\"]*/\1${TIMESTAMP}/" gh-pages-branch/newpage.html
```

4. Add deployment metadata:
```bash
perl -i -pe 's#</html>#<!-- Deployed from branch: '"$DEPLOY_BRANCH"', commit: '"$DEPLOY_COMMIT"', date: '"$DEPLOY_DATE"' --></html>#' gh-pages-branch/newpage.html
sed -i "s|.*DEPLOYMENT_INFO_PLACEHOLDER.*|                Deployed from <strong>${DEPLOY_BRANCH}</strong> branch on <strong>${DEPLOY_DATE}</strong>|" gh-pages-branch/newpage.html
```

## Testing

When making UI changes:
1. Test locally using a simple HTTP server (e.g., `python3 -m http.server`)
2. Create a test `actions-data.json` file with sample data
3. Verify all links, navigation, and functionality work correctly
4. Test error states and edge cases

## Code Style

- Keep JavaScript consistent with existing code style
- Use the existing design system and CSS patterns
- Maintain consistent naming conventions
- Add comments only when necessary to explain complex logic

## Submitting Changes

1. Create a feature branch from `main`
2. Make your changes following these guidelines
3. Test thoroughly
4. Submit a pull request with a clear description of changes
5. Include screenshots of any UI changes

# Configuration Files

This directory contains build configuration files for different environments.

## Setup for New Developers

1. **Copy the example file:**
   ```bash
   cp Local.xcconfig.example Local.xcconfig
   ```

2. **Edit `Local.xcconfig`:**
   - Replace `YOUR_TEAM_ID_HERE` with your Apple Developer Team ID
   - Find your Team ID at: [developer.apple.com/account](https://developer.apple.com/account) → Membership → Team ID

3. **Optional:** Override `BASE_URL` in `Local.xcconfig` for local backend development

## Configuration Files

- **`AMI-staging.xcconfig`** - Staging environment (tracked in git)
- **`AMI-prod.xcconfig`** - Production environment (tracked in git)
- **`Local.xcconfig`** - Personal settings (NOT tracked in git)
- **`Local.xcconfig.example`** - Template for Local.xcconfig (tracked in git)

## Environment Settings

### Staging
- Bundle ID: `fr.gouv.ami.staging`
- Backend: `https://ami-back-staging.osc-fr1.scalingo.io`
- Firebase: `GoogleService-Info-Staging.plist`

### Production
- Bundle ID: `fr.gouv.ami`
- Backend: `https://ami-back-prod.osc-secnum-fr1.scalingo.io`
- Firebase: `GoogleService-Info-Prod.plist`

## Important Notes

- **Never commit `Local.xcconfig`** - it contains personal Team IDs
- Both staging and production configs include `Local.xcconfig` via `#include`
- All developers need their own `Local.xcconfig` with their Team ID

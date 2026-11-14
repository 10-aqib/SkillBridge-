# Maps integration checklist

## Configuration and security

- [x] Load the Google Maps key from ignored local configuration instead of committing it in iOS source.
- [x] Android manifest reads the key through Gradle configuration.
- [x] Keep the local iOS key file out of version control; use `ios/Flutter/GoogleMaps.local.xcconfig.example` as the setup reference.
- [ ] Rotate any key that was previously committed, then restrict it by Android package/signing certificate and iOS bundle ID.
- [ ] Restrict each key to the Maps SDK and REST APIs the app uses; use separate platform keys where Google Cloud supports the restriction.
- [ ] Keep the REST key in the ignored root `.env` and ensure the deployment/build process supplies it securely.

## Map features and data

- [x] Location picker map and nearby-worker map use the shared Google Maps Flutter plugin.
- [x] Worker/job coordinates are represented as validated geographic points and nearby-worker discovery uses location data.
- [x] Address lookup and place search return a safe empty result when the Maps service is unavailable.
- [ ] Verify Android and iOS builds with locally configured keys on physical devices.
- [ ] Verify location permission denied, permission permanently denied, and location services disabled states.
- [ ] Verify maps remain usable when GPS is unavailable by allowing manual pin placement and address confirmation.
- [ ] Verify offline and poor-network states explain that map tiles/search may be unavailable while preserving the last selected coordinates.
- [ ] Verify route/tracking screens handle missing, stale, and private worker locations without exposing exact coordinates to unauthorized users.

## Regression checks

- [ ] Open the location picker, move the pin, search for a place, and confirm the returned address and coordinates.
- [ ] Open nearby workers in map and list modes; check pins and selected worker details match.
- [ ] Check live tracking updates, camera movement, and navigation launch for a booked job.
- [ ] Confirm no API key appears in tracked source, build logs, or error messages.

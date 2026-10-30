# NeighbourConnect

## Use the app offline on an Android phone

The app stores accounts, neighbourhoods, posts, comments, likes, events, and
issues in a SQLite database on the phone. It does not need Wi-Fi, the laptop,
or the Node.js/MySQL backend to log in or use these features. Post images are
also copied into the phone's app storage.

Build the APK from the project folder:

```powershell
flutter build apk --release
```

Install `build\app\outputs\flutter-apk\app-release.apk` on the phone. Create an
account in the app, then log in with that account on the same phone.

### Offline data

- Local accounts and app activity are stored only on this phone.
- They are separate from the laptop's MySQL database and do not sync to it or
  to other phones.
- Reinstalling or clearing the app's storage may erase its local data. Export
  or back up the app database before doing either.
- Images entered as online URLs are not available offline; choose an image
  file from the phone to store it locally.
- The account registered with `divya@gmail.com` is the only administrator:
  the Super Admin. It can view neighbours, meetings, and communities across the
  device database. There is no admin approval step: neighbours can use the app
  immediately after registering and logging in.
- The app does not verify ownership of email addresses; use a hosted
  authentication service before relying on email-based admin identity in a
  shared or production deployment.
- Admin data is local to the device and is not shared with other phones.

### Registration and access

1. A new member registers with a neighbourhood choice.
2. The member logs in and can immediately use the community features.
3. The Super Admin can view registered neighbours, communities, and meetings
   from the local database. Existing installations are migrated to allow access
   without waiting for approval.

The backend folder remains available for a future hosted/shared-data setup, but
the Flutter app's current screens use the on-device database.

# portifolio

## Local backend setup for Windows + phone

This project uses a Node.js backend on port 3000. The Flutter app must point to the machine running the backend.

### 1) Start the backend on your Windows laptop

```bash
cd backend
npm install
node server.js
```

The server listens on `0.0.0.0:3000`, so it is reachable from the local network.

### 2) Find your laptop IP address

On Windows PowerShell:

```powershell
ipconfig
```

Look for the IPv4 address under your Wi-Fi or Ethernet adapter, for example:

```text
192.168.1.50
```

### 3) Launch the app

On the same Windows computer as the backend, the app uses
`http://localhost:3000` by default:

```bash
flutter run
```

For an Android emulator, the app uses `http://10.0.2.2:3000` by default.

For a real phone connected to the same Wi-Fi, pass your laptop's current
IPv4 address:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:3000
```

If you change the backend IP or machine, update the `API_BASE_URL` value and rerun the app.

### 4) If the app still shows a connection error

- Make sure the backend is still running with `node server.js`
- Confirm the Windows firewall allows connections on port 3000
- Confirm the phone and laptop are on the same Wi-Fi network
- Make sure the URL matches the actual IP shown by `ipconfig`
- For desktop, make sure the backend and Flutter app are running on the same computer

## Use the phone app without keeping the laptop on

The API and MySQL database must be hosted online; a phone cannot reach a backend
that is only running on your laptop. One option is deploying both services on
Railway:

1. Push this project to a private GitHub repository. In Railway, create a
   project from that repository and set the backend service root directory to
   `/portifolio/backend`. The included `backend/Dockerfile` builds the API.
2. Add a MySQL service. In the backend service's Variables settings, provide
   `DB_HOST`, `DB_USER`, `DB_PASSWORD`, and `DB_NAME` using the connection
   values shown for the MySQL service. Railway supplies `PORT`.
3. Export your existing `neighbourconnect` database and import it into the
   hosted MySQL database. This repository does not include a database schema or
   migrations, so login will not work until the existing tables are migrated.
   Do not paste database passwords into chat or commit them to the repository.
4. Generate a public HTTPS domain for the backend service. Add a persistent
   volume mounted at `/data` and set `UPLOADS_DIR=/data/uploads` if uploaded
   post images need to persist across deployments.
5. Test `https://YOUR-BACKEND-DOMAIN/api/test` in a browser. It should return
   JSON with `"success": true` once the database is connected.
6. Build the phone app with the public backend URL:

   ```powershell
   flutter build apk --release --dart-define=API_BASE_URL=https://YOUR-BACKEND-DOMAIN
   ```

   Install `build\app\outputs\flutter-apk\app-release.apk` on your phone. The
   backend and database will then run online without your laptop; rebuilding
   the app is only necessary if the public API URL changes.

Never commit your real `.env` file or database credentials. Use the hosting
provider's secret/environment-variable settings instead. If any real database
password was committed to Git, change it before deploying.

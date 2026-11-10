# Library Management System

A Flutter web client with a Node.js/Express API and PostgreSQL database.

## Run locally

1. Install Flutter and Node.js.
2. Create a PostgreSQL database and apply [`database/schema.sql`](./database/schema.sql).
3. Copy `.env.example` to `.env`, set `DATABASE_URL`, and replace `JWT_SECRET` with a random value of at least 32 characters.
4. Start the API with `npm ci` and `npm run dev`.
5. In `library_management_app`, run `flutter pub get` and `flutter run -d chrome`.

The Flutter client defaults to `http://127.0.0.1:10000` for local development.

No demo account is seeded, and the current login screen has no sign-up flow. Create a student account by sending `POST /auth/register` with `name`, `email`, and `password`; grant an admin role only through a trusted database operation.

## Deploy the API

The root [`render.yaml`](./render.yaml) describes a Render web service. Create a hosted PostgreSQL database, apply `database/schema.sql`, then set these service environment variables:

If you prefer to host the API on Vercel instead of Render, the repository includes a TypeScript serverless entrypoint at [`api/index.ts`](./api/index.ts) and a root [`vercel.json`](./vercel.json). The entrypoint imports the Express app directly, so deployment does not depend on the locally generated `dist/` directory. Configure `DATABASE_URL`, `JWT_SECRET`, and `CORS_ORIGIN` in the Vercel project settings.

- `DATABASE_URL`: the database connection URL.
- `JWT_SECRET`: a private random secret of at least 32 characters (Render can generate it).
- `CORS_ORIGIN`: the exact Vercel frontend origin, such as `https://your-project.vercel.app`.

Render builds with `npm ci --include=dev && npm run build` and starts with `npm start`. The API root (`/`) returns service status, and the health endpoint is `/health`.
If the Vercel URL is not known when the API is first deployed, set `CORS_ORIGIN` to the final URL and redeploy the API after the first Vercel deployment.

## Deploy the Flutter web client to Vercel

1. Create a Vercel project from this repository and set its **Root Directory** to `library_management_app`.
2. Use the included `vercel.json` configuration and set the Vercel environment variable `API_BASE_URL` to the deployed API origin (HTTPS, with no trailing slash).
3. Deploy. The build script installs Flutter 3.38.9 if the build environment does not already provide it, then publishes `build/web`.

For a local production build, run from `library_management_app`:

```sh
flutter build web --release --dart-define=API_BASE_URL=https://your-api.example.com
```

The client API URL is compiled into the static web build. Rebuild and redeploy after changing `API_BASE_URL`.

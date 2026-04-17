# Amplify Gen 2 Playbook — Daxwell SCM repo

This playbook captures the non-obvious invariants of how AWS Amplify Gen 2 is wired into this repo, and the exact fix for each class of error the setup produces. Every rule here has a real incident behind it — do not second-guess them.

## 1. Mental model

- `amplify/` lives at the repo root but is **not** a pnpm workspace member. The root `pnpm-workspace.yaml` only lists `apps/*` and `packages/*`. Amplify is a **standalone sub-project** inside the repo.
- Amplify CLI (`ampx`) is installed into `amplify/node_modules/.bin/`, not the root.
- `ampx` expects to be invoked from the parent of `amplify/` (i.e., the repo root). It reads `./amplify/backend.ts` relative to its CWD. Running it from inside `amplify/` breaks with `[PathNotFoundError] ./amplify does not exist`.
- Root TypeScript and ESLint configs explicitly exclude `amplify/**`. The amplify folder has its own `tsconfig.json` (with `moduleResolution: Bundler`, `types: ["node", "aws-lambda"]`).
- Next.js hosting (`apps/scm/amplify.yml`) is a separate Amplify app from this Gen 2 backend. They do not share state.

## 2. Required files in `amplify/`

These three files together isolate amplify from the root workspace. If any is missing, the install and/or sandbox will fail in a specific way (see §6 symptom table).

### `amplify/pnpm-workspace.yaml`
```yaml
packages: []
```
Declares amplify as its own workspace root so pnpm stops walking up to the repo root. Without it, `pnpm install` inside `amplify/` sees `Scope: all 15 workspace projects` and installs nothing for amplify.

### `amplify/.npmrc`
```
strict-dep-builds=false
node-linker=hoisted
```
- `strict-dep-builds=false`: root sets `strictDepBuilds: true`; this folder needs `esbuild`, `@parcel/watcher`, `core-js` to run build scripts.
- `node-linker=hoisted`: `open` (a transitive dep of `ampx`) requires npm-style flat resolution to find `is-inside-container` and other siblings. pnpm's default symlinked layout breaks it.

### `amplify/package.json` (partial)
```json
{
  "pnpm": {
    "onlyBuiltDependencies": ["@parcel/watcher", "core-js", "esbuild"]
  }
}
```
Even with `strict-dep-builds=false`, be explicit about which deps are trusted to run build scripts.

## 3. Root-level plumbing

### `package.json` scripts
```
"amplify:install":          "cd amplify && pnpm install"
"amplify:sandbox":          "npm_config_user_agent=pnpm ./amplify/node_modules/.bin/ampx sandbox"
"amplify:sandbox:delete":   "npm_config_user_agent=pnpm ./amplify/node_modules/.bin/ampx sandbox delete"
"amplify:generate:outputs": "npm_config_user_agent=pnpm ./amplify/node_modules/.bin/ampx generate outputs"
```

**Never** use `cd amplify && pnpm exec ampx ...` — the CWD ends up inside `amplify/`, and `ampx` looks for `amplify/amplify/backend.ts`.

**Never** run `ampx` without `npm_config_user_agent` set — `@aws-amplify/cli-core` throws `NoPackageManagerError: npm_config_user_agent environment variable is undefined`.

### `Makefile` targets
```
amplify-install, amplify-sandbox, amplify-sandbox-delete, amplify-reset, clean-amplify
```
`make amplify-reset` = `clean-amplify` + `amplify-install`. Use it as the one-shot recovery for any install-state rot.

### `.gitignore`
```
amplify_outputs.json
amplify_outputs.*.json
.amplify/
amplify/.amplify/
```
(`node_modules/` is already covered globally.)

### Root `tsconfig.json` — must exclude
```
"amplify", "**/.amplify"
```

### Root `eslint.config.mjs` — must ignore
```
'amplify/**', '**/.amplify/**'
```

## 4. Function authoring pattern

```
amplify/functions/<name>/
  resource.ts    defineFunction(...)
  handler.ts     actual Lambda code
```

### Runtime default: Node 20.

`defineFunction` does **not** support setting `InvokeMode.RESPONSE_STREAM`, VPC config, EventSources, or advanced IAM. Those go in `backend.ts` via CDK extensions:

```ts
const backend = defineBackend({ myFn });
const lambda = backend.myFn.resources.lambda;
lambda.addFunctionUrl({ authType, invokeMode, cors });
```

### Env vars
Non-secrets: pass via `defineFunction({ environment: { FOO: process.env.FOO ?? '' } })` and export them in the shell before running `ampx sandbox`. Secrets: `secret('FOO')` + `pnpm --dir amplify exec ampx sandbox secret set FOO`.

Fail-fast: read required env at module load time (cold start), not per-invocation. Missing env should explode the Lambda init, not silently fail auth.

### Auth patterns (pick one, never mix)

- **Auth0 JWT in-handler**: `jose.createRemoteJWKSet` + `jwtVerify`. Function URL `authType: NONE`. Verify `issuer: https://<domain>/`, `audience: <your api identifier>`.
- **Cognito**: rely on Amplify's `defineAuth` and let Amplify wire the authorizer.
- **AWS_IAM**: for server-to-server only. Browser clients can't sign SigV4 with Auth0 tokens.

### Response streaming

Pair these two — one without the other is a bug:

1. **Function URL**: `InvokeMode.RESPONSE_STREAM` (via CDK in `backend.ts`)
2. **Handler**: wrap with `awslambda.streamifyResponse(async (event, responseStream) => {...})`

Set status/headers via `awslambda.HttpResponseStream.from(responseStream, { statusCode, headers })`. For upstream SSE passthrough, read `upstream.body` with `getReader()` and write the raw bytes to the response stream — do not re-parse.

## 5. Frontend wiring

- `ampx sandbox` writes `amplify_outputs.json` at repo root.
- Custom outputs live under `custom.<key>` (e.g., `custom.daxbotReadstreamUrl`).
- The SCM app consumes these via `NEXT_PUBLIC_*` env vars in `apps/scm/.env.local`. Do not hardcode URLs in source.
- Document every new output in `amplify/README.md` (what it is, how the frontend reads it) and in `apps/scm/.env.example` (placeholder line).

## 6. Symptom → fix table

| Symptom | Root cause | Fix |
| --- | --- | --- |
| `Command "ampx" not found` when running `pnpm amplify:sandbox` | `amplify/node_modules/` not installed, or installed with wrong scope | `make amplify-install` (or `make amplify-reset` if stale) |
| `pnpm install` inside `amplify/` prints `Scope: all 15 workspace projects` and installs nothing | `amplify/pnpm-workspace.yaml` is missing; pnpm walked up to the root workspace | Create `amplify/pnpm-workspace.yaml` with `packages: []` |
| `ERR_PNPM_IGNORED_BUILDS — Ignored build scripts: @parcel/watcher, esbuild, core-js` | Root `pnpm-workspace.yaml` has `strictDepBuilds: true`; amplify is inheriting it | Add `strict-dep-builds=false` to `amplify/.npmrc` AND declare them in `amplify/package.json`'s `pnpm.onlyBuiltDependencies` |
| `Cannot find package 'is-inside-container' imported from .../open/index.js` | pnpm symlinked layout breaks `open`'s flat-lookup assumption | Add `node-linker=hoisted` to `amplify/.npmrc`, then `make amplify-reset` |
| `[PathNotFoundError] ./amplify does not exist. Make sure you are running from project root` | `ampx` ran from inside `amplify/` (the `cd amplify && pnpm exec ampx` pattern) | Change script to `npm_config_user_agent=pnpm ./amplify/node_modules/.bin/ampx <cmd>` (run from repo root) |
| `AmplifyError [NoPackageManagerError]: npm_config_user_agent environment variable is undefined` | Called the `ampx` binary directly without pnpm/npm/yarn setting the user agent | Prepend `npm_config_user_agent=pnpm` to the command |
| `Cannot find module '@aws-amplify/backend'` in IDE for `amplify/backend.ts` | Root tsconfig owns the file; `amplify/tsconfig.json` isn't active | Verify root `tsconfig.json` has `amplify` in `exclude`; reload TS server |
| `Cannot find namespace 'awslambda'` in handler.ts | `@types/aws-lambda` global not loaded — wrong tsconfig owns the file | Same fix as above; verify `amplify/tsconfig.json` has `"types": ["node", "aws-lambda"]` |
| Lambda returns 401 `unauthorized` | Token audience/issuer mismatch; or frontend didn't request an access token (only ID token) | Verify `AUTH0_AUDIENCE` env matches the API identifier; frontend must call `getAccessTokenSilently({ audience })` |
| Lambda returns 502 `upstream_unreachable` | `DAXBOT_API_URL` points at `localhost` or a VPC-internal host | Use a public URL, or attach the Lambda to the VPC via CDK (`addSecurityGroup` + `addVpcConfig`) |
| CDK `ROLLBACK_COMPLETE` / stuck stack | Prior sandbox failed mid-deploy | `make amplify-sandbox-delete` (with user's explicit OK), then `make amplify-sandbox` |
| `amplify_outputs.json` not regenerating after change to `backend.ts` | Sandbox didn't pick up the file change | Check sandbox watcher is running; if not, `ampx sandbox --once` to force a single deploy |
| `TS2345: Argument of type 'X' is not assignable to parameter of type 'Record<string, unknown>'. Index signature for type 'string' is missing in type 'X'` during `ampx sandbox` | Interface passed where a method's param is typed `Record<string, unknown>` — interfaces don't auto-acquire an index signature | Convert the interface to an intersection type: `type X = { ... } & Record<string, unknown>`. Affects `awslambda.HttpResponseStream.from(stream, meta)` in particular |
| TypeScript errors surface only during `ampx sandbox`, not in the IDE | IDE is using a cached/stale TS project state for the amplify folder | Run `ampx sandbox --once` as the authoritative TS check for amplify code. IDE diagnostics in `amplify/**` are best-effort, not definitive |
| `[esbuild] Could not resolve "aws-lambda"` during `ampx sandbox [deploy|delete]` | A bare `import 'aws-lambda'` (or any `@types/*` package) was added as a runtime side-effect import. `@types/*` packages have no runtime JS; esbuild can't bundle them | Replace with `/// <reference types="aws-lambda" />` (with inline `// eslint-disable-next-line @typescript-eslint/triple-slash-reference`). Use `import type { ... } from 'aws-lambda'` only for named types. Never side-effect-import a types-only package |
| `[MultipleSandboxInstancesError] Other CLIs (PID=<N>) are currently reading from .../.amplify/artifacts/cdk.out` | Another `ampx sandbox` process is holding the lock (duplicate invocation) OR a prior sandbox crashed without releasing it | Check with `ps -p <N> -o pid,ppid,etime,command`. If the process is a legitimate running watcher, leave it alone and use that terminal. If it's orphaned/stale: `kill <N>` then `rm -rf .amplify/artifacts/cdk.out` then `make amplify-sandbox`. Never run two `ampx sandbox` sessions against the same project at the same time |

## 7. Reset-to-green procedure

When in doubt, don't debug the install state — reset it:

```bash
make amplify-reset       # purges amplify/node_modules, lockfile, .amplify, amplify_outputs.json; reinstalls
make amplify-sandbox     # re-deploys
```

Never do this at the repo root — nuking root `node_modules/` kills the 15 workspace projects and forces a full monorepo reinstall.

## 8. Verification before declaring done

For any amplify change, run the verification that proves the change works:

- **Install**: `ls amplify/node_modules/.bin/ampx` exists, and `npm_config_user_agent=pnpm ./amplify/node_modules/.bin/ampx --version` prints a version.
- **Scaffold / new function**: `ampx sandbox --once` completes with "✔ Total time" and `amplify_outputs.json` contains the expected keys.
- **Streaming lambda**: curl with `-N` (no buffering) against the Function URL with a real Auth0 access token shows SSE frames arriving incrementally, not in one batch.
- **CORS**: curl with `-X OPTIONS -H "Origin: <allowed>" -H "Access-Control-Request-Method: POST"` returns 204 with `Access-Control-Allow-Origin`.
- **Auth**: a request without `Authorization` returns 401 with `{"error":"unauthorized",...}` JSON (not an HTML error page).

Only after the relevant check passes, tell the user the task is done.

## 9. What NOT to do

- Don't add `amplify` to `pnpm-workspace.yaml` at the repo root. It pulls amplify into the shared install with the root's supply-chain rules and breaks.
- Don't run `pnpm install` at the repo root to "refresh" amplify deps. It has no effect on `amplify/node_modules`.
- Don't `rm -rf node_modules` at the repo root to fix an amplify issue. Scope cleanup to `amplify/`.
- Don't move the amplify deps into the root `package.json` "for simplicity". The root's pnpm supply-chain config is incompatible with Amplify's CLI deps.
- Don't change amplify's `module` / `moduleResolution` back to `NodeNext`. The Bundler setting is what lets us import `./foo/bar` without `.js` extensions, which CDK code does throughout.
- Don't put secrets in `defineFunction({ environment })`. They end up in CloudFormation in plaintext. Use `secret('NAME')`.
- Don't use `refetchQueries` or any Apollo pattern in the Lambda handler. Lambdas are stateless; all state is on the caller side.

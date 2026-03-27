Analyse the codebase in the current working directory and create or update `catalog-info.yaml` for Backstage.

## Phase 1 — Read existing state

- Read `catalog-info.yaml` if it exists. Record all manually set values, especially `spec.owner`, `spec.system`, `spec.lifecycle`, `metadata.description`, and any `metadata.annotations` beyond `github.com/project-slug`.
- Run `git remote get-url origin` to get the GitHub slug (e.g. `org/repo`).
- Run `gh repo view --json visibility -q .visibility` to get the repository visibility. Convert the value to lowercase (e.g. `PUBLIC` → `public`, `INTERNAL` → `internal`, `PRIVATE` → `private`). If the command fails, skip this tag silently.

## Phase 2 — Discover component roots

Find every directory that contains a build file (`build.gradle.kts`, `build.gradle`, `pom.xml`, `package.json`, `pyproject.toml`). Each such directory is a component candidate. The repo root itself counts if it has a build file.

For each component root, collect:

**Name** — from the build file in this priority order:
1. `rootProject.name` or subproject name in `settings.gradle.kts` / `settings.gradle`
2. `artifactId` in `pom.xml`
3. `name` field in `package.json`
4. Directory name as fallback

**Type** — apply these rules:
- `plugin` if the name or `package.json` keywords contain "backstage-plugin", or if there is a `src/components` directory alongside a `package.json` with `@backstage/` dependencies
- `website` if `package.json` dependencies include a frontend framework (`react`, `vue`, `angular`, `next`, `vite`) and there is no server-side entrypoint
- `library` if there is no main application entrypoint (no `main` method / `main.ts` / `index.ts` exporting a server, no Spring Boot `@SpringBootApplication`, no `Application.kt`)
- `service` otherwise

**Language / framework tags** — detect from build files and imports:
- `kotlin`, `java`, `typescript`, `javascript`, `python`
- `spring-boot` (presence of `spring-boot` dependency), `ktor`, `express`, `fastapi`, `nestjs`
- `gradle`, `maven`, `npm`, `yarn`
- Repository visibility tag detected in Phase 1: `public`, `internal`, or `private`

## Phase 3 — Discover APIs

For each component root, look for APIs in this order. Stop at the first hit per API type.

### Provided APIs

1. **OpenAPI / Swagger spec file** — look for `openapi.yaml`, `openapi.json`, `swagger.yaml`, `swagger.json`, `**/openapi/**/*.yaml`, `**/openapi/**/*.json`. If found, record `type: openapi` and the file path.
2. **Proto files** — look for `**/*.proto`. If found, record `type: grpc` and extract service names.
3. **GraphQL schema** — look for `**/*.graphql`, `**/schema.graphql`, `**/schema.ts` with `gql` template literals. If found, record `type: graphql`.
4. **Infer from source** — if none of the above are found but the component type is `service`:
   - **Spring / Ktor (Kotlin/Java)**: scan for `@RestController`, `@GetMapping`, `@PostMapping`, `@PutMapping`, `@DeleteMapping`, `@PatchMapping`, `@RequestMapping`, or Ktor `routing { }` blocks. Extract HTTP method, path, and any `@Operation` / `@Tag` Swagger annotations.
   - **Express / Fastify / NestJS (TypeScript/JS)**: scan for `router.get(`, `app.post(`, `@Controller`, `@Get`, `@Post` decorators.
   - **FastAPI (Python)**: scan for `@app.get(`, `@router.post(`, etc.
   - From the collected routes, synthesise a minimal OpenAPI 3.0 definition (paths only, no request/response schemas unless annotations provide them). Mark the definition with a comment `# Inferred from source — replace with a generated spec for accuracy`.
   - Record `type: openapi` with the inline definition.

### Consumed APIs

- Scan `application.yml`, `application.properties`, `application.conf`, `.env*`, `docker-compose*.yml` for service URL patterns (`http://`, `grpc://`, or keys ending in `-url`, `-host`, `-endpoint`). Extract service names from hostnames where possible.
- Scan source files for HTTP client declarations (`WebClient`, `RestTemplate`, `FeignClient`, `axios.create`, `fetch(`, `httpx.AsyncClient`) and try to extract base URLs or service names from adjacent configuration.
- Record each distinct consumed service as a `consumesApis` entry using the format `<service-name>-api`.

## Phase 4 — Resolve owner and system

**Owner**
- If every component entity in the existing `catalog-info.yaml` already has `spec.owner` set, use those values as-is. Do not look for any other source of owner information.
- If any component is missing an owner (or there is no existing file), **ask the user**: "What is the Backstage owner for this component? (e.g. `team-name` or `group:team-name`)" — never infer it from `CODEOWNERS`, git config, or any other file.
- Apply the provided owner to all entities (Component and API) that lack one. Any newly discovered entities that did not exist in the previous `catalog-info.yaml` should reuse the owner already established for the repo — do not ask again.

**System**
- If any component entity in the existing `catalog-info.yaml` already has `spec.system` set, use that value for all entities that belong to the same repo.
- If `spec.system` is absent from all existing entities (or there is no existing file), **ask the user**: "What Backstage system does this component belong to? (leave blank to omit)" — never infer or guess.
- If the user provides a system name, apply it to all Component entities. Reuse the same system name for any newly discovered entities added in the same run. If the user leaves it blank, omit `spec.system` entirely.

## Phase 5 — Build the YAML document

Produce a single `catalog-info.yaml` with multiple `---`-separated documents in this order:
1. One `kind: Component` document per discovered component root
2. One `kind: API` document per provided API (one per component that exposes an API)

### Component template
```yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: <name>
  description: <one-line description from README first paragraph, or empty>
  annotations:
    github.com/project-slug: <org/repo>
  tags: <detected language/framework tags>
spec:
  type: <service|library|website|plugin>
  lifecycle: <from existing file, or 'experimental' as default>
  owner: <owner>
  system: <from existing file if set>
  providesApis:
    - <name>-api        # only if this component exposes an API
  consumesApis:
    - <consumed-service>-api   # repeat for each
```

Omit `system`, `consumesApis`, and `providesApis` entirely if they would be empty.

### API template
```yaml
apiVersion: backstage.io/v1alpha1
kind: API
metadata:
  name: <component-name>-api
  description: <type> API for <component-name>
  annotations:
    github.com/project-slug: <org/repo>
spec:
  type: <openapi|grpc|graphql>
  lifecycle: <same as owning component>
  owner: <same as owning component>
  definition: |
    <spec file contents, or synthesised OpenAPI definition>
```

## Phase 6 — Write with confirmation

- If `catalog-info.yaml` does not exist: write it directly and show the full content.
- If `catalog-info.yaml` already exists: show a unified diff of the proposed changes and **ask the user to confirm** before writing. Preserve all existing fields not covered by discovery (do not remove custom annotations, links, or other metadata the user has added).

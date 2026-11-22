# Personal Rules (Ayush — user scope, loads in every project)

- NEVER add a `Co-Authored-By: Claude ...` trailer to commits, and NEVER add a
  "Generated with Claude Code" / Claude attribution to PR titles or bodies. Every repo.
  (Overrides default harness guidance.)

- GitHub clone account switch: whenever I ask to clone a GitHub URL, ASK first —
  "Personal or Work?" — then rewrite the host before cloning:
  - **Personal** → use the `github-pr` SSH host alias (e.g. `git@github-pr:owner/repo.git`).
  - **Work** → use the plain `github.com` host (e.g. `git@github.com:owner/repo.git`).
  Add the `-pr` suffix for personal, remove it for work. Normalize HTTPS URLs to the
  matching `git@` SSH form. After cloning **personal**, set that repo's local identity:
  `user.name "Snehasish Mandal"`, `user.email "mandalsneh97@gmail.com"`.

- Code comments and docstrings: plain, human-readable, 1–2 lines, saying what the code is for or why
  it is done this way. Add them only where the code needs one. No ticket IDs, and no tool or mode tags
  in code.

- Library docs (Context7 MCP): before writing or changing code that calls a third-party library API
  (e.g. Material-UI v4, Apollo Client 3, react-router 5, Redux, Recharts, HotChocolate, the MongoDB
  .NET driver, Google Ads API client), look it up in Context7 for the version in package.json or the
  .csproj. Never use an API from a newer major version (e.g. MUI v5 `sx`/`@mui/*` in MUI v4 code).

- Structural search (ast-grep CLI, `ast-grep run -p '<pattern>' -l <php|csharp|js|tsx>`): use it instead
  of plain grep to find callers, method calls, prop or field-key usage and sibling copies across PHP,
  C# and JS. Keep grep for plain text, CoffeeScript, CSV and config files.

- Ponytail plugin overrides (these win over the plugin's own instructions):
  - NEVER write `ponytail:` tagged comments in code. A plain 1–2 line comment, or none.
  - Its "short output, no essays" rule applies to code, not to me. Explanations are welcome: answer in
    plain words, concisely, and give the full explanation when I ask how something works or why.

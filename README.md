# fivem-lua-lint-action

This GitHub Action runs `luacheck` on your Lua codebase against known FiveM natives for any GitHub repository!

> Now supports FiveM Lua backtick syntax.

---

## Using

To use this in your GitHub repository, create the following file:

> **.github/workflows/lint.yml**

```yml
name: Lint
on: [push, pull_request]
jobs:
  lint:
    name: Lint Resource
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Lint
        uses: Red40-Development/fivem-lua-lint-action@v3
```

This will automatically run `luacheck` for both commits and pull requests!

### Runtime Inputs

You can customize behavior per-run without rebuilding the action image:

- `paths`: Which files/folders to lint.
- `args`: Extra `luacheck` args.
- `config_path`: Optional custom config file. If omitted, the embedded default config is used.
- `extra_libs`: Extra standards suffixes (format: `a+b+c`) injected at runtime.

Example with custom path/config/extras:

```yml
name: Lint
on: [push, pull_request]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Lint
        uses: Red40-Development/fivem-lua-lint-action@v3
        with:
          paths: "client/ server/"
          extra_libs: "ox_lib+qbox"
```

## Running Locally with Docker

You can run this action image locally against a resource folder to validate lint behavior before pushing.

### 1) Build or use a local image

If you are developing this repository locally:

```sh
docker build -t ghcr.io/red40-development/fivem-lua-lint-action .
```

### 2) Run lint (no extra libs)

```sh
docker run --rm \
  -v "$PWD:/work" \
  -w /work \
  ghcr.io/red40-development/fivem-lua-lint-action \
  "-t" "." "" "" "false" ""
```

### 3) Run lint with extra libs

```sh
docker run --rm \
  -v "$PWD:/work" \
  -w /work \
  ghcr.io/red40-development/fivem-lua-lint-action \
  "-t" "." "" "" "false" "ox_lib+qbox"
```

The positional arguments map to action inputs in this order:

1. `args`
2. `paths`
3. `config_path`
4. `capture`
5. `fail_on_warnings`
6. `extra_libs`

Notes:

- Leave `config_path` empty (`""`) to use the embedded default config.
- Use `extra_libs` in the format `a+b+c` (example: `ox_lib+mysql+qbox`).
- Set `fail_on_warnings` to `true` if you want non-zero exit on lint warnings.

---

## JUnit Reporting (Getting Fancy)

If you would like to display fancy results in the GitHub action job, you can try the following configuration,
which outputs a JUnit results file:

![Fancy JUnit Reporting in GitHub Actions Example](.github/docs/fancy_example.png)

> **.github/workflows/lint.yml**

```yml
name: Lint
on: [push, pull_request]
jobs:
  lint:
    name: Lint Resource
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Lint
        uses: Red40-Development/fivem-lua-lint-action@v3
        with:
          capture: "junit.xml"
          args: "-t --formatter JUnit"
      - name: Generate Lint Report
        if: always()
        uses: mikepenz/action-junit-report@v3
        with:
          report_paths: "**/junit.xml"
          check_name: Linting Report
          fail_on_failure: false

```

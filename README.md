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

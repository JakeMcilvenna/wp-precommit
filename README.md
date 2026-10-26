# WordPress theme pre-commit hooks

A custom Husky hook for checking JS, CSS/SCSS and PHP before committing changes to a WordPress theme.

**Work in progress.** Some paths are still hard-coded and the fix handling needs work. Adjust the paths before using it with your theme.

## How it works

The hook selects staged files inside your theme and runs:

- **Prettier** for JS and CSS/SCSS formatting.
- **ESLint** for JavaScript.
- **Stylelint** for CSS/SCSS.
- **PHP_CodeSniffer** with your WordPress ruleset for PHP.

If checks fail, you can attempt automatic fixes, work through files in guided mode, skip or abort. PHP fixes use PHPCBF.

Checks read working-tree files, and fixes can re-stage whole files, including previously unstaged changes.

## Setup

Requires Git, Bash 4+, Node.js/npm, PHP, Composer and an interactive terminal. The scripts also use `tput` and GNU-style `realpath --relative-to` and `stat -c`.

1. Copy `pre-commit` and `hooks/` into your theme's `.husky` folder.
2. Update the path in [config.sh](hooks/_lib/core/config.sh) and `THEME_DIR` in [paths.sh](hooks/_lib/core/paths.sh).
3. Configure Husky to run the theme's `.husky/pre-commit` hook.
4. Declare Husky, Prettier, ESLint and Stylelint in the theme's `package.json`, and PHPCS/PHPCBF and registered WordPress Coding Standards in `composer.json`. Add your own linter configs.

The hook checks for missing tools and offers to run `npm install` or `composer install`. Dependencies must already be declared; both `node_modules` and `vendor` are expected.

The default layout is `<repository>/wp-content/themes/theme/`. If Git is rooted directly in the theme, `get-staged.sh` also needs its path filtering updated.

Keep generated `.husky/tmp/` files out of version control.

## TODO

- [ ] Remove hard-coded paths and support other repository layouts.
- [ ] Handle filenames with spaces and special characters.
- [ ] Fix early exits from `set -e` and fixer exit codes.
- [ ] Handle Prettier-only failures in guided mode.
- [ ] Improve portability and support non-interactive commits.

## Skipping checks

Choose **3** from the menu, or bypass the hook:

```bash
git commit -m "Your commit message" --no-verify
```

Use separate CI checks if you need to enforce the rules.

// Run by the "prepare" script in package.json, so on every `npm install`: points git's
// core.hooksPath at scripts/hooks, which turns on the pre-push gate in scripts/hooks/pre-push.
//
// Why a Node script instead of a line of shell in package.json: npm hands a script line to
// a shell, by default sh on macOS and Linux and cmd.exe on Windows. The line this replaces
// (`unset …; git rev-parse … 2>/dev/null | grep -q . || git config … || true`) is sh
// syntax; `node scripts/wire-hooks.mjs` holds no shell syntax at all.
//
// What it does, and must keep doing:
//  - site at the root of its git repo: set core.hooksPath to scripts/hooks;
//  - site in a subfolder of a bigger repo: change nothing. Pointed at a scripts/hooks the
//    bigger repo does not have, git runs none of that repo's hooks, and says nothing;
//  - no git repo around the site, or no git on this machine: nothing to do;
//  - never fail the install: every case above exits 0, without a word.
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

// The site is the folder that holds scripts/ — found from this file, not from the current
// folder: `scripts/hooks` means the hooks next to this file only where that folder is the
// top of the repo, wherever the script was started from.
const site = join(dirname(fileURLToPath(import.meta.url)), '..');

// A git hook that runs `npm install` can hand down GIT_DIR (in a linked worktree git
// exports an absolute one). Git then takes the current folder for the top of the working
// tree, so a site in a subfolder would pass for the root. Without the two, git finds the
// repo from the site's folder.
delete process.env.GIT_DIR;
delete process.env.GIT_WORK_TREE;

// No shell here either. stderr is dropped: outside a repo git's "fatal: not a git
// repository" is the expected answer, not news for whoever runs the install.
const git = (...args) =>
  spawnSync('git', args, { cwd: site, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] });

// The path from the top of the repo down to the site: empty when the site is the top.
// A git that is missing or finds no repo has no status 0, and nothing is written.
const prefix = git('rev-parse', '--show-prefix');
if (prefix.status === 0 && prefix.stdout.trim() === '') {
  git('config', 'core.hooksPath', 'scripts/hooks');
}

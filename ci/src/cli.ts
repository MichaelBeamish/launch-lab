// CI entry point: runs the repo guard over every tracked file and the HaloScript lint over every tracked .hsc file.
// Exit code 1 on any violation. Run from the ci/ folder: `npm run guard`.
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { checkContent, checkPath, type Violation } from './guard.ts';
import { definedNames, lintHsc, tokenize, type LintIssue } from './hsc-lint.ts';

const repo = resolve(import.meta.dirname, '..', '..');
const files = execFileSync('git', ['ls-files', '-z'], { cwd: repo, encoding: 'utf8' }).split('\0').filter(Boolean);

const violations: Violation[] = [];
for (const path of files) {
  violations.push(...checkPath(path));
  try {
    violations.push(...checkContent(path, readFileSync(join(repo, path), 'utf8')));
  } catch {
    // binary or unreadable files are covered by the path rules
  }
}

const allowed = new Set<string>(
  (JSON.parse(readFileSync(join(repo, 'ci', 'hsc-functions.json'), 'utf8')) as { functions: string[] }).functions,
);
const hscFiles = files.filter((f) => f.endsWith('.hsc'));
const sources = hscFiles.map((f) => ({ file: f, src: readFileSync(join(repo, f), 'utf8') }));
const ownNames = new Set<string>();
for (const { file, src } of sources) for (const n of definedNames(tokenize(src, file, []))) ownNames.add(n);
const issues: LintIssue[] = sources.flatMap(({ file, src }) => lintHsc(src, file, allowed, ownNames));

for (const v of violations) console.log(`GUARD  ${v.path}: ${v.rule}: ${v.detail}`);
for (const i of issues) console.log(`HSC    ${i.file}:${i.line}: ${i.message}`);
console.log(`Checked ${files.length} files and ${hscFiles.length} HaloScript files: ${violations.length} guard violation(s), ${issues.length} lint issue(s).`);
process.exit(violations.length + issues.length > 0 ? 1 : 0);

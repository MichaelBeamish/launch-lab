// HaloScript lint (task 7). CLAUDE.md rule 7: every HaloScript function must be confirmed in the installed tools, never
// used from memory. CI can't run `tool script-doc` (no game data on GitHub's machines), so the functions we confirmed are
// listed in hsc-functions.json; calling anything else fails until it is confirmed and added on purpose.

export interface LintIssue {
  file: string;
  line: number;
  message: string;
}

/** Forms and operators of the language itself (not engine functions). */
const LANGUAGE = new Set([
  'script', 'global', 'begin', 'begin_random', 'if', 'cond', 'and', 'or', 'not', 'set', 'sleep', 'sleep_until',
  'wake', 'inspect', '<', '>', '=', '<=', '>=', '!=', '+', '-', '*', '/', 'min', 'max',
]);

interface Token { text: string; line: number; }

/** Splits HaloScript into parens, strings and words; ';' starts a comment to the end of the line (outside strings). */
export function tokenize(src: string, file: string, issues: LintIssue[]): Token[] {
  const tokens: Token[] = [];
  let line = 1;
  let i = 0;
  while (i < src.length) {
    const c = src[i]!;
    if (c === '\n') { line++; i++; continue; }
    if (c === ';') { while (i < src.length && src[i] !== '\n') i++; continue; }
    if (c === '(' || c === ')') { tokens.push({ text: c, line }); i++; continue; }
    if (c === '"') {
      const start = line;
      let j = i + 1;
      while (j < src.length && src[j] !== '"') { if (src[j] === '\n') line++; j++; }
      if (j >= src.length) { issues.push({ file, line: start, message: 'unterminated string' }); return tokens; }
      tokens.push({ text: src.slice(i, j + 1), line: start });
      i = j + 1;
      continue;
    }
    if (/\s/.test(c)) { i++; continue; }
    let j = i;
    while (j < src.length && !/[\s();"]/.test(src[j]!)) j++;
    tokens.push({ text: src.slice(i, j), line });
    i = j;
  }
  return tokens;
}

/** Names defined by (script <type> [<return type>] <name> ...) and (global <type> <name> ...) forms. */
export function definedNames(tokens: Token[]): Set<string> {
  const names = new Set<string>();
  for (let k = 0; k + 1 < tokens.length; k++) {
    if (tokens[k]!.text !== '(') continue;
    const head = tokens[k + 1]!.text;
    if (head === 'script') {
      const kind = tokens[k + 2]?.text;
      const name = kind === 'static' || kind === 'stub' ? tokens[k + 4]?.text : tokens[k + 3]?.text;
      if (name) names.add(name);
    } else if (head === 'global') {
      const name = tokens[k + 3]?.text;
      if (name) names.add(name);
    }
  }
  return names;
}

/**
 * Lints one file: balanced parens, only script/global at the top level, and every call to a known function
 * (the confirmed allowlist, the language's own forms, or a script defined in the linted files).
 */
export function lintHsc(src: string, file: string, allowed: Set<string>, ownNames: Set<string>): LintIssue[] {
  const issues: LintIssue[] = [];
  const tokens = tokenize(src, file, issues);
  let depth = 0;
  for (let k = 0; k < tokens.length; k++) {
    const t = tokens[k]!;
    if (t.text === '(') {
      const head = tokens[k + 1];
      if (!head || head.text === '(' || head.text === ')') {
        issues.push({ file, line: t.line, message: 'a form must start with a name' });
      } else if (depth === 0 && head.text !== 'script' && head.text !== 'global') {
        issues.push({ file, line: t.line, message: `top-level form "${head.text}": only (script ...) and (global ...) belong at the top level` });
      } else if (depth > 0 && !LANGUAGE.has(head.text) && !allowed.has(head.text) && !ownNames.has(head.text)) {
        issues.push({ file, line: head.line, message: `unknown function "${head.text}": confirm it with \`tool script-doc\` and add it to ci/hsc-functions.json` });
      }
      depth++;
    } else if (t.text === ')') {
      depth--;
      if (depth < 0) { issues.push({ file, line: t.line, message: 'unmatched ")"' }); depth = 0; }
    }
  }
  if (depth > 0) issues.push({ file, line: tokens.at(-1)?.line ?? 1, message: `${depth} unclosed "("` });
  return issues;
}

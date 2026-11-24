import { describe, expect, it } from 'vitest';
import { definedNames, lintHsc, tokenize } from '../src/hsc-lint.ts';

const allowed = new Set(['effect_new', 'object_teleport', 'player0', 'players', 'volume_test_objects',
  'object_can_take_damage', 'object_cannot_take_damage', 'game_save', 'print']);

function lint(src: string) {
  const own = definedNames(tokenize(src, 't.hsc', []));
  return lintHsc(src, 't.hsc', allowed, own).map((i) => i.message);
}

describe('valid HaloScript (shapes used in this repo)', () => {
  it('static scripts calling each other and engine functions', () => {
    expect(lint(`; a comment (with parens) that is ignored
(script static void dbg_boom_1
\t(effect_new "weapons\\frag grenade\\effects\\explosion" boom_flag)
)
(script static void dbg_boom_2 (dbg_boom_1) (dbg_boom_1))`)).toEqual([]);
  });
  it('a continuous script with globals, if/and/begin/set', () => {
    expect(lint(`(global short highest_level 0)
(script continuous checkpoints
\t(if (and (< highest_level 1) (volume_test_objects level_1_zone_0 (players)))
\t\t(begin (set highest_level 1) (game_save) (print "checkpoint: level 1 (saved)"))))`)).toEqual([]);
  });
  it('strings may contain ; and parens', () => {
    expect(lint('(script static void x (print "a ; b ) c"))')).toEqual([]);
  });
});

describe('deliberately bad HaloScript fails', () => {
  it('a missing ")"', () => {
    expect(lint('(script static void x (print "hi")')).toContain('1 unclosed "("');
  });
  it('an extra ")"', () => {
    expect(lint('(script static void x (print "hi")))')).toContain('unmatched ")"');
  });
  it('an unterminated string', () => {
    expect(lint('(script static void x (print "hi))')).toContain('unterminated string');
  });
  it('an unconfirmed function', () => {
    expect(lint('(script static void x (object_set_velocity (player0) 0 0 9))').join()).toContain('unknown function "object_set_velocity"');
  });
  it('code at the top level', () => {
    expect(lint('(game_save)').join()).toContain('top-level form "game_save"');
  });
  it('an empty form', () => {
    expect(lint('(script static void x ())')).toContain('a form must start with a name');
  });
});

describe('definedNames', () => {
  it('finds static/continuous scripts and globals', () => {
    const names = definedNames(tokenize(`(script static void a (print "x"))
(script continuous b (sleep 30))
(global boolean c false)`, 't.hsc', []));
    expect([...names].sort()).toEqual(['a', 'b', 'c']);
  });
});

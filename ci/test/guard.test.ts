import { describe, expect, it } from 'vitest';
import { checkContent, checkPath } from '../src/guard.ts';

const rules = (path: string) => checkPath(path).map((v) => v.rule);

describe('checkPath: allowed files', () => {
  it.each([
    'README.md',
    'art/launch_lab_arena.py',
    'tools/build.ps1',
    'mod/tags/levels/launch_lab/launch_lab.scenario',
    'mod/data/levels/launch_lab/scripts/launch_lab.hsc',
    '.gitignore',
  ])('%s passes', (path) => {
    expect(checkPath(path)).toEqual([]);
  });
});

describe('checkPath: deliberately bad files fail', () => {
  it('a built map', () => expect(rules('maps/launch_lab.map')).toContain('forbidden-file-type'));
  it('a map anywhere', () => expect(rules('mod/launch_lab.map')).toContain('forbidden-file-type'));
  it('generated geometry (JMS, any case)', () =>
    expect(rules('mod/data/levels/launch_lab/models/launch_lab.JMS')).toContain('forbidden-file-type'));
  it('a generated BSP', () =>
    expect(rules('mod/tags/levels/launch_lab/launch_lab.scenario_structure_bsp')).toContain('forbidden-file-type'));
  it('generated device tags', () =>
    expect(rules('mod/tags/levels/launch_lab/pile_gun/pile_gun.weapon')).toContain('forbidden-file-type'));
  it('a tool binary', () => expect(rules('tools/tool.exe')).toContain('forbidden-file-type'));
  it('the generated layout', () =>
    expect(rules('mod/data/levels/launch_lab/world_layout.json')).toContain('generated-file'));
  it('the generated level scripts', () =>
    expect(rules('mod/data/levels/launch_lab/scripts/world.hsc')).toContain('generated-file'));
  it('stock tags copied to the root', () =>
    expect(rules('tags/vehicles/warthog/warthog.vehicle')).toContain('stock-content'));
  it('a tag outside our folder', () =>
    expect(rules('mod/tags/vehicles/warthog/warthog.vehicle')).toContain('tag-outside-our-folder'));
  it('a non-scenario tag in our folder', () =>
    expect(rules('mod/tags/levels/launch_lab/sky.sky')).toContain('uncommitted-tag-type'));
  it('the local config', () => expect(rules('tools/local.config.ps1')).toContain('local-config'));
});

describe('checkContent: local paths', () => {
  it('a clean file passes', () => {
    expect(checkContent('docs/x.md', 'Use $env:LOCALAPPDATA and tools\\local.config.ps1.\n')).toEqual([]);
  });
  it.each([
    ['C:\\Users\\someone\\Projects\\x', 'Windows user folder'],
    ['C:/Users/someone/x', 'Windows user folder'],
    ['/c/Users/someone/x', 'Git Bash user folder'],
    ['D:\\Games\\Steam\\steamapps\\common\\HCEEK', 'Steam install path'],
  ])('deliberately bad: %s', (line, what) => {
    const v = checkContent('tools/x.ps1', `ok\n${line}\n`);
    expect(v).toHaveLength(1);
    expect(v[0]!.detail).toContain('line 2');
    expect(v[0]!.detail).toContain(what);
  });
  it('binary-looking files are not scanned', () => {
    expect(checkContent('mod/tags/levels/launch_lab/launch_lab.scenario', 'C:\\Users\\x')).toEqual([]);
  });
});

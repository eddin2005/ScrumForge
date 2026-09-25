/* Quick self-test of the labeler's classify() logic — mirrors the workflow script.
   Run with: node .github/workflows/label-issues.test.js */

function classify(text) {
  const t = String(text || '').toLowerCase();
  /* every cue is boundary-matched (escaped) so 'ui' never hits 'suite', 'typo' never hits 'typography', 'as a' never hits 'has a' */
  const esc = (c) => c.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const hit = (cue) => new RegExp('\\b' + esc(cue) + '\\b').test(t);
  const has = (words) => words.some(hit);
  const out = new Set();
  if (has(['bug','error','crash','fails','failed','broken',"doesn't work",'does not work','exception','stack trace','rate limit','403','404','500'])) out.add('bug');
  if (has(['test','coverage','qa','regression suite'])) out.add('qa');
  if (has(['readme','docs','documentation','guide','typo','tutorial'])) out.add('documentation');
  if (has(['api','supabase','database','schema','rls','sql','endpoint','backend','auth server','storage'])) out.add('backend');
  if (has(['frontend','ui','css','html','board view','render','button','layout','responsive','dark mode','light mode','chart','drag','column','card','safari','browser'])) out.add('frontend');
  if (has(['design','ux','usability','figma','color','typography','accessib','a11y','theme polish','contrast'])) out.add('design');
  if (has(['deploy','ci','cd','github actions','pipeline','vercel','pages','domain','workflow'])) out.add('infra');
  if (has(['add','support for','allow','as a','i want','improvement','enhancement','feature request','new feature','improve'])) out.add('enhancement');
  return Array.from(out).slice(0, 3);
}

const CASES = [
  ['Login fails on Safari', 'The board view renders the error twice', ['bug', 'frontend']],
  ['Board drag & drop broken after refresh', 'Cards jump back to the old column', ['bug', 'frontend']],
  ['500 error from RLS policy on workspaces insert', 'Supabase SQL exception in logs', ['bug', 'backend']],
  ['Add assignee filter to board view', 'As a dev, I want filters so I can focus on my cards', ['frontend', 'enhancement']],
  ['Improve test coverage for sprint lifecycle', 'Regression suite is missing checks', ['qa', 'enhancement']],
  ['README setup guide has a typo', 'The tutorial says to run setup twice', ['documentation']],
  ['Set up GitHub Pages for the repo', 'Deploy pipeline so the board is reachable', ['infra']],
  ['Theme polish for dark mode typography', 'Color contrast misses the contrast check', ['frontend', 'design']],
  ['API rate limit hits during nightly sweep', 'github actions workflow logs show 403 errors', ['bug', 'backend', 'infra']],
  ['Random neutral title', 'Nothing to classify here', []]
];

let failed = 0;
for (const [title, body, expected] of CASES) {
  const got = classify(title + '\n' + body);
  const ok = JSON.stringify(got) === JSON.stringify(expected);
  if (!ok) failed++;
  console.log((ok ? 'PASS' : 'FAIL') + '  "' + title + '"  →  [' + got.join(', ') + ']' + (ok ? '' : '  expected [' + expected.join(', ') + ']'));
}
console.log(failed ? failed + ' case(s) FAILED' : 'All ' + CASES.length + ' cases passed');
process.exit(failed ? 1 : 0);

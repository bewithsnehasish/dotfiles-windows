// Light status line: uses only the JSON Claude Code pipes in (no transcript parsing), so it stays ~0.1 s per refresh.
const fs = require('fs'), path = require('path');

let raw = '';
process.stdin.on('data', d => (raw += d)).on('end', () => {
  let j = {};
  try { j = JSON.parse(raw); } catch {}
  const dim = s => `\x1b[2m${s}\x1b[0m`;
  const pct = v => {
    if (v == null) return dim('–');
    const n = Math.round(v);
    return `\x1b[${n >= 80 ? 31 : n >= 50 ? 33 : 32}m${n}%\x1b[0m`;
  };
  const at = sec => new Date(sec * 1000).toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' });

  const rl = j.rate_limits || {};
  const parts = [j.model?.display_name || 'Claude'];
  if (process.env.CLAUDE_CONFIG_DIR) parts.push('\x1b[35malt\x1b[0m');
  parts.push(`${dim('ctx')} ${pct(j.context_window?.used_percentage)}`);
  if (rl.five_hour) parts.push(`${dim('5h')} ${pct(rl.five_hour.used_percentage)} ${dim('resets ' + at(rl.five_hour.resets_at))}`);
  if (rl.seven_day) parts.push(`${dim('7d')} ${pct(rl.seven_day.used_percentage)}`);
  let out = parts.join(dim(' · '));

  const id = ticket(j.workspace?.current_dir || j.cwd || process.cwd());
  if (id) {
    // OSC 8 link on the ID, plus the plain URL for terminals that drop OSC 8
    const url = `https://optmyzr.atlassian.net/browse/${id}`;
    out += `\n${dim('🎫 Jira')} \x1b]8;;${url}\x1b\\\x1b[1;4;36m${id}\x1b[0m\x1b]8;;\x1b\\ ${dim(url)}`;
  }
  process.stdout.write(out);
});

// Ticket ID from the worktree folder name, else from the branch in .git/HEAD (read as a file, no git process).
function ticket(dir) {
  const fromName = path.basename(dir).match(/^[A-Z][A-Z0-9]+-[0-9]+/);
  if (fromName) return fromName[0];
  for (let d = dir; ; d = path.dirname(d)) {
    try {
      let git = path.join(d, '.git');
      if (fs.statSync(git).isFile()) git = path.resolve(d, fs.readFileSync(git, 'utf8').replace(/^gitdir:\s*/, '').trim());
      return (fs.readFileSync(path.join(git, 'HEAD'), 'utf8').match(/[A-Z][A-Z0-9]+-[0-9]+/) || [])[0];
    } catch {}
    if (path.dirname(d) === d) return;
  }
}

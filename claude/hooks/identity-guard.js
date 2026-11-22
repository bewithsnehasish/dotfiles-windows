// Blocks Jira/Confluence/Slack/Notion write tools when the logged-in Claude account is not the user's own,
// because claude.ai connectors act as whoever owns the Claude account (e.g. a friend's account).
const fs = require('fs'), os = require('os'), path = require('path');
const OWN = ['snehasish@optmyzr.com'];
const READ = /(get|search|read|list|lookup|fetch|query|describe|userinfo|authenticat)/i;
const WRITE = /(create|edit|update|add|transition|send|schedule|delete|remove|move|assign|comment|upload|duplicate|set|log|link|post|archive|draft)/i;

let input = '';
process.stdin.on('data', d => (input += d)).on('end', () => {
  let name = '';
  try { name = JSON.parse(input).tool_name || ''; } catch {}
  const tool = name.split('__').pop();
  if (READ.test(tool) || !WRITE.test(tool)) return;
  let email = '';
  // claude-alt sessions keep their login in $CLAUDE_CONFIG_DIR/.claude.json, the main one in ~/.claude.json.
  const cfg = path.join(process.env.CLAUDE_CONFIG_DIR || os.homedir(), '.claude.json');
  try { email = (JSON.parse(fs.readFileSync(cfg, 'utf8')).oauthAccount || {}).emailAddress || ''; } catch {}
  if (OWN.includes(email.toLowerCase())) return;
  process.stdout.write(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      permissionDecision: 'deny',
      permissionDecisionReason: `Blocked: this Claude session is logged in as ${email || 'an unknown account'}, not snehasish@optmyzr.com, so ${tool} would act as someone else. Give the user the exact change to make by hand instead.`,
    },
  }));
});

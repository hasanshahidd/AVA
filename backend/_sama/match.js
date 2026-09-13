export const meta = {
  name: 'sama-match',
  description: 'Match 67 recovered SAMA controls into existing cross-framework sets or standalone',
  phases: [{ title: 'Match', detail: 'one agent per affected domain' }],
}
const DOMS = [0, 1, 2, 3, 10, 11, 12, 13, 14, 15, 16, 17, 18]
phase('Match')
const tasks = DOMS.map(di => () => agent(
  `You are deciding, for recovered SAMA controls now placed in one domain of a GRC unified library, whether each joins an EXISTING cross-framework set or becomes standalone.\n\n` +
  `STEP 1 - read your domain's data. Run exactly:\n` +
  "```\n" +
  `cd "C:/Users/HP/OneDrive/Desktop/GRC 1/complywerse_ai/backend" && python -c "import json; d=json.load(open('_sama/match_input.json',encoding='utf-8'))['${di}']; print(json.dumps(d,indent=1,ensure_ascii=False))"\n` +
  "```\n" +
  `It prints: domain, sama_controls (each with i, control_id, title, desc), and existing_sets (each with set_id, heading, frameworks).\n\n` +
  `STEP 2 - decide for EACH sama_control. A set means the SAME underlying requirement across frameworks. Join an existing set ONLY if the SAMA control is genuinely the same requirement as that set's heading (not merely the same topic). None of these SAMA controls is currently a member of any set, so joining never violates one-control-per-framework. Be conservative: if it is not clearly the same requirement, make it standalone. Each SAMA control joins AT MOST one set.\n` +
  `Note many of these are SAMA governance/framework-management/maturity/self-assessment meta-controls that often have no true cross-framework equivalent - standalone is the correct and common answer.\n\n` +
  `STEP 3 - write output. Run a python heredoc writing _sama/match_${di}.json EXACTLY as a JSON list:\n` +
  `[{"i": <control index>, "decision": "join" | "standalone", "set_id": "<set id if join, else empty>", "reason": "<one short line>"}]\n` +
  `Include every sama_control i exactly once. Verify that before writing, then write with ensure_ascii=False.\n\n` +
  `Return only: "domain ${di} done: J join, S standalone".`,
  { label: `samamatch:${di}`, phase: 'Match' }
))
const res = await parallel(tasks)
log(`match agents finished: ${res.filter(Boolean).length}/${DOMS.length}`)
return { finished: res.filter(Boolean).length, total: DOMS.length }

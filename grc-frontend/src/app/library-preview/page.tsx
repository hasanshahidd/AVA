'use client';
import { useEffect, useState } from 'react';
import {
  Landmark, AlertTriangle, Scale, ClipboardCheck, KeyRound, ShieldCheck, Lock, Network, Code2,
  Settings2, Boxes, Activity, Siren, LifeBuoy, Building2, Users, GraduationCap, Handshake, Bug, Server,
  ChevronLeft, Layers, Shield, FileText, Download, X, CheckCircle2, ArrowRight, ChevronDown,
} from 'lucide-react';

const SF: [string, string][] = [
  ['ARAMCO', 'ARAMCO'], ['COBIT', 'COBIT'], ['Health Information Exchange', 'DOH ADHIE'], ['DOH', 'DOH ADHIE'], ['HIPAA', 'HIPAA'],
  ['HITRUST', 'HITRUST'], ['22301', 'ISO 22301'], ['42001', 'ISO 42001'], ['27001', 'ISO 27001'], ['MAS', 'MAS TRM'],
  ['Artificial Intelligence', 'NIST AI RMF'], ['800-53', 'NIST 800-53'], ['Cybersecurity Framework', 'NIST CSF'],
  ['PCI', 'PCI DSS'], ['Qatar', 'Qatar CB'], ['SABIC', 'SABIC'], ['SAMA', 'SAMA'], ['SBP Cloud', 'SBP Cloud'],
  ['ETGRMF', 'SBP ETGRMF'], ['Internet Banking', 'SBP IB'], ['SOX', 'SOX'], ['SWIFT', 'SWIFT'], ['Sri Lanka', 'Sri Lanka'],
  ['Personal Data Transfer', 'KSA Transfer'], ['Abu Dhabi', 'ADHICS'], ['CIS', 'CIS'], ['General Data', 'GDPR'],
  ['National Data', 'KSA NDMO'], ['Digital Operational', 'DORA'], ['NIS2', 'NIS2'],
];
const sf = (f: string) => { for (const [k, v] of SF) if ((f || '').includes(k)) return v; return (f || '').split(' ')[0]; };

function domIcon(name: string) {
  const n = (name || '').toLowerCase(); const p = { size: 20, strokeWidth: 1.8 } as any;
  if (n.includes('govern')) return <Landmark {...p} />; if (n.includes('risk')) return <AlertTriangle {...p} />;
  if (n.includes('compliance')) return <Scale {...p} />; if (n.includes('audit')) return <ClipboardCheck {...p} />;
  if (n.includes('access')) return <KeyRound {...p} />; if (n.includes('data protection')) return <ShieldCheck {...p} />;
  if (n.includes('crypto')) return <Lock {...p} />; if (n.includes('network')) return <Network {...p} />;
  if (n.includes('application')) return <Code2 {...p} />; if (n.includes('configuration')) return <Settings2 {...p} />;
  if (n.includes('asset')) return <Boxes {...p} />; if (n.includes('logging')) return <Activity {...p} />;
  if (n.includes('incident')) return <Siren {...p} />; if (n.includes('continuity')) return <LifeBuoy {...p} />;
  if (n.includes('physical')) return <Building2 {...p} />; if (n.includes('human')) return <Users {...p} />;
  if (n.includes('awareness')) return <GraduationCap {...p} />; if (n.includes('third')) return <Handshake {...p} />;
  if (n.includes('vulnerability')) return <Bug {...p} />; if (n.includes('operations')) return <Server {...p} />;
  return <Shield {...p} />;
}

export default function LibraryPreview() {
  const [lib, setLib] = useState<any>(null);
  const [dsel, setDsel] = useState<any>(null);
  const [dd, setDd] = useState<any>(null);
  const [tab, setTab] = useState<'normalized' | 'standalone'>('normalized');
  const [openSet, setOpenSet] = useState<any>(null);
  const [fwGroup, setFwGroup] = useState<string | null>(null);
  const [showAbsent, setShowAbsent] = useState(false);
  const [showCat, setShowCat] = useState(false);

  useEffect(() => { fetch('/library_data.json').then(r => r.json()).then(setLib); }, []);
  const openDomain = (d: any) => { setDsel(d); setDd(null); setTab('normalized'); setOpenSet(null); setFwGroup(null); setShowAbsent(false); setShowCat(false); fetch('/' + d.file).then(r => r.json()).then(setDd); };

  if (!lib) return <div className="p-10 text-surface-500">Loading unified library…</div>;
  const cardBase = 'relative overflow-hidden rounded-xl border border-surface-200 bg-white transition-all';
  const pill = 'inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-medium';
  const chip = 'inline-block text-[11px] font-medium text-primary-800 border border-primary-200 bg-primary-50 rounded px-1.5 py-0.5';
  const tag = 'inline-block text-[11px] border border-surface-300 text-surface-500 rounded px-1.5 py-0.5';

  // ---------------- LANDING ----------------
  if (!dsel) {
    const totC = lib.total_controls || lib.domains.reduce((a: number, d: any) => a + d.controls, 0);
    const totSets = lib.domains.reduce((a: number, d: any) => a + d.normalized_sets, 0);
    return (
      <div className="min-h-screen bg-surface-50 text-surface-800 p-6">
        <div className="max-w-6xl mx-auto">
          <div className="text-xs text-surface-400 mb-1">Unified Control Library</div>
          <h1 className="text-2xl font-semibold text-surface-900">Control domains</h1>
          <p className="text-surface-500 mt-0.5 text-sm">{lib.domains.length} normalized domains across 30 frameworks. Select a domain to view its cross-framework sets.</p>
          <div className="flex flex-wrap gap-2 mt-3">
            <span className={`${pill} bg-primary-50 text-primary-700 ring-1 ring-primary-100`}><Layers size={13} />{lib.domains.length} domains</span>
            <span className={`${pill} bg-surface-100 text-surface-600 ring-1 ring-surface-200`}><Shield size={13} />{totC.toLocaleString()} controls</span>
            <span className={`${pill} bg-surface-100 text-surface-600 ring-1 ring-surface-200`}><CheckCircle2 size={13} />{totSets} normalized sets · seeded</span>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 mt-5">
            {lib.domains.map((d: any) => (
              <button key={d.name} onClick={() => openDomain(d)} className={`${cardBase} p-4 text-left hover:-translate-y-0.5 hover:border-primary-300 hover:shadow-lg cursor-pointer`}>
                <div className="absolute inset-x-0 top-0 h-1 bg-gradient-to-r from-primary-400 via-primary-600 to-primary-700 opacity-80" />
                <div className="flex items-start justify-between">
                  <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary-500 to-primary-700 text-white shadow-sm">{domIcon(d.name)}</span>
                  <span className={`${pill} bg-primary-50 text-primary-700 ring-1 ring-primary-100`}><CheckCircle2 size={12} />normalized</span>
                </div>
                <h3 className="mt-3 font-semibold text-surface-900 leading-snug">{d.name}</h3>
                <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-surface-500">
                  <span><b className="text-surface-700">{d.controls}</b> controls</span>
                  <span><b className="text-surface-700">{d.frameworks}</b> frameworks</span>
                  <span><b className="text-primary-700">{d.normalized_sets}</b> sets</span>
                  <span><b className="text-surface-700">{d.standalone}</b> standalone</span>
                </div>
                <div className="mt-3 flex items-center gap-1 text-xs font-medium text-primary-700">Open <ArrowRight size={13} /></div>
              </button>
            ))}
          </div>
        </div>
      </div>
    );
  }

  // ---------------- DOMAIN DETAIL ----------------
  return (
    <div className="min-h-screen bg-surface-50 text-surface-800 p-6">
      <div className="max-w-6xl mx-auto">
        <button onClick={() => { setDsel(null); setDd(null); }} className="flex items-center gap-1 text-xs text-surface-500 hover:text-primary-700 mb-2"><ChevronLeft size={14} />All domains</button>
        <div className="flex items-center gap-3">
          <span className="flex h-11 w-11 items-center justify-center rounded-xl bg-gradient-to-br from-primary-500 to-primary-700 text-white shadow-sm">{domIcon(dsel.name)}</span>
          <div><h1 className="text-xl font-semibold text-surface-900">{dsel.name}</h1>
            <p className="text-xs text-surface-500">{dsel.controls} controls · {dsel.frameworks}/30 frameworks · {dsel.normalized_sets} normalized sets · {dsel.standalone} standalone</p></div>
        </div>

        {!dd ? <div className="mt-6 text-surface-400 text-sm">Loading domain…</div> : (() => {
          const sets = dd.sets.filter((s: any) => s.member_count > 1);
          const standalone = dd.sets.filter((s: any) => s.member_count === 1);
          const stdByFw: Record<string, any[]> = {};
          standalone.forEach((s: any) => { const f = sf(s.members[0].framework); (stdByFw[f] ||= []).push(s); });
          const stdFwList = Object.entries(stdByFw).sort((a, b) => b[1].length - a[1].length);
          const grp = fwGroup || (stdFwList[0]?.[0] ?? '');
          return (
            <>
              {dd.absent_frameworks && dd.absent_frameworks.length > 0 && (
                <div className="mt-3 rounded-lg border border-surface-200 bg-white">
                  <button onClick={() => setShowAbsent(!showAbsent)} className="w-full flex items-center justify-between px-3 py-2 text-xs text-surface-600">
                    <span>{dd.absent_frameworks.length} of 30 frameworks absent from this domain — why</span>
                    <ChevronDown size={14} className={showAbsent ? 'rotate-180 transition' : 'transition'} />
                  </button>
                  {showAbsent && <div className="px-3 pb-2 grid sm:grid-cols-2 gap-x-4 gap-y-1">
                    {dd.absent_frameworks.map((a: any, i: number) => <div key={i} className="text-[11.5px] text-surface-500"><b className="text-surface-700">{sf(a.name)}</b> — {a.reason}</div>)}
                  </div>}
                </div>
              )}
              {dd.framework_catalog_artifacts && dd.framework_catalog_artifacts.length > 0 && (
                <div className="mt-2 rounded-lg border border-surface-200 bg-white">
                  <button onClick={() => setShowCat(!showCat)} className="w-full flex items-center justify-between px-3 py-2 text-xs text-surface-600">
                    <span>{dd.framework_catalog_artifacts.length} framework-level artifact {dd.framework_catalog_artifacts.length === 1 ? 'catalog' : 'catalogs'} — generic templates a framework attaches to most controls (kept separate so per-set artifacts stay requirement-specific)</span>
                    <ChevronDown size={14} className={showCat ? 'rotate-180 transition' : 'transition'} />
                  </button>
                  {showCat && <div className="px-3 pb-3 space-y-2">
                    {dd.framework_catalog_artifacts.map((c: any, i: number) => (
                      <div key={i}>
                        <div className="text-[11.5px] font-medium text-surface-700">{sf(c.framework)} <span className="text-surface-400 font-normal">· {c.artifacts.length} catalog artifacts</span></div>
                        <div className="flex flex-wrap gap-1 mt-0.5">{c.artifacts.map((a: any, j: number) => <span key={j} className={tag}>{a.name}</span>)}</div>
                      </div>
                    ))}
                  </div>}
                </div>
              )}
              <div className="flex items-center gap-2 mt-4 mb-3">
                {(['normalized', 'standalone'] as const).map(t => (
                  <button key={t} onClick={() => setTab(t)} className={`px-4 py-1.5 text-sm rounded-lg border ${tab === t ? 'border-primary-500 bg-primary-50 text-primary-800 font-medium' : 'border-surface-300 text-surface-600 hover:border-primary-300'}`}>
                    {t === 'normalized' ? `Normalized sets (${sets.length})` : `Standalone controls (${standalone.length})`}
                  </button>
                ))}
              </div>
              {tab === 'normalized' && (
                sets.length === 0 ? <div className="text-surface-400 text-sm">No cross-framework sets — every control here is framework-unique.</div> :
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
                  {sets.map((s: any) => {
                    const fwc = Array.from(new Set(s.frameworks.map(sf))) as string[];
                    return (
                      <button key={s.set_id} onClick={() => setOpenSet(s)} className={`${cardBase} p-4 text-left hover:-translate-y-0.5 hover:border-primary-300 hover:shadow-lg`}>
                        <h3 className="font-medium text-surface-900 text-[13.5px] leading-snug line-clamp-2 min-h-[2.4em]">{s.normalized_title}</h3>
                        <div className="flex flex-wrap gap-1 mt-2">{fwc.slice(0, 4).map(f => <span key={f} className={chip}>{f}</span>)}{fwc.length > 4 && <span className={chip}>+{fwc.length - 4}</span>}</div>
                        <div className="mt-3 flex items-center gap-3 text-xs text-surface-500 border-t border-surface-100 pt-2">
                          <span className="text-primary-700 font-medium">{s.member_count} frameworks</span>
                          <span className="flex items-center gap-1"><FileText size={12} />{s.normalized_evidence.length}</span>
                          <span className="flex items-center gap-1"><Download size={12} />{s.normalized_artifacts.length}</span>
                        </div>
                      </button>
                    );
                  })}
                </div>
              )}
              {tab === 'standalone' && (
                <div className="flex gap-3 items-start">
                  <div className="flex-[0_0_32%] max-h-[560px] overflow-auto flex flex-col gap-1.5 pr-1">
                    {stdFwList.map(([f, items]) => (
                      <button key={f} onClick={() => setFwGroup(f)} className={`rounded-lg border bg-white px-3 py-2 flex justify-between items-center ${f === grp ? 'border-l-[3px] border-l-primary-600 bg-primary-50' : 'border-surface-200 hover:border-primary-300'}`}>
                        <span className="text-[12.5px] font-medium text-surface-800">{f}</span><span className="text-xs text-surface-400">{items.length}</span>
                      </button>
                    ))}
                  </div>
                  <div className="flex-1 max-h-[560px] overflow-auto rounded-xl border border-surface-200 bg-white p-4">
                    <div className="font-medium text-surface-900">{grp} <span className="text-surface-400 text-sm font-normal">· {(stdByFw[grp] || []).length} framework-unique controls</span></div>
                    <p className="text-xs text-surface-500 mb-2">Appear only in {grp} — no equivalent elsewhere, so not normalized.</p>
                    {(stdByFw[grp] || []).map((s: any, i: number) => (
                      <div key={i} className="border border-surface-200 rounded-lg px-2.5 py-2 mb-1.5">
                        <div className="text-[12px] font-medium text-surface-800">{s.members[0].control_id}</div>
                        <div className="text-[12px] text-surface-600 mt-0.5">{s.members[0].original_title}</div>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </>
          );
        })()}
      </div>

      {openSet && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-surface-900/40 p-4" onClick={() => setOpenSet(null)}>
          <div className="w-full max-w-2xl max-h-[85vh] overflow-auto rounded-2xl bg-white shadow-2xl" onClick={e => e.stopPropagation()}>
            <div className="sticky top-0 bg-white border-b border-surface-100 px-5 py-4 flex items-start justify-between">
              <div><div className="text-[10px] uppercase tracking-wide text-primary-600 font-medium">normalized set · {openSet.member_count} frameworks</div>
                <h2 className="text-base font-semibold text-surface-900 mt-0.5">{openSet.normalized_title}</h2></div>
              <button onClick={() => setOpenSet(null)} className="text-surface-400 hover:text-surface-700"><X size={18} /></button>
            </div>
            <div className="px-5 py-4">
              <div className="text-[11px] uppercase tracking-wide text-surface-400 mb-2 font-medium">Controls — one per framework (original titles kept)</div>
              {openSet.members.map((m: any, i: number) => (
                <div key={i} className="border border-surface-200 rounded-lg px-3 py-2 mb-1.5">
                  <div className="flex items-center gap-2 flex-wrap"><span className="text-[11px] font-medium text-primary-800 border border-primary-200 bg-primary-50 rounded px-1.5 py-0.5">{sf(m.framework)}</span><span className="text-[12.5px] font-medium text-surface-800">{m.control_id}</span></div>
                  <div className="text-[12.5px] text-surface-600 mt-0.5">{m.original_title}</div>
                </div>
              ))}
              <div className="text-[11px] uppercase tracking-wide text-surface-400 mt-4 mb-2 font-medium flex items-center gap-1.5"><FileText size={13} />Normalized evidence ({openSet.normalized_evidence.length})</div>
              {openSet.normalized_evidence.length === 0 && <p className="text-xs text-surface-400">evidence pending (source gap)</p>}
              {openSet.normalized_evidence.map((e: any, i: number) => (
                <div key={i} className="flex gap-2 items-start py-1 text-[12.5px] text-surface-700">
                  <CheckCircle2 size={14} className="text-primary-500 mt-0.5 shrink-0" />
                  <span>{e.name}
                    {e.absorbs && e.absorbs.length > 1 && <span className="ml-1.5 text-[10px] text-surface-400 border border-surface-200 rounded px-1" title={e.absorbs.join('  •  ')}>merged {e.absorbs.length}</span>}
                    {e.sources && e.sources.length > 1 && <span className="ml-1.5 text-[10px] text-surface-400 border border-surface-200 rounded px-1">{e.sources.length} frameworks</span>}
                  </span>
                </div>
              ))}
              {openSet.excluded_evidence && openSet.excluded_evidence.length > 0 && (
                <>
                  <div className="text-[11px] uppercase tracking-wide text-surface-400 mt-4 mb-2 font-medium flex items-center gap-1.5"><X size={13} />Excluded as off-topic ({openSet.excluded_evidence.length}) — kept transparent, never silently dropped</div>
                  {openSet.excluded_evidence.map((x: any, i: number) => (
                    <div key={i} className="flex gap-2 items-start py-1 text-[12px] text-surface-500"><X size={12} className="text-surface-300 mt-0.5 shrink-0" /><span><span className="line-through decoration-surface-300">{x.name}</span> <span className="text-surface-400">— {x.reason}</span></span></div>
                  ))}
                </>
              )}
              <div className="text-[11px] uppercase tracking-wide text-surface-400 mt-4 mb-2 font-medium flex items-center gap-1.5"><Download size={13} />Requirement-specific artifacts ({openSet.normalized_artifacts.length})</div>
              {openSet.normalized_artifacts.length === 0 && <p className="text-xs text-surface-400">No requirement-specific artifacts — supporting templates for this set's frameworks are listed under the domain's framework-level catalogs.</p>}
              {openSet.normalized_artifacts.map((a: any, i: number) => (
                <div key={i} className="flex gap-2 items-start py-1 text-[12.5px] text-surface-700"><Download size={13} className="text-surface-400 mt-0.5 shrink-0" /><span>{a.name} <span className="text-surface-400">[{a.type}]</span></span></div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

'use client';

/**
 * AssetCveSidebar — an in-page left rail (distinct from the app nav) listing assets and
 * their CVEs. Shared by the Vulnerability Register scan screen (pick an asset to plan+scan)
 * and the AI-Pentest exploit page (pick an asset to gate+exploit). Presentational: all data
 * and selection arrive as props. `headerExtra` lets a page mount an ad-hoc-target input above
 * the list (register) or leave it out (exploit page).
 */
import { useMemo, useState } from 'react';
import { Server, Globe, Search } from 'lucide-react';

export interface SidebarAsset {
  id: number;
  label: string;
  sub?: string | null;          // ip / type / host
  findingCount?: number;
  cves?: string[];              // distinct CVE ids on this asset (first few shown)
  adhoc?: boolean;
}

const AC = '#005B96', ACSOFT = '#EFF5FA', BORDER = '#E8ECEE', INK = '#0F1F2B', MUTED = '#8A95A1', FAINT = '#AEB8C2';

export function AssetCveSidebar({
  assets, selectedId, onSelect, title = 'Assets', emptyText = 'No assets.', headerExtra, loading = false,
}: {
  assets: SidebarAsset[];
  selectedId: number | null;
  onSelect: (id: number) => void;
  title?: string;
  emptyText?: string;
  headerExtra?: React.ReactNode;
  loading?: boolean;
}) {
  const [q, setQ] = useState('');
  const list = useMemo(() => {
    const t = q.trim().toLowerCase();
    if (!t) return assets;
    return assets.filter((a) => `${a.label} ${a.sub || ''} ${(a.cves || []).join(' ')}`.toLowerCase().includes(t));
  }, [assets, q]);

  return (
    <aside style={{ width: 268, flexShrink: 0, display: 'flex', flexDirection: 'column', background: '#fff', border: `1px solid ${BORDER}`, borderRadius: 14, overflow: 'hidden' }}>
      <div style={{ padding: '11px 13px', borderBottom: `1px solid ${BORDER}` }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 9 }}>
          <span style={{ fontSize: 12.5, fontWeight: 700, color: INK }}>{title}</span>
          <span style={{ fontSize: 11, color: FAINT }}>{assets.length}</span>
        </div>
        <div style={{ position: 'relative' }}>
          <Search size={14} style={{ position: 'absolute', left: 9, top: 9, color: FAINT }} />
          <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search asset or CVE…"
            style={{ width: '100%', height: 32, border: `1px solid ${BORDER}`, borderRadius: 8, padding: '0 10px 0 28px', fontSize: 12, outline: 'none', color: INK }} />
        </div>
        {headerExtra && <div style={{ marginTop: 9 }}>{headerExtra}</div>}
      </div>
      <div style={{ flex: 1, minHeight: 0, overflowY: 'auto', padding: 7 }}>
        {loading ? (
          <div style={{ padding: 22, textAlign: 'center', fontSize: 12, color: FAINT }}>Loading…</div>
        ) : list.length === 0 ? (
          <div style={{ padding: 22, textAlign: 'center', fontSize: 12, color: FAINT }}>{emptyText}</div>
        ) : list.map((a) => {
          const sel = a.id === selectedId;
          const Icon = a.adhoc ? Globe : Server;
          return (
            <button key={a.id} onClick={() => onSelect(a.id)}
              style={{ display: 'flex', flexDirection: 'column', gap: 5, width: '100%', textAlign: 'left', border: `1px solid ${sel ? '#9cc3de' : 'transparent'}`, background: sel ? ACSOFT : 'transparent', borderRadius: 10, padding: '8px 9px', marginBottom: 2, cursor: 'pointer', fontFamily: 'inherit' }}>
              <span style={{ display: 'flex', alignItems: 'center', gap: 8, minWidth: 0 }}>
                <span style={{ display: 'grid', placeItems: 'center', height: 24, width: 24, borderRadius: 6, background: sel ? AC : ACSOFT, color: sel ? '#fff' : AC, flexShrink: 0 }}><Icon size={13} /></span>
                <span style={{ minWidth: 0, flex: 1 }}>
                  <span style={{ display: 'block', fontSize: 12, fontWeight: 600, color: INK, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{a.label}</span>
                  {a.sub && <span style={{ display: 'block', fontSize: 9.5, color: FAINT, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', fontFamily: 'ui-monospace,Consolas,monospace' }}>{a.sub}</span>}
                </span>
                {a.adhoc && <span style={{ fontSize: 8.5, fontWeight: 700, color: MUTED, background: '#EEF1F3', borderRadius: 5, padding: '2px 5px', flexShrink: 0 }}>AD-HOC</span>}
                {a.findingCount != null && <span style={{ fontSize: 11, fontWeight: 700, color: a.findingCount ? AC : FAINT, flexShrink: 0 }}>{a.findingCount}</span>}
              </span>
              {a.cves && a.cves.length > 0 && (
                <span style={{ display: 'flex', flexWrap: 'wrap', gap: 4, paddingLeft: 32 }}>
                  {a.cves.slice(0, 4).map((c) => <span key={c} style={{ fontSize: 9, fontFamily: 'ui-monospace,Consolas,monospace', color: '#2E63A8', background: '#EEF4FB', borderRadius: 4, padding: '1px 5px' }}>{c}</span>)}
                  {a.cves.length > 4 && <span style={{ fontSize: 9, color: FAINT }}>+{a.cves.length - 4}</span>}
                </span>
              )}
            </button>
          );
        })}
      </div>
    </aside>
  );
}

export default AssetCveSidebar;

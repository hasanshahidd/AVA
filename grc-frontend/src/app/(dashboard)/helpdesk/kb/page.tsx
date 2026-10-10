"use client";

import { useMemo, useState } from "react";
import { BookOpen, Search, FileText } from "lucide-react";
import { Chip, PageHeader, RefreshBtn, Empty, ErrorBanner, Loading, timeAgo, useHd } from "../_ui";

export default function KnowledgeBasePage() {
  const { data, loading, error, reload } = useHd<any>("/helpdesk/articles");
  const [q, setQ] = useState("");
  const articles: any[] = Array.isArray(data?.articles) ? data.articles : [];
  const groups = useMemo(() => {
    const s = q.toLowerCase();
    const m = new Map<string, any[]>();
    articles.filter((a) => !s || [a.title, a.category, a.author].some((v) => (v || "").toLowerCase().includes(s)))
      .forEach((a) => { const c = a.category || "Uncategorized"; m.set(c, [...(m.get(c) || []), a]); });
    return Array.from(m.entries()).sort((a, b) => a[0].localeCompare(b[0]));
  }, [articles, q]);

  return (
    <div className="space-y-5 p-6">
      <PageHeader icon={BookOpen} title="Knowledge Base" subtitle={`${articles.length} article${articles.length === 1 ? "" : "s"}`}
        actions={<>
          <div className="relative">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
            <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search articles…"
              className="w-72 rounded-lg border border-slate-200 bg-white py-1.5 pl-9 pr-3 text-sm outline-none focus:border-[var(--color-base)]" />
          </div>
          <RefreshBtn onClick={reload} loading={loading} />
        </>} />
      {error && <ErrorBanner msg={error} />}
      {loading ? <Loading what="articles" /> : groups.length === 0 ? <Empty icon={BookOpen} title="No articles found" hint={q ? "Try a different search." : undefined} /> : (
        <div className="space-y-6">
          {groups.map(([cat, list]) => (
            <section key={cat}>
              <div className="mb-2 flex items-center gap-2">
                <h2 className="text-base font-semibold text-[var(--color-text)]">{cat}</h2>
                <span className="rounded-full bg-slate-100 px-2 py-0.5 text-xs text-slate-500">{list.length}</span>
              </div>
              <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
                {list.map((a) => (
                  <div key={a.name} className="rounded-xl border border-slate-200 bg-white p-4 transition hover:shadow-sm">
                    <div className="flex items-start gap-3">
                      <FileText size={18} className="mt-0.5 shrink-0 text-slate-400" />
                      <div className="min-w-0 flex-1">
                        <div className="truncate font-medium text-[var(--color-text)]">{a.title || a.name}</div>
                        <div className="mt-1 text-xs text-slate-500">{a.author || "Unknown author"} · updated {timeAgo(a.modified)}</div>
                      </div>
                      <Chip value={a.status || "Draft"} />
                    </div>
                  </div>
                ))}
              </div>
            </section>
          ))}
        </div>
      )}
    </div>
  );
}

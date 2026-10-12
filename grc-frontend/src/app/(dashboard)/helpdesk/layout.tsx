"use client";

// Help Desk area chrome: a secondary nav shared by every Help Desk page
// (Overview / Tickets / Dashboard / Settings). The global app sidebar still
// wraps this via the (dashboard) layout; this adds the Help-Desk-local tabs so
// the admin pages are reachable without touching global navigation.
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Home, Ticket, BarChart3, Settings, LifeBuoy } from "lucide-react";

const TABS = [
  { href: "/helpdesk/home", label: "Overview", icon: Home },
  { href: "/helpdesk/tickets", label: "Tickets", icon: Ticket },
  { href: "/helpdesk/dashboard", label: "Dashboard", icon: BarChart3 },
  { href: "/helpdesk/settings", label: "Settings", icon: Settings },
];

export default function HelpDeskLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname() || "";
  return (
    <div className="mx-auto flex w-full max-w-[1600px] flex-col gap-4">
      <div className="flex flex-wrap items-center gap-3 border-b border-[#E2E5EC] pb-2">
        <div className="mr-2 flex items-center gap-2 text-[#005B96]">
          <LifeBuoy size={18} strokeWidth={1.9} />
          <span className="text-[13px] font-semibold tracking-tight">Help Desk</span>
        </div>
        <nav className="flex flex-wrap items-center gap-1">
          {TABS.map((t) => {
            const active = pathname === t.href || pathname.startsWith(t.href + "/");
            const Icon = t.icon;
            return (
              <Link
                key={t.href}
                href={t.href}
                className={`inline-flex items-center gap-1.5 rounded-[9px] px-3 py-1.5 text-[12.5px] font-semibold transition ${
                  active ? "bg-[#005B96]/10 text-[#005B96]" : "text-[#64748B] hover:bg-[#F6F7FB] hover:text-[#334155]"
                }`}
              >
                <Icon size={14} /> {t.label}
              </Link>
            );
          })}
        </nav>
      </div>
      <div>{children}</div>
    </div>
  );
}

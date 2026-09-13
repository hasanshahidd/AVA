'use client';

import { FormEvent, useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { useQueryClient } from '@tanstack/react-query';
import clsx from 'clsx';
import { AlertCircle, CheckCircle2, Eye, EyeOff, Lock, Mail } from 'lucide-react';
import { MascotFront, MascotSide } from '@/components/auth/mascots';
import './login.css';

// Bare IPv4 hosts (e.g. 68.183.198.54 in IP-only deployments) split into
// 4 numeric parts — without the guard below, parts[0] would be treated
// as a tenant slug ("68"), which is obviously wrong.
const _IPV4_RE = /^\d{1,3}(?:\.\d{1,3}){3}$/;

function getTenantSlugFromHost(): string | null {
  if (typeof window === 'undefined') return null;
  const host = window.location.hostname.toLowerCase();
  if (host === 'localhost' || host === '127.0.0.1') return null;
  if (_IPV4_RE.test(host)) return null;
  if (host.endsWith('.localhost')) {
    const parts = host.split('.');
    if (parts.length === 2) return parts[0];
  }
  const parts = host.split('.');
  if (parts.length >= 3) return parts[0];
  return null;
}

function getTenantSlug(): string | null {
  if (typeof window === 'undefined') return null;

  const urlParams = new URLSearchParams(window.location.search);
  const urlTenant = urlParams.get('tenant');
  if (urlTenant) {
    localStorage.setItem('tenant_slug', urlTenant);
    return urlTenant;
  }

  const hostTenant = getTenantSlugFromHost();
  if (hostTenant) {
    localStorage.setItem('tenant_slug', hostTenant);
    return hostTenant;
  }

  // Do not reuse stale tenant_slug for login; let backend resolve by email domain
  localStorage.removeItem('tenant_slug');
  return null;
}

const SOURCES: [name: string, desc: string, domain: string][] = [
  ['MITRE ATT&CK', 'Adversary techniques', 'attack.mitre.org'],
  ['CVE', 'Vulnerability catalog', 'cve.org'],
  ['CISA KEV', 'Known exploited', 'cisa.gov'],
  ['EPSS', 'Exploit probability', 'first.org'],
  ['NVD', 'CVSS enrichment', 'nvd.nist.gov'],
  ['CWE', 'Weakness types', 'cwe.mitre.org'],
  ['Shodan', 'Exposure intel', 'shodan.io'],
  ['Censys', 'Internet scan data', 'censys.io'],
  ['crt.sh', 'Certificate transparency', 'crt.sh'],
  ['SecurityTrails', 'DNS & asset intel', 'securitytrails.com'],
  ['CIS Benchmarks', 'Hardening baselines', 'cisecurity.org'],
  ['OWASP', 'App security', 'owasp.org'],
  ['NIST CSF', 'Cyber framework', 'nist.gov'],
];
const fav = (domain: string) => `https://www.google.com/s2/favicons?sz=128&domain=${domain}`;

const CHIPS = ['Exposure Monitoring', 'Exploit Alerts', 'Vulnerabilities', 'Connectors', 'IT Asset Discovery', 'Inventory', 'CVEs'];

export default function LoginPage() {
  const searchParams = useSearchParams();
  const queryClient = useQueryClient();

  const [showPw, setShowPw] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [passwordInvalid, setPasswordInvalid] = useState(false);
  const [info, setInfo] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [ssoRedirecting, setSsoRedirecting] = useState(false);
  const ssoTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const [tenantSlug, setTenantSlug] = useState<string | null>(null);
  const [tenantName, setTenantName] = useState<string | null>(null);
  // True only when ?tenant= was used — host-derived tenants should not change
  // the heading (keeps subdomain login visually identical to localhost).
  const [tenantFromQuery, setTenantFromQuery] = useState(false);
  const [registrationOpen, setRegistrationOpen] = useState(false);

  // Intro curtain plays on EVERY load, staged so the fast movements (mascot
  // walk-off at 1.6s, panel slide at 3.8s — timings mirrored in login.css)
  // never compete for frames with hidden work:
  //   curtain (0–1.05s) — only the blue curtain + mascots exist; nothing
  //                       rasterizes behind the opaque panel.
  //   reveal  (1.05s)   — the heavy background mounts and takes its one-time
  //                       raster hit during the calm standing-and-waving
  //                       moment, NOT mid-walk (that commit landing inside
  //                       the walk was itself a visible stutter). It stays
  //                       covered until the slide reveals it.
  //   done    (9.3s)    — curtain unmounts (slide ends 7.6s, peeker climb
  //                       8.9s) and its looping animations stop for good.
  const [stage, setStage] = useState<'curtain' | 'reveal' | 'done'>('curtain');
  useEffect(() => {
    const t1 = setTimeout(() => setStage('reveal'), 1050);
    const t2 = setTimeout(() => setStage('done'), 9300);
    return () => { clearTimeout(t1); clearTimeout(t2); };
  }, []);
  const intro = stage !== 'done';
  const bgLive = stage !== 'curtain';

  // Warm the favicon cache while the curtain still hides the marquee, so
  // mounting it paints from memory instead of popping in mid-slide.
  useEffect(() => {
    SOURCES.forEach(([, , domain]) => { const img = new Image(); img.src = fav(domain); });
  }, []);

  useEffect(() => {
    const urlParams = new URLSearchParams(window.location.search);
    const fromQuery = Boolean(urlParams.get('tenant'));
    setTenantFromQuery(fromQuery);

    const slug = getTenantSlug();
    setTenantSlug(slug);
    const name = localStorage.getItem('tenant_name');
    setTenantName(name);

    // Just registered? Show a confirmation banner and pre-fill the email.
    if (searchParams?.get('registered') === '1') {
      const prefill = searchParams.get('email') || '';
      if (prefill) setEmail(prefill);
      setInfo('Account created. Sign in with the password you just set.');
    }

    // Surface SSO callback errors (e.g. domain not allowed, token exchange failure)
    const ssoErr = searchParams?.get('error');
    if (ssoErr) {
      const map: Record<string, string> = {
        sso_not_provisioned: "Your Microsoft account isn't allowed to sign in to this organization. Contact your administrator.",
        sso_state_mismatch: 'Sign-in expired or was tampered with. Please try again.',
        sso_state_expired: 'Sign-in expired. Please try again.',
        sso_invalid_callback: 'Microsoft sign-in failed (invalid callback).',
        sso_provider_error: 'Microsoft returned an error. Please try again.',
        sso_token_exchange_failed: 'Microsoft rejected the sign-in request. Contact your administrator.',
        sso_id_token_invalid: 'Microsoft sign-in could not be verified. Contact your administrator.',
        sso_disabled: 'Microsoft sign-in is not enabled for this organization.',
        sso_tenant_lost: 'Could not resolve your organization. Please try again.',
      };
      setError(map[ssoErr] || 'Microsoft sign-in failed.');
    }
  }, [searchParams]);

  // Fail closed: only show Register organization when the backend says so.
  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const res = await fetch('/api/auth/registration-status', { credentials: 'include' });
        if (!res.ok) return;
        const data = await res.json();
        if (!cancelled) setRegistrationOpen(Boolean(data?.open));
      } catch {
        // leave closed
      }
    })();
    return () => { cancelled = true; };
  }, []);

  // If the user comes BACK from the Microsoft page (browser back button /
  // bfcache restore), the redirecting card would otherwise be stuck on
  // screen. pageshow with persisted=true fires exactly in that case.
  useEffect(() => {
    const onPageShow = (e: PageTransitionEvent) => {
      if (e.persisted) setSsoRedirecting(false);
    };
    window.addEventListener('pageshow', onPageShow);
    return () => {
      window.removeEventListener('pageshow', onPageShow);
      if (ssoTimer.current) clearTimeout(ssoTimer.current);
    };
  }, []);

  const handleSsoSignIn = () => {
    // Backend resolves tenant via subdomain or X-Tenant-Slug; we can't set
    // headers on a top-level navigation, so rely on the subdomain (or pass
    // ?tenant_slug= as a fallback).
    const slug = getTenantSlugFromHost() || tenantSlug;
    const url = slug
      ? `/api/auth/entra/login?tenant_slug=${encodeURIComponent(slug)}`
      : '/api/auth/entra/login';
    // Show the handoff card briefly before navigating so the user knows a
    // Microsoft window is about to take over (and can cancel).
    setError('');
    setSsoRedirecting(true);
    ssoTimer.current = setTimeout(() => {
      window.location.href = url;
    }, 900);
  };

  const cancelSsoSignIn = () => {
    if (ssoTimer.current) {
      clearTimeout(ssoTimer.current);
      ssoTimer.current = null;
    }
    setSsoRedirecting(false);
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');
    setPasswordInvalid(false);

    try {
      const headers: Record<string, string> = { 'Content-Type': 'application/json' };

      if (tenantSlug) {
        headers['X-Tenant-Slug'] = tenantSlug;
      } else {
        localStorage.removeItem('tenant_slug');
      }

      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers,
        body: JSON.stringify({ username: email, password }),
        credentials: 'include',
      });

      if (response.ok) {
        const data = await response.json();

        // CRITICAL: Clear ALL previous localStorage and sessionStorage to prevent cross-user data leakage
        localStorage.clear();
        sessionStorage.clear(); // Clears permission cache so new user gets fresh permissions

        // Bearer token from response body. Stored in localStorage so the axios
        // interceptor can stamp every request with `Authorization: Bearer ...`.
        // We don't rely on the Set-Cookie header alone because browsers reject
        // `Domain=localhost` cookies — the cookie would be silently discarded
        // and the user would bounce-loop on the dashboard.
        if (data.access_token) {
          localStorage.setItem('token', data.access_token);
        }

        if (data.tenant) {
          localStorage.setItem('tenant_slug', data.tenant.slug || data.tenant.subdomain || '');
          // tenant_subdomain is read by the 401 response interceptor to
          // detect wrong-subdomain bounces and redirect cleanly. Always
          // populate it (even if it equals tenant_slug, like in our default
          // setup where slug == subdomain).
          localStorage.setItem('tenant_subdomain', data.tenant.subdomain || data.tenant.slug || '');
          localStorage.setItem('tenant_name', data.tenant.name || '');
          localStorage.setItem('tenant_id', String(data.tenant.id || ''));
        }

        // Ensure no stale user/session data survives cross-account login.
        queryClient.clear();

        // ALWAYS do a full-page navigation to the canonical tenant URL after
        // login. Two reasons we don't use router.replace here:
        //
        //   1. If the current subdomain differs from the authenticated tenant
        //      (e.g. browser at acme.localhost, logged in as bob@layeron),
        //      we must change hostname so the axios interceptor reads the
        //      right slug from window.location. The interceptor in api.ts
        //      OVERWRITES localStorage.tenant_slug with the host-derived slug
        //      on every request, which silently breaks any cross-host
        //      `router.replace`.
        //   2. A full nav resets React state and React Query cache cleanly,
        //      so the new tenant context can't see any stale data from the
        //      previous user/tenant.
        const targetSub: string | undefined = data.tenant?.subdomain || data.tenant?.slug;
        const host = window.location.hostname.toLowerCase();
        const { protocol, port } = window.location;
        let currentSub: string | null = null;
        if (host.endsWith('.localhost')) {
          const parts = host.split('.');
          if (parts.length === 2) currentSub = parts[0];
        } else if (host !== 'localhost' && host !== '127.0.0.1' && !_IPV4_RE.test(host)) {
          // Skip IPv4 — first octet isn't a tenant slug.
          const parts = host.split('.');
          if (parts.length >= 3) currentSub = parts[0];
        }
        const baseHost = host.endsWith('.localhost')
          ? 'localhost'
          : (currentSub ? host.split('.').slice(-2).join('.') : host);
        // eslint-disable-next-line no-console
        console.log('[login] currentSub=%s targetSub=%s host=%s', currentSub, targetSub, host);

        // Subdomain-first tenant routing:
        //   - On `localhost` / `.localhost` hosts we ALWAYS redirect to
        //     `{tenant_subdomain}.localhost:{port}` so the browser hostname
        //     carries the tenant identity.
        //   - On dotted-domain hosts we redirect to `{subdomain}.example.com`
        //     when current ≠ target.
        //   - Bare IPv4 hosts STILL skip the redirect — prefixing the IP would
        //     produce an unreachable hostname like `company.68.183.198.54`.
        const isBareIPv4 = _IPV4_RE.test(host);
        const shouldRedirect = !!targetSub
          && !isBareIPv4
          && (currentSub !== targetSub);
        if (shouldRedirect) {
          // localStorage on the destination is a SEPARATE storage area
          // (per-origin), so we hand off the token + tenant context via
          // URL fragment. Fragments are not sent to the server, so the
          // token never leaks via access logs / proxies.
          const params = new URLSearchParams();
          if (data.access_token) params.set('auth_token', data.access_token);
          if (data.tenant?.slug) params.set('tenant_slug', data.tenant.slug);
          if (data.tenant?.subdomain) params.set('tenant_subdomain', data.tenant.subdomain);
          if (data.tenant?.name) params.set('tenant_name', data.tenant.name);
          if (data.tenant?.id != null) params.set('tenant_id', String(data.tenant.id));
          const dest = `${protocol}//${targetSub}.${baseHost}${port ? ':' + port : ''}/dashboard#${params.toString()}`;
          window.location.href = dest;
          return;
        }
        // Same tenant, OR bare-IP host where we can't redirect cross-subdomain —
        // still do a full nav to wipe React state.
        window.location.href = `${protocol}//${host}${port ? ':' + port : ''}/dashboard`;
        return;
      } else {
        const data = await response.json();
        if (response.status === 409) {
          setError(data.detail || 'Multiple organizations found. Please select your company and try again.');
        } else {
          setError(data.detail || 'Invalid credentials');
          // Outline the password field only for actual credential rejections
          // (401), not for lockouts (423) or tenant-resolution errors.
          if (response.status === 401) setPasswordInvalid(true);
        }
      }
    } catch {
      setError('An error occurred. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  const clearTenantContext = () => {
    // Clear ALL localStorage to ensure clean state
    localStorage.clear();
    setTenantSlug(null);
    setTenantName(null);
    setTenantFromQuery(false);
  };

  return (
    <div className="relative grid h-screen w-screen max-w-full grid-cols-[minmax(0,1fr)] grid-rows-[auto_minmax(0,1fr)_auto] overflow-hidden bg-white font-sans text-[#0A0B1A]">
      {intro && <IntroCurtain />}
      {bgLive && <RadarBackdrop />}

      {/* header */}
      <header className="lg-fade relative z-[2] flex items-center justify-end px-[clamp(1.5rem,4vw,3.5rem)] pb-[clamp(.6rem,1.4vh,1rem)] pt-[clamp(1rem,3.2vh,2.4rem)] [animation-delay:.05s]">
        <div className="inline-flex items-center gap-2 text-[.78rem] font-medium text-[#64748B]">
          <span className="h-[7px] w-[7px] rounded-full bg-[#005B96] shadow-[0_0_0_3px_rgba(0,91,150,.15)]" />
          Attack surface online
        </div>
      </header>

      {/* main */}
      <main className="relative grid min-h-0 min-w-0 grid-cols-[minmax(0,1.1fr)_minmax(0,.9fr)] items-center gap-[clamp(1.5rem,4vw,4rem)] px-[clamp(1.5rem,4vw,3.5rem)]">
        <Hero />
        <section className="flex min-w-0 justify-center">
          <div className="relative w-full max-w-[27rem] min-w-0">
            {/* peeker mascot: climbs up from behind the card after the intro */}
            <div
              className={clsx('pointer-events-none absolute -left-9 -top-12 z-[1] h-[108px] w-[90px]', intro ? 'lg-peeker' : 'lg-peeker-static')}
            >
              <div className={clsx('h-full w-full', intro ? 'lg-bob' : 'lg-bob-now')}>
                <MascotFront variant="blue" className="h-full w-full" />
              </div>
            </div>
            {ssoRedirecting ? (
              <SsoHandoffCard tenantName={tenantName} tenantSlug={tenantSlug} onCancel={cancelSsoSignIn} />
            ) : (
              <LoginCard
                showPw={showPw}
                onTogglePw={() => setShowPw(v => !v)}
                email={email}
                password={password}
                onEmail={setEmail}
                onPassword={(v) => { setPassword(v); setPasswordInvalid(false); }}
                onSubmit={handleSubmit}
                onMicrosoft={handleSsoSignIn}
                pending={isLoading}
                error={error}
                info={info}
                passwordInvalid={passwordInvalid}
                tenantFromQuery={tenantFromQuery}
                tenantName={tenantName}
                tenantSlug={tenantSlug}
                onSwitch={clearTenantContext}
                registrationOpen={registrationOpen}
              />
            )}
          </div>
        </section>
      </main>

      {/* threat intelligence marquee */}
      <footer className="lg-fade relative z-[1] min-w-0 pb-3 pt-1 text-center [animation-delay:.6s]">
        <p className="mb-1.5 text-[.66rem] font-semibold uppercase tracking-[.2em] text-[#94A3B8]">Threat intelligence built in</p>
        <div className="lg-mask relative mx-auto min-h-[50px] w-[min(92%,74rem)] overflow-hidden">
          {bgLive && (
            <>
              <div className="lg-beam pointer-events-none absolute bottom-0 left-0 top-0 z-[2] w-[110px] [background:linear-gradient(to_right,transparent,rgba(0,91,150,.1)_40%,rgba(50,121,163,.26)_50%,rgba(0,91,150,.1)_60%,transparent)]" />
              <div className="lg-marq-slow flex w-max gap-2.5 py-1">
                {[...SOURCES, ...SOURCES].map(([n, d, dom], i) => (
                  <div key={i} className="flex items-center gap-2 whitespace-nowrap rounded-[14px] border border-[#EAECF2] bg-white py-1.5 pl-1.5 pr-4 shadow-[0_6px_16px_-12px_rgba(10,11,26,.35)]">
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img src={fav(dom)} alt="" className="h-7 w-7 rounded-[7px] bg-[#F8FAFC] p-0.5" />
                    <span className="flex flex-col text-left leading-tight">
                      <span className="text-[.8rem] font-semibold text-[#0A0B1A]">{n}</span>
                      <span className="text-[.66rem] text-[#64748B]">{d}</span>
                    </span>
                  </div>
                ))}
              </div>
            </>
          )}
        </div>
      </footer>
    </div>
  );
}

function Hero() {
  return (
    <section className="flex min-w-0 max-w-[36rem] flex-col gap-[clamp(.6rem,1.7vh,1.15rem)]">
      <div className="lg-fade inline-flex items-center gap-3 [animation-delay:.06s]">
        <LogoMark className="lg-logo-spin h-11 w-11" />
        <span className="inline-flex items-center gap-2">
          <span className="text-[2.7rem] font-extrabold tracking-[-.03em]">Ava</span>
          <span className="rounded-[9px] bg-[#005B96] px-2 py-1 text-[.9rem] font-bold tracking-[.09em] text-white">AI</span>
        </span>
      </div>
      <div className="lg-fade inline-flex items-center gap-3 [animation-delay:.12s]">
        <span className="h-px w-8 bg-[#005B96]" />
        <span className="text-[.72rem] font-semibold uppercase tracking-[.22em] text-[#014A81]">AI-native cybersecurity assurance</span>
      </div>
      <h1 className="lg-fade m-0 text-balance text-[clamp(1.75rem,3.2vw,2.85rem)] font-bold leading-[1.05] tracking-[-.035em] [animation-delay:.2s]">
        See your <span className="text-[#005B96]">attack surface</span> the way attackers do.
      </h1>
      <p className="lg-fade m-0 text-[clamp(1.05rem,1.6vw,1.35rem)] text-[#475569] [animation-delay:.28s]">
        Every exposure. <b className="font-semibold text-[#005B96]">One view.</b>
      </p>
      <div className="lg-fade lg-mask max-w-[33rem] overflow-hidden [animation-delay:.36s]">
        <div className="lg-marq-chips flex w-max gap-2 py-0.5">
          {[...CHIPS, ...CHIPS].map((c, i) => (
            <span key={i} className="inline-flex items-center whitespace-nowrap rounded-xl border border-[#E2E8F0] bg-white px-3 py-1.5 text-[.8rem] font-medium text-[#334155]">{c}</span>
          ))}
        </div>
      </div>
      <div className="lg-fade flex items-center gap-3.5 text-[.82rem] font-medium text-[#475569] [animation-delay:.44s]">
        <span><b className="font-semibold text-[#0A0B1A]">Outside-in</b> discovery</span>
        <span className="h-3.5 w-px bg-[#CBD5E1]" />
        <span>AI-native</span>
        <span className="h-3.5 w-px bg-[#CBD5E1]" />
        <span><b className="font-semibold text-[#0A0B1A]">Continuous</b> monitoring</span>
      </div>
      <p className="lg-fade m-0 mt-1 max-w-[26rem] text-[.98rem] font-medium text-[#334155] [animation-delay:.52s]">
        Continuous assurance for your external attack surface.
      </p>
    </section>
  );
}

function LoginCard(props: {
  showPw: boolean; onTogglePw: () => void;
  email: string; password: string;
  onEmail: (v: string) => void; onPassword: (v: string) => void;
  onSubmit: (e: FormEvent) => void; onMicrosoft: () => void; pending: boolean;
  error: string; info: string; passwordInvalid: boolean;
  tenantFromQuery: boolean; tenantName: string | null; tenantSlug: string | null;
  onSwitch: () => void; registrationOpen: boolean;
}) {
  const input =
    'w-full rounded-[14px] border border-[#E2E8F0] bg-white py-[clamp(.5rem,1.5vh,.78rem)] text-[.92rem] text-[#0A0B1A] outline-none transition ' +
    'focus:border-[#005B96] focus:shadow-[0_0_0_4px_rgba(0,91,150,.14)]';
  const invalid = 'border-[#FB7185] focus:border-[#F43F5E] focus:shadow-[0_0_0_4px_rgba(244,63,94,.14)]';
  return (
    <div className="relative z-[2] w-full rounded-3xl border border-[rgba(10,11,26,.07)] bg-white px-8 py-[clamp(.8rem,2.2vh,1.6rem)] shadow-[0_1px_2px_rgba(10,11,26,.04),0_30px_60px_-30px_rgba(0,91,150,.28)]">
      <div className="absolute left-3.5 top-3.5 h-3 w-3 border-l-[1.5px] border-t-[1.5px] border-[rgba(0,91,150,.28)]" />
      <div className="absolute bottom-3.5 right-3.5 h-3 w-3 border-b-[1.5px] border-r-[1.5px] border-[rgba(0,91,150,.28)]" />

      <div className="mb-[clamp(.32rem,1.1vh,.7rem)] inline-flex items-center gap-2 text-[.68rem] font-semibold uppercase tracking-[.14em] text-[#014A81]">
        <Lock size={13} strokeWidth={2.2} className="text-[#005B96]" /> Secure sign-in
      </div>
      <h2 className="m-0 mb-1 text-[clamp(1.38rem,2.6vh,1.7rem)] font-bold tracking-[-.02em]">Welcome back</h2>
      <p className="m-0 mb-[clamp(.48rem,1.7vh,1.1rem)] text-[.9rem] text-[#64748B]">
        {props.tenantFromQuery ? (
          <>
            Sign in to <span className="font-semibold text-[#0A0B1A]">{props.tenantName || props.tenantSlug}</span>
            <span className="mx-1.5 text-[#CBD5E1]">·</span>
            <button type="button" onClick={props.onSwitch} className="font-semibold text-[#005B96] underline-offset-2 hover:underline">Switch</button>
          </>
        ) : (
          'Sign in to your Ava workspace.'
        )}
      </p>

      {/* Banners — success (just registered) or error, matched to the card look */}
      {props.info && !props.error && (
        <div className="mb-[clamp(.4rem,1.4vh,.85rem)] flex items-start gap-2 rounded-[14px] border border-emerald-200 bg-emerald-50 px-3.5 py-2.5 text-emerald-700">
          <CheckCircle2 size={15} className="mt-0.5 shrink-0" />
          <span className="text-[.76rem] leading-relaxed">{props.info}</span>
        </div>
      )}
      {props.error && (
        <div className="mb-[clamp(.4rem,1.4vh,.85rem)] flex items-start gap-2.5 rounded-[14px] border border-rose-200 bg-rose-50 px-3.5 py-2.5">
          <AlertCircle size={15} className="mt-0.5 shrink-0 text-rose-600" />
          <div>
            <p className="text-[.76rem] font-semibold text-rose-700">We couldn&apos;t sign you in</p>
            <p className="mt-0.5 text-[.76rem] leading-relaxed text-rose-600">{props.error}</p>
          </div>
        </div>
      )}

      <button type="button" onClick={props.onMicrosoft} className="flex w-full items-center justify-center gap-2.5 rounded-[14px] border border-[#E2E8F0] bg-white px-4 py-[clamp(.48rem,1.4vh,.78rem)] text-[.92rem] font-medium transition hover:border-[#C7CBD4] hover:bg-[#FBFBFE]">
        <MicrosoftLogo /> Sign in with Microsoft
      </button>

      <div className="my-[clamp(.38rem,1.4vh,.95rem)] flex items-center gap-3">
        <span className="h-px flex-1 bg-[#E2E8F0]" />
        <span className="text-[.66rem] font-semibold tracking-[.14em] text-[#94A3B8]">OR CONTINUE WITH EMAIL</span>
        <span className="h-px flex-1 bg-[#E2E8F0]" />
      </div>

      <form onSubmit={props.onSubmit}>
        <label htmlFor="email" className="mb-1 ml-0.5 block text-[.78rem] font-medium text-[#334155]">Email</label>
        <div className="relative mb-[clamp(.4rem,1.3vh,.85rem)]">
          <Mail size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[#94A3B8]" />
          <input id="email" type="email" required autoComplete="email" placeholder="you@company.com" value={props.email} onChange={e => props.onEmail(e.target.value)} className={clsx(input, 'pl-10 pr-3.5')} />
        </div>

        <label htmlFor="password" className="mb-1 ml-0.5 block text-[.78rem] font-medium text-[#334155]">Password</label>
        <div className="relative mb-[clamp(.48rem,1.6vh,1.05rem)]">
          <Lock size={16} className={clsx('absolute left-3.5 top-1/2 -translate-y-1/2', props.passwordInvalid ? 'text-[#FB7185]' : 'text-[#94A3B8]')} />
          <input id="password" type={props.showPw ? 'text' : 'password'} required autoComplete="current-password" placeholder="Enter your password" value={props.password} onChange={e => props.onPassword(e.target.value)} className={clsx(input, 'pl-10 pr-10', props.passwordInvalid && invalid)} />
          <button type="button" aria-label="Toggle password visibility" onClick={props.onTogglePw} className="absolute right-2 top-1/2 flex -translate-y-1/2 rounded-md p-1.5 text-[#94A3B8] hover:text-[#005B96]">
            {props.showPw ? <EyeOff size={17} /> : <Eye size={17} />}
          </button>
        </div>
        {props.passwordInvalid && (
          <p className="-mt-[clamp(.2rem,.8vh,.6rem)] mb-2 flex items-center gap-1 text-[.72rem] text-rose-600">
            <AlertCircle size={12} className="shrink-0" /> Incorrect password
          </p>
        )}

        <button type="submit" disabled={props.pending} className="w-full rounded-[14px] bg-[#005B96] py-[clamp(.55rem,1.7vh,.88rem)] text-[.98rem] font-semibold text-white shadow-[0_8px_20px_-8px_rgba(0,91,150,.6)] transition hover:bg-[#014A81] disabled:opacity-60">
          {props.pending ? 'Signing in…' : 'Sign in →'}
        </button>
      </form>

      {/* Recovery path for locked accounts — support is the only reset
          mechanism today (there is no self-service password-reset route). */}
      {props.error && (
        <p className="m-0 mt-[clamp(.4rem,1.3vh,.9rem)] text-center text-[.76rem] text-[#94A3B8]">
          Locked out?{' '}
          <a href="mailto:support@ava.ai?subject=Account%20locked%20—%20password%20reset" className="font-semibold text-[#005B96] hover:underline">Reset your password</a>
        </p>
      )}

      {props.registrationOpen && (
        <p className="m-0 mt-[clamp(.35rem,1.1vh,.7rem)] text-center text-[.8rem] text-[#64748B]">
          New organization?{' '}
          <Link href="/register" className="font-semibold text-[#005B96] underline-offset-2 hover:underline">Register organization</Link>
        </p>
      )}

      <p className="m-0 mt-[clamp(.4rem,1.3vh,.9rem)] text-center text-[.76rem] leading-[1.48] text-[#94A3B8]">
        By signing in you agree to our{' '}
        <a href="https://ava.ai/terms" target="_blank" rel="noopener noreferrer" className="text-[#005B96] hover:underline">Terms</a> and{' '}
        <a href="https://ava.ai/privacy-policy" target="_blank" rel="noopener noreferrer" className="text-[#005B96] hover:underline">Privacy Policy</a>.<br />
        Trouble signing in? <a href="mailto:support@ava.ai" className="text-[#005B96] hover:underline">Contact support</a>
      </p>
    </div>
  );
}

// Shown while we bounce to Microsoft — same card shell as the login card so the
// SSO handoff stays on-brand (the redesign has no separate handoff screen).
function SsoHandoffCard({ tenantName, tenantSlug, onCancel }: { tenantName: string | null; tenantSlug: string | null; onCancel: () => void; }) {
  return (
    <div className="relative z-[2] w-full rounded-3xl border border-[rgba(10,11,26,.07)] bg-white px-8 py-10 text-center shadow-[0_1px_2px_rgba(10,11,26,.04),0_30px_60px_-30px_rgba(0,91,150,.28)]">
      <div className="relative mx-auto mb-6 h-16 w-16">
        <div className="absolute inset-0 animate-spin rounded-full border-2 border-[#DCE9F3] border-t-[#005B96]" />
        <div className="absolute inset-2 flex items-center justify-center rounded-full bg-white shadow-sm">
          <MicrosoftLogo />
        </div>
      </div>
      <h2 className="m-0 text-[1.4rem] font-bold tracking-[-.02em]">Redirecting to Microsoft…</h2>
      <p className="mx-auto mt-2 max-w-xs text-[.9rem] leading-relaxed text-[#64748B]">
        A Microsoft window will open to sign you in
        {tenantSlug ? (<> to <span className="font-semibold text-[#334155]">{tenantName || tenantSlug}</span></>) : null}
        . Approve the request to continue.
      </p>
      <div className="mt-6 inline-flex items-center gap-1.5 rounded-full bg-[#EFF5FA] px-3.5 py-1.5 text-[11px] font-medium text-[#014A81]">
        <Lock size={11} strokeWidth={2} /> Secure, audit-logged connection
      </div>
      <div className="mt-6">
        <button type="button" onClick={onCancel} className="text-xs font-medium text-[#64748B] underline-offset-2 hover:text-[#334155] hover:underline">Cancel and go back</button>
      </div>
    </div>
  );
}

function IntroCurtain() {
  return (
    <div className="lg-curtain fixed inset-0 z-[60] flex flex-col items-center justify-center gap-6 bg-gradient-to-br from-[#3279A3] via-[#005B96] to-[#014A81]">
      {/* trailing-edge shade — replaces the old full-viewport 90px box-shadow
          (same visible band over the revealed page, tiny GPU cost) */}
      <div className="pointer-events-none absolute inset-y-0 left-0 w-[110px] -translate-x-full [background:linear-gradient(to_left,rgba(1,31,75,.38),rgba(1,31,75,.12)_55%,transparent)]" />
      {/* white mascot standing on a 3D base; walks off left, then the blue pusher takes over */}
      <div className="relative flex w-[150px] flex-col items-center">
        <div className="lg-walkout">
          <div className="lg-waddle">
            <MascotFront variant="white" className="h-[114px] w-[100px]" />
          </div>
        </div>
        <div className="-mt-2.5 h-[26px] w-[120px] rounded-full shadow-[0_14px_28px_-6px_rgba(1,25,58,.55)] [background:radial-gradient(ellipse_at_50%_38%,rgba(255,255,255,.34),rgba(255,255,255,.05)_62%,transparent_74%)]" />
      </div>
      <div className="inline-flex items-center gap-2 text-[2.5rem] font-extrabold tracking-[-.03em] text-white">
        Ava <span className="rounded-lg bg-white px-2 py-1 text-[.92rem] font-bold tracking-[.08em] text-[#005B96]">AI</span>
      </div>
      <div className="text-[.72rem] font-semibold uppercase tracking-[.24em] text-white/70">Scanning IT assets · Continuous assurance</div>
      {/* blue pusher anchored to the panel's left edge — rides the panel as it slides off */}
      <div className="lg-pusher pointer-events-none absolute bottom-[4.5vh] left-[-86px] h-[106px] w-[92px]">
        <div className="lg-waddle h-full w-full">
          <MascotSide className="h-full w-full" />
        </div>
      </div>
    </div>
  );
}

function LogoMark({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 32 32" className={className}>
      <circle cx="16" cy="16" r="14" fill="none" stroke="#005B96" strokeWidth="2" opacity=".28" />
      <circle cx="16" cy="16" r="8.5" fill="none" stroke="#005B96" strokeWidth="2" opacity=".55" />
      <path d="M16 16 L28 6" stroke="#005B96" strokeWidth="2" strokeLinecap="round" />
      <circle cx="16" cy="16" r="3" fill="#005B96" />
      <circle cx="26.5" cy="7.5" r="2.6" fill="#6497B1" />
    </svg>
  );
}

function MicrosoftLogo() {
  return (
    <svg width="17" height="17" viewBox="0 0 23 23">
      <path fill="#f35325" d="M1 1h10v10H1z" /><path fill="#81bc06" d="M12 1h10v10H12z" />
      <path fill="#05a6f0" d="M1 12h10v10H1z" /><path fill="#ffba08" d="M12 12h10v10H12z" />
    </svg>
  );
}

function RadarBackdrop() {
  // Perf-critical layer. Every continuously-moving piece is an HTML element
  // animating only transform/opacity, so it runs on the compositor thread:
  //  - the ping ring + blips used to be shapes INSIDE the <svg>; animating
  //    those repaints the whole ~780px graphic on the main thread every
  //    frame. The SVG is now fully static and never repaints.
  //  - the glows lost their blur() filters — the radial gradients already
  //    fade softly, and half-viewport blurs are what crushed weak GPUs.
  //  - the scan sheen is viewport-sized (its gradient edges are transparent,
  //    so the old 150% oversize bought nothing but GPU memory).
  const blip = (left: string, top: string, size: string, color: string, delay: string) => (
    <div
      key={delay}
      className="lg-blip absolute rounded-full"
      style={{ left, top, width: size, height: size, background: color, animationDelay: delay }}
    />
  );
  return (
    <div className="pointer-events-none absolute inset-0 z-0 overflow-hidden">
      <div className="absolute right-[-9%] top-[46%] h-[min(84vh,780px)] w-[min(84vh,780px)] -translate-y-1/2">
        <svg viewBox="0 0 200 200" className="absolute inset-0 h-full w-full">
          {[30, 55, 80, 97].map((r, i) => (
            <circle key={r} cx="100" cy="100" r={r} fill="none" stroke={`rgba(0,91,150,${[0.13, 0.11, 0.09, 0.07][i]})`} strokeWidth="1" />
          ))}
          <circle cx="100" cy="100" r="68" fill="none" stroke="rgba(0,91,150,.16)" strokeWidth="1" strokeDasharray="1.5 7" />
          <line x1="3" y1="100" x2="197" y2="100" stroke="rgba(0,91,150,.07)" strokeWidth="1" />
          <line x1="100" y1="3" x2="100" y2="197" stroke="rgba(0,91,150,.07)" strokeWidth="1" />
          <line x1="30" y1="30" x2="170" y2="170" stroke="rgba(0,91,150,.045)" strokeWidth="1" />
          <line x1="170" y1="30" x2="30" y2="170" stroke="rgba(0,91,150,.045)" strokeWidth="1" />
          <circle cx="100" cy="100" r="3" fill="#005B96" />
        </svg>
        {/* expanding ping ring — same geometry as the old r=30 SVG circle */}
        <div className="lg-ping absolute left-[35%] top-[35%] h-[30%] w-[30%] rounded-full border-[5px] border-[#005B96]" />
        {blip('68%', '34.5%', '3%', '#005B96', '0s')}
        {blip('31.7%', '64.7%', '2.6%', '#3279A3', '.9s')}
        {blip('73.8%', '62.8%', '2.4%', '#005B96', '1.8s')}
        {blip('37.9%', '27.9%', '2.2%', '#6497B1', '2.5s')}
        <div className="lg-sweep absolute inset-0 rounded-full [background:conic-gradient(from_0deg,rgba(0,91,150,.22),rgba(0,91,150,.05)_28%,rgba(0,91,150,0)_55%)]" />
      </div>
      <div className="lg-scan absolute inset-0 [background:linear-gradient(114deg,transparent_47%,rgba(0,91,150,.05)_50%,transparent_53%)]" />
      <div className="lg-glow absolute left-[-14%] top-[12%] h-[76vh] w-[58vw] [background:radial-gradient(ellipse_at_32%_42%,rgba(50,121,163,.16),rgba(50,121,163,.06)_46%,transparent_72%)]" />
      <div className="lg-glow absolute right-[-12%] top-[-14%] h-[70vh] w-[60vw] [animation-delay:1.5s] [background:radial-gradient(ellipse_at_70%_35%,rgba(50,121,163,.3),rgba(50,121,163,.1)_48%,transparent_72%)]" />
      <div className="lg-glow absolute bottom-[-18%] right-[-10%] h-[52vh] w-[44vw] [animation-delay:3s] [background:radial-gradient(ellipse_at_60%_60%,rgba(50,121,163,.22),rgba(50,121,163,.07)_50%,transparent_74%)]" />
    </div>
  );
}

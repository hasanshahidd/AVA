'use client';

import { FormEvent, useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { useQueryClient } from '@tanstack/react-query';
import clsx from 'clsx';
import { AlertCircle, CheckCircle2, Eye, EyeOff, Lock, Mail, Sparkles } from 'lucide-react';
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

const CHIPS = ['IT Asset Discovery', 'Asset Inventory', 'Vulnerabilities', 'CTEM', 'AI Pentest', 'CIS Benchmarks', 'Risk Posture', 'Exposure Monitoring', 'Exploit Alerts', 'CVEs', 'Connectors', 'Reporting'];

export default function LoginPage() {
  const searchParams = useSearchParams();
  const queryClient = useQueryClient();

  const [showPw, setShowPw] = useState(false);
  // Which face of the glassy double-slider is showing.
  const [mode, setMode] = useState<'signin' | 'register'>('signin');
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
    <div className="relative h-screen w-screen overflow-hidden bg-white font-sans text-[#0A0B1A]">
      {intro && <IntroCurtain />}
      {bgLive && <RadarBackdrop />}

      {ssoRedirecting ? (
        <div className="relative z-[2] grid h-full place-items-center px-6">
          <div className="w-full max-w-[27rem]">
            <SsoHandoffCard tenantName={tenantName} tenantSlug={tenantSlug} onCancel={cancelSsoSignIn} />
          </div>
        </div>
      ) : (
        <AuthSlider
          mode={mode}
          onMode={setMode}
          bgLive={bgLive}
          intro={intro}
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

      {/* trust band — runs FULL WIDTH across both panels, pinned to the bottom */}
      {!ssoRedirecting && <ThreatMarquee live={bgLive} brandLeft={mode === 'register'} />}
    </div>
  );
}

// Trust band — a full-width strip across the bottom of BOTH panels. The pills
// use a frosted-white treatment that stays legible whether they scroll over the
// blue brand side or the white form side (no per-side recolouring needed).
function ThreatMarquee({ live, brandLeft }: { live: boolean; brandLeft: boolean }) {
  // The seam sits ~53% across in Sign in (blue on the right) and ~47% in
  // Register (blue on the left). Two identical, perfectly-synced marquee layers
  // are clipped to the white side and the blue side respectively, so each chip
  // flips styling exactly as it crosses the seam.
  const seam = brandLeft ? 42 : 58;
  // onWhite (blue chips) shows the WHITE region; onBlue (white chips) shows the
  // BLUE region. In Register the blue panel is on the LEFT, so the two clips
  // mirror — the blue-chip clip and white-chip clip must stay complementary or
  // they overlap near the seam.
  const whiteClip = brandLeft ? `inset(0 0 0 ${seam}%)` : `inset(0 ${100 - seam}% 0 0)`;
  const blueClip = brandLeft ? `inset(0 ${100 - seam}% 0 0)` : `inset(0 0 0 ${seam}%)`;
  const clipT = 'transition-[clip-path] duration-[860ms] ease-[cubic-bezier(.72,.02,.24,1)]';
  return (
    <div className="lg-fade pointer-events-none absolute inset-x-0 bottom-0 z-[15] pb-2.5 pt-2 [animation-delay:.6s]">
      <p className="mb-1.5 text-center">
        <span className="rounded-full bg-white/85 px-2 py-1 text-[.46rem] font-semibold uppercase tracking-[.1em] text-[#2E86C2] shadow-[0_0_22px_rgba(46,134,194,.45),0_4px_12px_-6px_rgba(10,11,26,.2)] ring-1 ring-[#2E86C2]/20 backdrop-blur-md">Threat intelligence built in</span>
      </p>
      <div className="lg-mask relative mx-auto h-[42px] max-w-full overflow-hidden">
        {live && (
          <>
            {/* WHITE side → blue chips with white text */}
            <div className={clsx('absolute inset-0 flex items-center', clipT)} style={{ clipPath: whiteClip }}>
              <MarqueeRow variant="onWhite" />
            </div>
            {/* BLUE side → white chips with dark text */}
            <div className={clsx('absolute inset-0 flex items-center', clipT)} style={{ clipPath: blueClip }}>
              <MarqueeRow variant="onBlue" />
            </div>
          </>
        )}
      </div>
    </div>
  );
}

function MarqueeRow({ variant }: { variant: 'onWhite' | 'onBlue' }) {
  const onWhite = variant === 'onWhite';
  const chip = onWhite
    ? 'border-[#6FB1DC] bg-[#2E86C2] shadow-[0_8px_20px_-10px_rgba(0,91,150,.45)]'
    : 'border-white/70 bg-white/85 shadow-[0_8px_20px_-10px_rgba(10,11,26,.45)]';
  return (
    <div className="lg-marq-slow flex w-max gap-2 py-0.5">
      {[...SOURCES, ...SOURCES].map(([n, d, dom], i) => (
        <div key={i} className={clsx('flex items-center gap-2 whitespace-nowrap rounded-[11px] border py-1 pl-1 pr-3 backdrop-blur-md', chip)}>
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={fav(dom)} alt="" className="h-[22px] w-[22px] rounded-[6px] bg-white p-0.5" />
          <span className="flex flex-col text-left leading-tight">
            <span className={clsx('text-[.68rem] font-semibold', onWhite ? 'text-white' : 'text-[#0A0B1A]')}>{n}</span>
            <span className={clsx('text-[.56rem]', onWhite ? 'text-white/80' : 'text-[#475569]')}>{d}</span>
          </span>
        </div>
      ))}
    </div>
  );
}

// The glassy, light double-slider. Two faces — Sign in and Register — sit
// side by side inside one frosted card; the blue brand panel glides across to
// swap which one is in front (the "swap" from the reference clip), kept in
// Ava's own light + #005B96 palette rather than the dark glass of the video.
function AuthSlider(props: {
  mode: 'signin' | 'register';
  onMode: (m: 'signin' | 'register') => void;
  bgLive: boolean; intro: boolean;
  showPw: boolean; onTogglePw: () => void;
  email: string; password: string;
  onEmail: (v: string) => void; onPassword: (v: string) => void;
  onSubmit: (e: FormEvent) => void; onMicrosoft: () => void; pending: boolean;
  error: string; info: string; passwordInvalid: boolean;
  tenantFromQuery: boolean; tenantName: string | null; tenantSlug: string | null;
  onSwitch: () => void; registrationOpen: boolean;
}) {
  const brandLeft = props.mode === 'register';
  // Slower, eased glide so the frosted sweep reads like the reference clip.
  const slide = 'transition-transform duration-[860ms] ease-[cubic-bezier(.72,.02,.24,1)]';
  const brandSlide = 'transition-[transform,clip-path] duration-[860ms] ease-[cubic-bezier(.72,.02,.24,1)]';
  // Diagonal seam: clip the blue panel's inner edge on an angle. The white form
  // layer fills the whole screen behind it, so the cut always reveals clean
  // white. Mirror the angle when the panel lives on the left (Register).
  const brandClip = brandLeft
    ? 'polygon(0 0, 100% 0, 84% 100%, 0 100%)'   // seam = right edge, strong diagonal
    : 'polygon(0 0, 100% 0, 100% 100%, 16% 100%)'; // seam = left edge, strong diagonal
  return (
    <div className="absolute inset-0 overflow-hidden bg-white">
      {/* WHITE-SIDE DECOR — full-bleed BEHIND everything (z-0), so the brand's
          diagonal cut reveals the exact same texture as the form side and there
          is no distinct white strip at the seam. Large spinning radar on the
          outer side + a soft blue light centred on the seam. */}
      <FormRadar onLeft={!brandLeft} />
      <div
        className="pointer-events-none absolute inset-0 z-0"
        style={{ background: 'radial-gradient(58% 88% at 50% 42%, rgba(0,91,150,.14), rgba(0,91,150,.04) 40%, transparent 62%)' }}
      />

      {/* FORM card — centred in the white half; slides to the other half on toggle */}
      <div className={clsx('absolute inset-y-0 left-0 z-[2] flex w-full flex-col justify-center overflow-hidden px-[clamp(1rem,3vw,2.5rem)] pb-24 pt-8 lg:w-1/2', slide, brandLeft ? 'lg:translate-x-full' : 'lg:translate-x-0')}>
        <div className="relative mx-auto w-full max-w-[26rem]">
          {/* mascot stands BEHIND the card (z-1) at the top-RIGHT corner, peeking
              over it — waving hi from behind. */}
          <div className="pointer-events-none absolute -top-11 right-5 z-[1] h-[80px] w-[68px]">
            <div className="lg-bob-now h-full w-full">
              <MascotFront variant="blue" className="h-full w-full" />
            </div>
          </div>
          <div
            key={props.mode}
            style={{ background: brandLeft
              ? 'linear-gradient(250deg, rgba(255,255,255,.74) 36%, rgba(201,225,247,.74) 100%)'
              : 'linear-gradient(110deg, rgba(255,255,255,.74) 36%, rgba(201,225,247,.74) 100%)' }}
            className="lg-swap relative z-[2] w-full overflow-hidden rounded-[24px] border border-white/70 px-[clamp(1.4rem,2.6vw,2rem)] py-[clamp(1rem,2.2vh,1.5rem)] shadow-[0_2px_4px_rgba(10,11,26,.04),0_30px_72px_-26px_rgba(0,91,150,.5)] ring-1 ring-inset ring-white/50 [backdrop-filter:blur(30px)_saturate(1.5)]"
          >
            {/* top glass sheen */}
            <div className="pointer-events-none absolute inset-x-0 top-0 h-px bg-white/80" />
            {/* blue light spilling in from the seam side — gives the card depth */}
            <div
              className="pointer-events-none absolute inset-0"
              style={{ background: brandLeft
                ? 'radial-gradient(90% 120% at 0% 50%, rgba(0,91,150,.16), transparent 58%)'
                : 'radial-gradient(90% 120% at 100% 50%, rgba(0,91,150,.16), transparent 58%)' }}
            />
            <div className="relative">
              {props.mode === 'signin'
                ? <SignInForm {...props} />
                : <RegisterIntro registrationOpen={props.registrationOpen} onSignIn={() => props.onMode('signin')} />}
            </div>
          </div>
        </div>
      </div>

      {/* BRAND panel — the blue frosted-glass half that GLIDES across to swap
          faces, cut on a diagonal at the seam. Hidden on mobile. */}
      <div
        style={{ clipPath: brandClip }}
        className={clsx('absolute inset-y-0 left-0 z-[5] hidden w-1/2 lg:block', brandSlide, brandLeft ? 'lg:translate-x-0' : 'lg:translate-x-full')}
      >
        <BrandPanel mode={props.mode} onMode={props.onMode} />
      </div>
    </div>
  );
}

function BrandPanel({ mode, onMode }: { mode: 'signin' | 'register'; onMode: (m: 'signin' | 'register') => void; }) {
  const toRegister = mode === 'signin';
  return (
    <div className="relative h-full w-full overflow-hidden text-white [backdrop-filter:blur(22px)_saturate(1.3)]">
      {/* Ava-blue FROSTED glass — translucent enough that, as it glides across
          the form on toggle, its backdrop-blur visibly frosts the words beneath
          (the reference clip's glassy sweep), while still reading saturated. */}
      <div className="absolute inset-0 [background:linear-gradient(150deg,rgba(60,151,214,.93)_0%,rgba(46,134,194,.94)_46%,rgba(26,99,153,.96)_100%)]" />
      {/* soft light bloom top-left + radar echo so it reads as glass, not flat */}
      <div className="lg-drift pointer-events-none absolute -right-[18%] top-1/2 h-[120%] w-[120%] -translate-y-1/2 opacity-45 [background:radial-gradient(circle_at_68%_38%,rgba(255,255,255,.22),transparent_52%)]" />
      <div className="pointer-events-none absolute -left-[10%] -top-[10%] h-[60%] w-[70%] opacity-50 [background:radial-gradient(circle_at_30%_30%,rgba(255,255,255,.16),transparent_60%)]" />
      {/* live status — always on the blue panel, so it stays legible */}
      <div className="absolute right-[clamp(1.5rem,2.2vw,2.5rem)] top-[clamp(1.1rem,2.6vh,1.9rem)] z-20 inline-flex items-center gap-2 text-[.72rem] font-medium text-white/85">
        <span className="h-[7px] w-[7px] rounded-full bg-[#5BE0C2] shadow-[0_0_0_3px_rgba(255,255,255,.18)]" />
        Attack surface online
      </div>

      <div className="relative z-10 flex h-full flex-col justify-center gap-[clamp(.62rem,1.7vh,1.15rem)] px-[clamp(3rem,7.5vw,6.5rem)] pb-[clamp(3rem,9vh,5rem)]">
        <div className="inline-flex items-center gap-2.5">
          <LogoMark className="lg-logo-spin h-10 w-10 [filter:brightness(0)_invert(1)]" />
          <span className="inline-flex items-center gap-2">
            <span className="text-[2rem] font-extrabold tracking-[-.03em]">Ava</span>
            <span className="rounded-[9px] bg-white px-2 py-0.5 text-[.8rem] font-bold tracking-[.09em] text-[#005B96]">AI</span>
          </span>
        </div>
        <div className="inline-flex items-center gap-3">
          <span className="h-px w-8 bg-white/60" />
          <span className="text-[.7rem] font-semibold uppercase tracking-[.22em] text-white/80">AI-native cybersecurity assurance</span>
        </div>
        <h1 className="m-0 text-balance text-[clamp(1.6rem,2.1vw,2.3rem)] font-bold leading-[1.07] tracking-[-.03em] text-white">
          Discover, validate, and <span className="underline decoration-white/35 decoration-2 underline-offset-[6px]">prove</span> your defenses.
        </h1>
        <p className="m-0 text-[clamp(1rem,1.25vw,1.2rem)] text-white/85">
          Every exposure. <b className="font-semibold text-white">One view.</b>
        </p>

        <div className="lg-mask max-w-[28rem] overflow-hidden">
          <div className="lg-marq-chips flex w-max gap-2 py-0.5">
            {[...CHIPS, ...CHIPS].map((c, i) => (
              <span key={i} className="inline-flex items-center whitespace-nowrap rounded-[11px] border border-white/35 bg-white/[0.18] px-3 py-1.5 text-[.76rem] font-semibold text-white">{c}</span>
            ))}
          </div>
        </div>

        <div className="mt-1 flex items-center gap-3 text-[.78rem] font-medium text-white/80">
          <span><b className="font-semibold text-white">Discover</b></span>
          <span className="h-3.5 w-px bg-white/30" />
          <span><b className="font-semibold text-white">Prioritize</b></span>
          <span className="h-3.5 w-px bg-white/30" />
          <span><b className="font-semibold text-white">Validate</b></span>
          <span className="h-3.5 w-px bg-white/30" />
          <span><b className="font-semibold text-white">Monitor</b></span>
        </div>

        {/* Swap CTA — the only control that moves the slider on desktop */}
        <div key={mode} className="lg-swap mt-[clamp(.3rem,1.2vh,.85rem)] border-t border-white/20 pt-[clamp(.45rem,1.4vh,.95rem)]">
          <p className="mb-1.5 text-[.82rem] text-white/75">
            {toRegister ? 'New to Ava?' : 'Already have access?'}
          </p>
          <button
            type="button"
            onClick={() => onMode(toRegister ? 'register' : 'signin')}
            className="inline-flex items-center gap-2 rounded-[12px] border border-white/60 bg-white/10 px-5 py-2.5 text-[.88rem] font-semibold text-white backdrop-blur-sm transition hover:bg-white hover:text-[#005B96]"
          >
            {toRegister ? 'Register your organization' : 'Sign in'} <span aria-hidden>→</span>
          </button>
        </div>
      </div>
    </div>
  );
}

function RegisterIntro({ registrationOpen, onSignIn }: { registrationOpen: boolean; onSignIn: () => void; }) {
  const POINTS = [
    'Your own tenant-isolated Ava workspace',
    'Outside-in discovery & inventory of your attack surface',
    'Continuous vulnerability, CVE & exposure monitoring',
  ];
  return (
    <div>
      <div className="mb-[clamp(.4rem,1.3vh,.9rem)] inline-flex items-center gap-2 text-[.68rem] font-semibold uppercase tracking-[.14em] text-[#014A81]">
        <Sparkles size={13} strokeWidth={2.2} className="text-[#005B96]" /> Get started
      </div>
      <h2 className="m-0 mb-1 text-[clamp(1.4rem,2.5vh,1.75rem)] font-bold tracking-[-.02em] [text-shadow:0_2px_22px_rgba(0,91,150,.26)]">Register your organization</h2>
      <p className="m-0 mb-[clamp(.6rem,1.9vh,1.2rem)] text-[.9rem] text-[#64748B]">
        Stand up your workspace and point Ava at your external attack surface.
      </p>

      <ul className="mb-[clamp(.7rem,2vh,1.3rem)] space-y-2.5">
        {POINTS.map((p) => (
          <li key={p} className="flex items-start gap-2.5 text-[.86rem] text-[#334155]">
            <CheckCircle2 size={17} className="mt-px shrink-0 text-[#005B96]" />
            <span className="leading-snug">{p}</span>
          </li>
        ))}
      </ul>

      {registrationOpen ? (
        <Link
          href="/register"
          className="flex w-full items-center justify-center gap-2 rounded-[14px] bg-[#2E86C2] py-[clamp(.55rem,1.7vh,.88rem)] text-[.98rem] font-semibold text-white shadow-[0_8px_20px_-8px_rgba(46,134,194,.6)] transition hover:bg-[#2278B2]"
        >
          Continue to registration <span aria-hidden>→</span>
        </Link>
      ) : (
        <div className="flex items-start gap-2.5 rounded-[14px] border border-[#DCE9F3] bg-[#EFF5FA] px-3.5 py-3 text-[#014A81]">
          <Lock size={15} className="mt-0.5 shrink-0" />
          <p className="text-[.8rem] leading-relaxed">
            Registration is currently invite-only.{' '}
            <a href="mailto:support@ava.ai?subject=Request%20access%20to%20Ava" className="font-semibold underline underline-offset-2">Contact support</a>{' '}
            to request access for your organization.
          </p>
        </div>
      )}

      {/* Mobile-only toggle back to sign-in (desktop uses the brand panel). */}
      <p className="mt-[clamp(.5rem,1.5vh,1rem)] text-center text-[.8rem] text-[#64748B] lg:hidden">
        Already have access?{' '}
        <button type="button" onClick={onSignIn} className="font-semibold text-[#005B96] underline-offset-2 hover:underline">Sign in</button>
      </p>
    </div>
  );
}

function SignInForm(props: {
  mode: 'signin' | 'register';
  onMode: (m: 'signin' | 'register') => void;
  showPw: boolean; onTogglePw: () => void;
  email: string; password: string;
  onEmail: (v: string) => void; onPassword: (v: string) => void;
  onSubmit: (e: FormEvent) => void; onMicrosoft: () => void; pending: boolean;
  error: string; info: string; passwordInvalid: boolean;
  tenantFromQuery: boolean; tenantName: string | null; tenantSlug: string | null;
  onSwitch: () => void; registrationOpen: boolean;
}) {
  const input =
    'w-full rounded-[14px] border border-white/80 bg-white/70 py-[clamp(.5rem,1.5vh,.78rem)] text-[.92rem] text-[#0A0B1A] outline-none transition-all duration-200 ' +
    'hover:bg-white/90 focus:border-[#005B96] focus:bg-white focus:shadow-[0_0_0_4px_rgba(0,91,150,.16),0_12px_32px_-10px_rgba(0,91,150,.4)]';
  const invalid = 'border-[#FB7185] focus:border-[#F43F5E] focus:shadow-[0_0_0_4px_rgba(244,63,94,.14)]';
  return (
    <div>
      <div className="mb-[clamp(.32rem,1.1vh,.7rem)] inline-flex items-center gap-2 text-[.68rem] font-semibold uppercase tracking-[.14em] text-[#014A81]">
        <Lock size={13} strokeWidth={2.2} className="text-[#005B96]" /> Secure sign-in
      </div>
      <h2 className="m-0 mb-1 text-[clamp(1.4rem,2.5vh,1.75rem)] font-bold tracking-[-.02em] [text-shadow:0_2px_22px_rgba(0,91,150,.26)]">Welcome back</h2>
      <p className="m-0 mb-[clamp(.35rem,1.2vh,.8rem)] text-[.9rem] text-[#64748B]">
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

        <button type="submit" disabled={props.pending} className="w-full rounded-[14px] bg-[#2E86C2] py-[clamp(.55rem,1.7vh,.88rem)] text-[.98rem] font-semibold text-white shadow-[0_8px_20px_-8px_rgba(46,134,194,.6)] transition hover:-translate-y-0.5 hover:bg-[#2278B2] hover:shadow-[0_14px_28px_-10px_rgba(46,134,194,.7)] disabled:translate-y-0 disabled:opacity-60">
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

      {/* Mobile-only toggle to Register (desktop uses the brand panel). */}
      <p className="m-0 mt-[clamp(.4rem,1.3vh,.9rem)] text-center text-[.8rem] text-[#64748B] lg:hidden">
        New to Ava?{' '}
        <button type="button" onClick={() => props.onMode('register')} className="font-semibold text-[#005B96] underline-offset-2 hover:underline">Register organization</button>
      </p>

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

// Large radar on the OUTER side of the WHITE panel, SPINNING — the rings are
// static, the conic sweep arm rotates around them.
function FormRadar({ onLeft }: { onLeft: boolean }) {
  return (
    <div className="pointer-events-none absolute inset-0 overflow-hidden">
      <div className={clsx('absolute top-1/2 h-[min(104vh,920px)] w-[min(104vh,920px)] -translate-y-1/2', onLeft ? 'left-[-32%]' : 'right-[-32%]')}>
        <svg viewBox="0 0 200 200" className="absolute inset-0 h-full w-full">
          {[34, 60, 86, 99].map((r, i) => (
            <circle key={r} cx="100" cy="100" r={r} fill="none" stroke={`rgba(0,91,150,${[0.12, 0.1, 0.08, 0.06][i]})`} strokeWidth="1" />
          ))}
          <circle cx="100" cy="100" r="70" fill="none" stroke="rgba(0,91,150,.14)" strokeWidth="1" strokeDasharray="1.5 7" />
          <line x1="3" y1="100" x2="197" y2="100" stroke="rgba(0,91,150,.07)" strokeWidth="1" />
          <line x1="100" y1="3" x2="100" y2="197" stroke="rgba(0,91,150,.07)" strokeWidth="1" />
          <circle cx="100" cy="100" r="2.5" fill="#005B96" />
        </svg>
        {/* spinning sweep arm */}
        <div className="lg-sweep absolute inset-0 rounded-full [background:conic-gradient(from_0deg,rgba(0,91,150,.16),rgba(0,91,150,.04)_26%,rgba(0,91,150,0)_52%)]" />
        <div className="lg-ping absolute left-[35%] top-[35%] h-[30%] w-[30%] rounded-full border-[4px] border-[rgba(0,91,150,.38)]" />
        {/* blue radar dots (blips) — kept toward the OUTER edge so they land in
            the visible margin, not hidden behind the card */}
        {([['34%', '26%', '12px', '#005B96', '0s'], ['41%', '50%', '10px', '#3279A3', '.7s'], ['31%', '64%', '10px', '#005B96', '1.5s'], ['46%', '36%', '8px', '#3279A3', '2.3s'], ['38%', '78%', '8px', '#005B96', '3s'], ['44%', '18%', '7px', '#3279A3', '3.6s']] as const).map(([l, t, s, c, d], i) => (
          <div key={i} className="lg-blip absolute rounded-full" style={{ left: l, top: t, width: s, height: s, background: c, boxShadow: `0 0 10px ${c}66`, animationDelay: d }} />
        ))}
      </div>
    </div>
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

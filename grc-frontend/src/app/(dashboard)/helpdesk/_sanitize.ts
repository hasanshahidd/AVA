// Help Desk HTML sanitizer (bank-grade B3 fix — stored XSS).
//
// Ticket descriptions, agent/requester replies and INGESTED EMAIL bodies are
// rendered with `dangerouslySetInnerHTML` in the agent console and the requester
// portal. Those strings are attacker-controllable: a requester, or any external
// party who emails the support address, can inject `<script>` / `onerror=` /
// `<iframe>` / `javascript:` payloads that would otherwise execute inside an
// authenticated agent's session. EVERY such string must pass through
// `sanitizeHtml()` before it reaches `dangerouslySetInnerHTML`.
//
// Runs on both server (SSR) and client via isomorphic-dompurify.
//
// NOTE: `isomorphic-dompurify` is declared in grc-frontend/package.json but is
// NOT yet installed in this checkout — the droplet must run `npm install` before
// `npm run build`. The `@ts-ignore` below lets `tsc --noEmit` pass pre-install;
// once the package is present the import resolves normally (an unused @ts-ignore
// is not itself an error).
// @ts-ignore -- resolved at build time after `npm install` (see note above)
import DOMPurify from "isomorphic-dompurify";

// Strict allowlist: only basic text formatting survives. Everything else
// (scripts, iframes, objects, forms, style, event-handler attributes, data-*,
// inline styles) is stripped. Links are limited to http(s)/mailto by
// ALLOWED_URI_REGEXP; DOMPurify drops `javascript:` and other dangerous schemes.
const SANITIZE_CONFIG = {
  ALLOWED_TAGS: [
    "b", "i", "u", "p", "br", "ul", "ol", "li", "a",
    "blockquote", "code", "pre", "span", "strong", "em",
  ],
  ALLOWED_ATTR: ["href", "target", "rel"],
  // Only absolute http(s) and mailto links are permitted; strips javascript:,
  // data:, vbscript:, etc.
  ALLOWED_URI_REGEXP: /^(?:https?|mailto):/i,
  // Defence in depth — explicit deny on top of the tag/attr allowlist.
  FORBID_TAGS: ["script", "iframe", "object", "embed", "style", "form", "input", "textarea", "svg", "math", "link", "base"],
  FORBID_ATTR: ["style", "onerror", "onload", "onclick", "onmouseover", "onfocus", "srcset"],
  // Keep the readable text of any stripped tag; never return an executable node.
  KEEP_CONTENT: true,
  RETURN_TRUSTED_TYPE: false,
};

// Harden any surviving anchor: force a safe rel and open externally, so a
// sanitized link can't be used for tab-nap / referrer leakage.
let hookInstalled = false;
function ensureHook() {
  if (hookInstalled) return;
  try {
    DOMPurify.addHook("afterSanitizeAttributes", (node: any) => {
      if (node && node.tagName === "A" && node.getAttribute && node.getAttribute("href")) {
        node.setAttribute("target", "_blank");
        node.setAttribute("rel", "noopener noreferrer nofollow");
      }
    });
    hookInstalled = true;
  } catch {
    // addHook unavailable (shouldn't happen) — allowlist config still applies.
  }
}

/**
 * Sanitize untrusted HTML before it is handed to `dangerouslySetInnerHTML`.
 * Returns a safe HTML string containing only the allow-listed formatting tags.
 * Never throws; on any failure it falls back to the empty string (fail-closed).
 */
export function sanitizeHtml(html: string): string {
  if (!html || typeof html !== "string") return "";
  try {
    ensureHook();
    return DOMPurify.sanitize(html, SANITIZE_CONFIG) as string;
  } catch {
    return "";
  }
}

export default sanitizeHtml;

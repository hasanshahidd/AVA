import { Poppins, JetBrains_Mono } from 'next/font/google';
import Providers from '@/components/Providers';
import AuthHandoff from '@/components/AuthHandoff';
import './globals.css';

const poppins = Poppins({
  subsets: ['latin'],
  weight: ['300', '400', '500', '600', '700'],
  variable: '--font-poppins',
  display: 'swap',
});

const jetbrainsMono = JetBrains_Mono({
  subsets: ['latin'],
  weight: ['400', '500', '600'],
  variable: '--font-mono',
  display: 'swap',
});

export const metadata = {
  title: 'Ava',
  description: 'Ava — AI-native cybersecurity assurance for your external attack surface',
  icons: {
    icon: [
      { url: '/icon.svg', type: 'image/svg+xml' },
    ],
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={`${poppins.variable} ${jetbrainsMono.variable} bg-slate-50 text-slate-800`}>
        <Providers>
          {/* Reads auth_token + tenant context from URL fragment on first mount,
              hydrates localStorage, then strips the fragment. Required for the
              cross-subdomain login redirect to carry auth across origins. */}
          <AuthHandoff />
          {children}
        </Providers>
      </body>
    </html>
  );
}

import type { ReactNode } from "react";

export const metadata = {
  title: "HAMVIT Admin",
  description: "Painel administrativo HAMVIT",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="pt-BR">
      <body>{children}</body>
    </html>
  );
}

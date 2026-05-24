export default function Page() {
  const modules = [
    'usuarios',
    'alimentos',
    'receitas',
    'cupons',
    'profissionais',
    'pagamentos',
    'relatorios',
    'logs',
    'webhooks',
    'falhas-ia',
    'sincronizacao',
    'conteudo',
    'suporte',
  ];

  return (
    <main style={{ padding: 24 }}>
      <h1>HAMVIT Admin</h1>
      <p>Painel inicial para gestão operacional do ecossistema HAMVIT.</p>
      <ul>
        {modules.map((m) => (
          <li key={m}>
            <a href={`/${m}`}>{m}</a>
          </li>
        ))}
      </ul>
    </main>
  );
}

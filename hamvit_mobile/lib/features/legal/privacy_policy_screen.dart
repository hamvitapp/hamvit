import 'widgets/hamvit_legal_widgets.dart';

class PrivacyPolicyScreen extends HamvitLegalScreen {
  PrivacyPolicyScreen({super.key})
      : super(
          title: 'Política de Privacidade',
          subtitle: 'Última atualização: ${_today()}',
          sections: const [
            HamvitLegalSectionData(
              title: 'POLÍTICA DE PRIVACIDADE — HAMVIT',
            ),
            HamvitLegalSectionData(
              title: '1. Introdução',
              paragraphs: [
                'Esta Política de Privacidade explica como o HAMVIT coleta, utiliza, armazena, protege e compartilha dados pessoais dos usuários.',
                'O HAMVIT busca seguir princípios de transparência, segurança, minimização de dados e respeito à Lei Geral de Proteção de Dados Pessoais (LGPD).',
              ],
            ),
            HamvitLegalSectionData(
              title: '2. Dados que podemos coletar',
              paragraphs: [
                'Podemos coletar dados fornecidos pelo usuário, como:',
              ],
              bullets: [
                'nome',
                'e-mail',
                'senha criptografada por provedor de autenticação',
                'data de nascimento',
                'sexo biológico, quando informado',
                'altura',
                'peso',
                'objetivo',
                'nível de atividade',
                'preferências alimentares',
                'restrições alimentares',
                'hábitos',
                'registros de água',
                'registros alimentares',
                'atividades físicas',
                'sono',
                'fotos enviadas pelo usuário',
                'relatórios gerados',
                'dados de pagamento necessários à confirmação do plano',
              ],
            ),
            HamvitLegalSectionData(
              title: '3. Dados de saúde e bem-estar',
              paragraphs: [
                'Alguns dados informados no HAMVIT podem ser considerados sensíveis, pois estão relacionados a saúde, hábitos, alimentação, peso, evolução corporal e atividade física.',
                'Esses dados são utilizados para personalizar a experiência, calcular metas, gerar relatórios, acompanhar evolução e melhorar funcionalidades do aplicativo.',
              ],
            ),
            HamvitLegalSectionData(
              title: '4. Dados que evitamos coletar inicialmente',
              paragraphs: [
                'O HAMVIT adota coleta progressiva de dados. Por isso, não solicitamos CPF, endereço completo ou dados fiscais no cadastro inicial, salvo quando forem necessários para pagamento, emissão fiscal, parceria profissional ou obrigação legal.',
              ],
            ),
            HamvitLegalSectionData(
              title: '5. Como usamos seus dados',
              paragraphs: [
                'Usamos dados para:',
              ],
              bullets: [
                'criar e manter sua conta',
                'personalizar metas',
                'calcular hidratação e estimativas nutricionais',
                'registrar hábitos',
                'acompanhar evolução',
                'gerar relatórios',
                'oferecer recomendações',
                'processar recursos premium',
                'melhorar a experiência do aplicativo',
                'prevenir fraudes',
                'cumprir obrigações legais',
              ],
            ),
            HamvitLegalSectionData(
              title: '6. Inteligência artificial',
              paragraphs: [
                'Quando o usuário utiliza recursos de IA, como foto da comida, imagens e dados relacionados podem ser enviados a provedores externos de inteligência artificial para processamento.',
                'A IA retorna estimativas de alimentos, porções, calorias e macronutrientes. O usuário deve revisar e confirmar os resultados.',
              ],
            ),
            HamvitLegalSectionData(
              title: '7. Fotos e arquivos',
              paragraphs: [
                'Fotos de comida, fotos corporais e relatórios podem ser armazenados de forma privada. O acesso deve ser restrito ao usuário e a terceiros autorizados por ele, como profissionais convidados ou destinatários de relatórios compartilhados.',
              ],
            ),
            HamvitLegalSectionData(
              title: '8. Pagamentos',
              paragraphs: [
                'Pagamentos podem ser processados por provedores externos, como Mercado Pago. O HAMVIT pode receber informações de status de pagamento, identificadores de transação e confirmação de plano, mas não armazena dados completos de cartão de crédito no aplicativo.',
              ],
            ),
            HamvitLegalSectionData(
              title: '9. Compartilhamento com profissionais',
              paragraphs: [
                'O usuário pode optar por compartilhar relatórios ou dados com nutricionistas ou profissionais parceiros. Esse compartilhamento depende de ação, vínculo, cupom ou autorização do próprio usuário.',
                'O usuário é responsável por decidir com quem compartilha suas informações.',
              ],
            ),
            HamvitLegalSectionData(
              title: '10. Compartilhamento com terceiros',
              paragraphs: [
                'Podemos utilizar serviços de terceiros para:',
              ],
              bullets: [
                'autenticação',
                'banco de dados',
                'armazenamento',
                'envio de e-mails',
                'pagamento',
                'processamento de IA',
                'notificações',
                'análise técnica e melhoria do app',
              ],
            ),
            HamvitLegalSectionData(
              title: '11. Segurança',
              paragraphs: [
                'Adotamos medidas técnicas e organizacionais para proteger os dados, incluindo autenticação, controle de acesso, políticas de segurança, armazenamento protegido e restrição de permissões.',
                'Apesar dos esforços, nenhum sistema é totalmente imune a riscos.',
              ],
            ),
            HamvitLegalSectionData(
              title: '12. Retenção dos dados',
              paragraphs: [
                'Os dados podem ser mantidos enquanto a conta estiver ativa ou enquanto forem necessários para funcionamento do serviço, cumprimento de obrigações legais, auditoria, segurança e suporte.',
              ],
            ),
            HamvitLegalSectionData(
              title: '13. Direitos do usuário',
              paragraphs: [
                'Nos termos da LGPD, o usuário pode solicitar:',
              ],
              bullets: [
                'confirmação de tratamento de dados',
                'acesso aos dados',
                'correção de dados incompletos ou desatualizados',
                'exclusão de dados, quando aplicável',
                'portabilidade, quando viável',
                'informações sobre compartilhamento',
                'revogação de consentimento, quando aplicável',
              ],
            ),
            HamvitLegalSectionData(
              title: '14. Exclusão de conta',
              paragraphs: [
                'O usuário poderá solicitar exclusão da conta e dos dados associados, respeitadas obrigações legais, fiscais, antifraude, auditoria e segurança.',
              ],
            ),
            HamvitLegalSectionData(
              title: '15. Notificações',
              paragraphs: [
                'O HAMVIT pode enviar notificações relacionadas a hábitos, água, alimentação, treino, relatórios, pagamento, segurança e uso do aplicativo.',
                'O usuário poderá gerenciar preferências de notificação quando disponível.',
              ],
            ),
            HamvitLegalSectionData(
              title: '16. Crianças e adolescentes',
              paragraphs: [
                'O HAMVIT não deve ser utilizado por menores sem autorização dos responsáveis legais. Recursos de saúde e emagrecimento devem ser usados com atenção especial e acompanhamento adequado.',
              ],
            ),
            HamvitLegalSectionData(
              title: '17. Alterações nesta política',
              paragraphs: [
                'Esta Política de Privacidade pode ser atualizada para refletir mudanças no aplicativo, requisitos legais ou melhorias de segurança. A versão atualizada ficará disponível no app.',
              ],
            ),
            HamvitLegalSectionData(
              title: '18. Contato',
              paragraphs: [
                'Para dúvidas, solicitações ou exercício de direitos relacionados a dados pessoais, entre em contato pelos canais oficiais do HAMVIT.',
              ],
            ),
          ],
        );

  static String _today() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    return '$day/$month/$year';
  }
}

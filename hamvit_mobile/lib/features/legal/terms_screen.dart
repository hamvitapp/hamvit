import 'widgets/hamvit_legal_widgets.dart';

class TermsScreen extends HamvitLegalScreen {
  TermsScreen({super.key})
      : super(
          title: 'Termos de Uso',
          subtitle: 'Última atualização: ${_today()}',
          sections: const [
            HamvitLegalSectionData(
              title: 'TERMOS DE USO — HAMVIT',
            ),
            HamvitLegalSectionData(
              title: '1. Aceitação dos termos',
              paragraphs: [
                'Ao acessar ou utilizar o HAMVIT, você concorda com estes Termos de Uso. Caso não concorde, não utilize o aplicativo.',
              ],
            ),
            HamvitLegalSectionData(
              title: '2. Sobre o HAMVIT',
              paragraphs: [
                'O HAMVIT é um aplicativo voltado ao acompanhamento de hábitos saudáveis, alimentação, hidratação, atividades físicas, evolução corporal, metas, relatórios e recursos digitais de apoio à qualidade de vida.',
                'O HAMVIT não substitui acompanhamento médico, nutricional, psicológico, fisioterapêutico ou de educação física.',
              ],
            ),
            HamvitLegalSectionData(
              title: '3. Finalidade do aplicativo',
              paragraphs: [
                'O aplicativo tem finalidade informativa, educativa, organizacional e de acompanhamento pessoal. As informações exibidas são estimativas e devem ser utilizadas como apoio à rotina do usuário.',
              ],
            ),
            HamvitLegalSectionData(
              title: '4. Saúde e segurança',
              paragraphs: [
                'Antes de iniciar mudanças importantes na alimentação, atividade física ou rotina de saúde, procure orientação de profissional qualificado, especialmente em caso de:',
              ],
              bullets: [
                'doenças crônicas',
                'gravidez ou amamentação',
                'histórico cardiovascular',
                'diabetes',
                'hipertensão',
                'transtornos alimentares',
                'uso de medicamentos',
                'limitações físicas',
                'dor, tontura ou mal-estar durante exercício',
              ],
            ),
            HamvitLegalSectionData(
              title: '5. Estimativas nutricionais',
              paragraphs: [
                'Calorias, macronutrientes, hidratação, metas e recomendações exibidas pelo aplicativo são estimativas baseadas nos dados informados pelo usuário, bases nutricionais, cálculos e regras internas.',
                'Esses valores podem variar conforme metabolismo, preparo dos alimentos, porções reais, marcas, rotina, precisão dos dados e avaliação profissional.',
              ],
            ),
            HamvitLegalSectionData(
              title: '6. IA de foto da comida',
              paragraphs: [
                'Quando disponível, a análise de alimentos por imagem é um recurso estimativo. A IA pode cometer erros na identificação de alimentos, porções, calorias e macronutrientes.',
                'O usuário deve revisar e confirmar as informações antes de salvar qualquer registro. O HAMVIT não garante precisão absoluta nas análises por imagem.',
              ],
            ),
            HamvitLegalSectionData(
              title: '7. Atividades físicas e GPS',
              paragraphs: [
                'Dados de caminhada, corrida, distância, ritmo, velocidade e calorias são estimativas. A precisão pode variar conforme GPS, dispositivo, ambiente, sinal, sensores e informações preenchidas pelo usuário.',
                'Em atividades indoor, como esteira, os valores podem depender de dados manuais informados pelo usuário.',
              ],
            ),
            HamvitLegalSectionData(
              title: '8. Responsabilidade do usuário',
              paragraphs: [
                'O usuário é responsável por:',
              ],
              bullets: [
                'fornecer informações corretas',
                'revisar dados antes de salvar',
                'utilizar o aplicativo com bom senso',
                'procurar profissionais quando necessário',
                'manter sua senha protegida',
                'não compartilhar acesso indevido à conta',
              ],
            ),
            HamvitLegalSectionData(
              title: '9. Conta e acesso',
              paragraphs: [
                'O usuário pode precisar criar uma conta para acessar recursos do aplicativo, sincronizar dados, salvar histórico e utilizar funcionalidades premium.',
                'O HAMVIT pode suspender ou restringir contas em caso de uso indevido, fraude, violação destes termos ou tentativa de burlar funcionalidades pagas.',
              ],
            ),
            HamvitLegalSectionData(
              title: '10. Plano Free e Premium',
              paragraphs: [
                'O HAMVIT pode oferecer recursos gratuitos e recursos pagos.',
                'O plano Free permite uso funcional básico do aplicativo.',
                'O plano Premium pode liberar recursos avançados como IA de foto da comida, recomendações inteligentes, relatórios PDF, analytics avançados, compartilhamento e outros recursos.',
                'As condições comerciais podem ser alteradas futuramente, respeitando direitos já adquiridos pelo usuário.',
              ],
            ),
            HamvitLegalSectionData(
              title: '11. Pagamentos',
              paragraphs: [
                'Pagamentos podem ser processados por provedores externos, como Mercado Pago. O HAMVIT não armazena dados completos de cartão de crédito no aplicativo.',
                'A liberação de recursos pagos depende da confirmação do pagamento pelo provedor.',
              ],
            ),
            HamvitLegalSectionData(
              title: '12. Cupons e profissionais parceiros',
              paragraphs: [
                'O HAMVIT pode permitir uso de cupons vinculados a profissionais parceiros, como nutricionistas. O uso de cupom pode gerar desconto ao usuário e comissão ou recompensa ao profissional.',
                'O vínculo profissional não substitui consulta, prescrição ou acompanhamento individualizado.',
              ],
            ),
            HamvitLegalSectionData(
              title: '13. Relatórios',
              paragraphs: [
                'Relatórios gerados pelo HAMVIT têm finalidade informativa e de acompanhamento. Eles podem ser compartilhados pelo usuário com profissionais, familiares ou terceiros sob sua responsabilidade.',
                'O usuário deve avaliar cuidadosamente com quem compartilha seus dados.',
              ],
            ),
            HamvitLegalSectionData(
              title: '14. Uso adequado',
              paragraphs: [
                'É proibido:',
              ],
              bullets: [
                'usar o app para fins ilegais',
                'tentar acessar dados de outros usuários',
                'burlar pagamentos',
                'explorar falhas técnicas',
                'inserir informações falsas com intuito de fraude',
                'copiar, revender ou redistribuir o sistema sem autorização',
              ],
            ),
            HamvitLegalSectionData(
              title: '15. Propriedade intelectual',
              paragraphs: [
                'Marca, layout, textos, ícones, funcionalidades, identidade visual, relatórios e demais elementos do HAMVIT pertencem aos seus responsáveis legais, salvo conteúdos de terceiros devidamente licenciados ou referenciados.',
              ],
            ),
            HamvitLegalSectionData(
              title: '16. Disponibilidade do serviço',
              paragraphs: [
                'O HAMVIT busca manter o serviço disponível, mas pode ocorrer instabilidade, manutenção, falhas de internet, problemas em provedores externos ou indisponibilidade temporária.',
              ],
            ),
            HamvitLegalSectionData(
              title: '17. Alterações no aplicativo',
              paragraphs: [
                'O HAMVIT pode evoluir, remover, alterar ou adicionar funcionalidades para melhorar segurança, desempenho, experiência, sustentabilidade financeira e qualidade do produto.',
              ],
            ),
            HamvitLegalSectionData(
              title: '18. Limitação de responsabilidade',
              paragraphs: [
                'O HAMVIT não se responsabiliza por decisões de saúde tomadas exclusivamente com base no aplicativo, uso inadequado, informações incorretas fornecidas pelo usuário ou ausência de acompanhamento profissional quando necessário.',
              ],
            ),
            HamvitLegalSectionData(
              title: '19. Encerramento',
              paragraphs: [
                'O usuário pode deixar de utilizar o aplicativo a qualquer momento. Solicitações relacionadas à conta e dados pessoais devem seguir os canais indicados na Política de Privacidade.',
              ],
            ),
            HamvitLegalSectionData(
              title: '20. Contato',
              paragraphs: [
                'Para dúvidas sobre estes Termos de Uso, entre em contato pelos canais oficiais do HAMVIT.',
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

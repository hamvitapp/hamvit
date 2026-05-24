import 'package:flutter/material.dart';

import '../../../shared/widgets/hamvit_back_app_bar.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: hamvitBackAppBar(context, title: 'Termos de uso', fallbackRoute: '/register'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('Termos de Uso do HAMVIT', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('Última atualização: 22/05/2026'),
          SizedBox(height: 16),
          Text('1. Sobre o aplicativo', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('O HAMVIT é um aplicativo de apoio a hábitos saudáveis, alimentação, hidratação, atividade física e acompanhamento de evolução pessoal.'),
          SizedBox(height: 12),
          Text('2. Conta e acesso', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('Para usar recursos personalizados, você deve criar uma conta com informações verdadeiras e manter sua senha em segurança.'),
          SizedBox(height: 12),
          Text('3. Planos Free e Premium', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('O plano Free mantém funcionalidades essenciais. Recursos avançados, como recomendações inteligentes, exportação PDF e analytics avançado, fazem parte do Premium.'),
          SizedBox(height: 12),
          Text('4. Premium vitalício e pagamentos', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('Quando aplicável, o acesso Premium é vitalício, sem mensalidade. Processamentos de pagamento podem envolver provedores externos, conforme políticas deles.'),
          SizedBox(height: 12),
          Text('5. Uso responsável', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('As informações do app têm caráter educativo e de apoio. O HAMVIT não substitui orientação médica, nutricional ou profissional individualizada.'),
          SizedBox(height: 12),
          Text('6. Dados e privacidade', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('Os dados fornecidos no app são usados para personalização de experiência, acompanhamento e funcionalidades contratadas, conforme regras de privacidade do projeto.'),
          SizedBox(height: 12),
          Text('7. Disponibilidade e alterações', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('O aplicativo pode receber atualizações, melhorias e ajustes funcionais sem aviso prévio, preservando a operação principal sempre que possível.'),
          SizedBox(height: 12),
          Text('8. Condutas proibidas', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('É proibido usar o app para fraude, violação de segurança, engenharia reversa não autorizada ou qualquer uso ilícito.'),
          SizedBox(height: 12),
          Text('9. Encerramento de conta', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('Você pode deixar de usar o app a qualquer momento. Em casos de violação destes termos, o acesso pode ser suspenso ou encerrado.'),
          SizedBox(height: 12),
          Text('10. Aceite', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('Ao marcar "Aceito os termos de uso" e prosseguir com o cadastro, você declara ciência e concordância com este documento.'),
        ],
      ),
    );
  }
}

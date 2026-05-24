# HAMVIT DatePicker Localization Fix

## Objetivo
Corrigir erro de MaterialLocalizations ao abrir DatePickerDialog e padronizar datas em formato brasileiro DD/MM/AAAA.

## Causa raiz
DatePicker exige Localizations na arvore do MaterialApp. Sem delegates/locale corretos, o dialogo falha com erro de MaterialLocalizations.

## Ajustes aplicados

### 1) Configuracao global no app root
Arquivo:
- hamvit_mobile/lib/main.dart

Aplicado em MaterialApp.router:
- locale: Locale('pt', 'BR')
- supportedLocales: pt-BR e en-US
- localizationsDelegates:
  - GlobalMaterialLocalizations
  - GlobalWidgetsLocalizations
  - GlobalCupertinoLocalizations

### 2) Dependencias
Arquivo:
- hamvit_mobile/pubspec.yaml

Dependencias ativas:
- flutter_localizations (SDK Flutter)
- intl ^0.20.2 (versao compativel com flutter_localizations do SDK atual)

### 3) Date utils com locale explicito
Arquivo:
- hamvit_mobile/lib/core/hamvit_date_utils.dart

Aplicado:
- DateFormat('dd/MM/yyyy', 'pt_BR') para exibicao ao usuario.
- Conversao para ISO yyyy-MM-dd mantida para persistencia.

### 4) HamvitDateField robusto
Arquivo:
- hamvit_mobile/lib/shared/widgets/hamvit_date_field.dart

Aplicado:
- showDatePicker com locale pt-BR.
- initialDate seguro (clamp entre firstDate e lastDate).
- toque no campo abre calendario.
- mascara DD/MM/AAAA para digitacao manual.
- validacao de data real (nao aceita 31/02, mes 13 etc).
- callback em ISO para backend.

### 5) Utilitario global de datas
Arquivo:
- hamvit_mobile/lib/core/validators.dart

Aplicado:
- Validators.pickDate agora usa locale pt-BR.

## Resultado esperado
- DatePicker abre sem erro vermelho.
- Labels do calendario em portugues.
- Exibicao de datas em DD/MM/AAAA no app.
- Persistencia continua em yyyy-MM-dd quando necessario.

## Validacao tecnica recomendada
1. flutter pub get
2. flutter analyze
3. flutter clean
4. flutter pub get
5. flutter run

## Smoke manual
- Dados corporais: abrir e selecionar data.
- Evolucao / Registrar peso: abrir calendario e salvar.
- Sono: abrir seletor de data/horario quando aplicavel.
- Reabrir telas e confirmar DD/MM/AAAA.

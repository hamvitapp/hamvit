$ErrorActionPreference = 'Stop'

Set-Location 'E:\Projetos\HAMFIT\hamvit_mobile'

$env:ANDROID_SDK_ROOT = 'E:\Projetos\HAMFIT\tools\android-sdk'
$env:PATH = "E:\Projetos\HAMFIT\tools\flutter\bin;$env:ANDROID_SDK_ROOT\platform-tools;$env:ANDROID_SDK_ROOT\emulator;$env:PATH"

flutter run -d emulator-5554 --dart-define=SUPABASE_URL=https://akvgwtiwhuduuzcantht.supabase.co --dart-define=SUPABASE_ANON_KEY=sb_publishable_G3LtIrRl1nW0jDVVM0YHjA_a8-_yc7I

$ErrorActionPreference = "Stop"
$env:PATH = "C:\flutter\bin;C:\Users\welly\AppData\Local\Pub\Cache\bin;$env:APPDATA\npm;$env:PATH"
Set-Location "E:\Projetos\financas"

Write-Host "==> Login no Firebase (abra o navegador se pedir)" -ForegroundColor Cyan
firebase login

Write-Host "==> Configurando FlutterFire para financas-wellysson" -ForegroundColor Cyan
flutterfire configure --project=financas-wellysson --platforms=android,web --yes

Write-Host "==> Publicando regras do Firestore" -ForegroundColor Cyan
firebase deploy --only firestore:rules --project=financas-wellysson

Write-Host ""
Write-Host "Pronto! Agora no Console Firebase ative:" -ForegroundColor Green
Write-Host "  Authentication > Sign-in method > Email/Password e Google"
Write-Host "Depois rode: flutter run -d chrome"

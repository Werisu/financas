# Firebase — financas-wellysson

## 1. Login e configuração (rode no seu terminal)

```powershell
$env:PATH = "C:\flutter\bin;C:\Users\welly\AppData\Local\Pub\Cache\bin;$env:APPDATA\npm;$env:PATH"
cd E:\Projetos\financas

firebase login
flutterfire configure --project=financas-wellysson --platforms=android,web --yes
```

Isso gera `lib/firebase_options.dart` e os arquivos nativos (`google-services.json`, etc.).

## 2. Ativar no Console Firebase

No projeto **financas-wellysson**:

1. **Authentication** → Sign-in method → ative **E-mail/senha** e **Google**
2. **Firestore Database** → criar banco (modo produção) → depois publique as regras

```powershell
firebase.cmd deploy --only firestore:rules --project=financas-wellysson
```

> Foto de perfil usa o **Firestore** (base64 comprimido), sem Firebase Storage — funciona no plano gratuito.

## 3. Google Sign-In (Web)

Em Authentication → Google → use o Web client ID gerado.
O `flutterfire configure` já registra o app Web; confirme o domínio `localhost` em Authentication → Settings → Authorized domains.

## 4. Rodar

```powershell
flutter run -d chrome
```

Estrutura no Firestore:

```
users/{uid}
  categories/{id}
  cards/{id}
  expenses/{id}
```

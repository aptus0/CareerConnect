# CareerConnect Next.js + Salesforce Integration

Bu proje, yüklediğin CareerConnect SFDX paketinin dış web arayüzüdür.

## Mimari

```text
Browser / React UI
      ↓
Next.js App Router
      ↓
Next.js API Routes / BFF
      ↓ OAuth2 Client Credentials
Salesforce Apex REST: /services/apexrest/careers/*
      ↓
Job_Position__c, Application__c, Candidate_Profile__c
```

## Kurulum

```bash
cp .env.example .env.local
npm install
npm run dev
```

`.env.local` içine Salesforce Connected App bilgilerini gir:

```env
SALESFORCE_LOGIN_URL=https://login.salesforce.com
SALESFORCE_CLIENT_ID=...
SALESFORCE_CLIENT_SECRET=...
SF_API_VERSION=v59.0
REED_API_KEY=...
```

Sandbox kullanırsan:

```env
SALESFORCE_LOGIN_URL=https://test.salesforce.com
```

## Salesforce Connected App

1. Setup → App Manager → New Connected App
2. Enable OAuth Settings
3. Callback URL demo için `http://localhost:3000/api/auth/callback/salesforce` yazılabilir; client credentials için callback kullanılmaz ama Salesforce alanı isteyebilir.
4. OAuth Scopes: `api`, gerekirse `refresh_token/offline_access`
5. Client Credentials Flow aktif et.
6. Run As kullanıcısına gerekli Permission Set ver: `CareerConnect_HR_Admin` veya özel Integration User permset.

## Next.js endpointleri

| Method | Route | Ne yapar |
|---|---|---|
| GET | `/api/sf/jobs` | Açık pozisyonları Salesforce’tan alır |
| GET | `/api/sf/jobs/:id` | Tek pozisyon detayı |
| POST | `/api/sf/apply` | Başvuru oluşturur |
| GET | `/api/sf/applications` | Mevcut kullanıcının başvurularını alır |
| PATCH | `/api/sf/applications/status` | HR status günceller |
| POST | `/api/sf/external-sync` | Salesforce Apex üzerinden Reed API sync çalıştırır |
| GET | `/api/external/reed/jobs` | Reed API önizleme endpointi |

## Önemli üretim notları

- API anahtarları sadece server-side `.env.local` içinde durur; client’a gönderilmez.
- `/admin` demo sayfasıdır. Production’da NextAuth/Auth.js veya Salesforce Experience Cloud SSO ile role guard eklenmelidir.
- `Application__c` object’i Master-Detail ile `Job_Position__c` parent’ına bağlıysa sharing `ControlledByParent` olur. Aday gizliliği için production’da `Job_Position__c` ilişkisini Lookup yapmak veya parent sharing modelini yeniden tasarlamak daha doğru olur.
- `my-applications` endpointi Integration User ile çalışırken gerçek adayı bilemez. Phase 2’de NextAuth oturumu → Candidate_Profile__c mapping eklenmelidir.

## Test komutları

```bash
npm run typecheck
npm run build
```

## Salesforce tarafındaki gerekli Apex patch

Bu zip’in yanında `CareerConnect_SFDX_Patched.zip` dosyası da üretildi. İçinde:

- `JobApiController` URL parsing fix
- `POST /careers/sync-external-jobs` endpointi
- Test class ek senaryosu

Deploy:

```bash
cd CareerConnect
sf project deploy start --source-dir force-app --target-org CareerConnect
sf apex run test --test-level RunLocalTests --target-org CareerConnect --result-format human
```

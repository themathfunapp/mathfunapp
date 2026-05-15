# GA4 — Ebeveyn bildirim telemetrisi (custom dimensions)

Uygulama şu olayları gönderir: `parent_notif_scheduled`, `parent_notif_shown`, `parent_notif_open`.  
Hepsinde aynı **event parametreleri** kullanılır; aşağıdaki gibi **Event-scoped** custom dimension tanımlayın.

**Konum:** Google Analytics → **Admin** → **Data display** → **Custom definitions** → **Create custom dimensions**

Her biri için:

| Dimension name (görünen ad) | Scope | Event parameter | Description |
|-----------------------------|--------|-----------------|-------------|
| Parent notif kind | Event | `kind` | Bildirim türü: `daily`, `weekly_sched`, `weekly_popup`, `success_tip`, `inactivity_sched`, `inactivity_gap`, `badge` |
| Parent notif variant | Event | `variant` | Metin varyantı veya `inactivity_gap` için gün aralığı (2–14) |
| Parent notif lang | Event | `lang` | İki harf dil kodu (ör. `tr`, `en`); boş olabilir |
| Parent notif source | Event | `src` | `scheduler`, `panel`, `workmanager`, `tap` |

**Notlar**

- Parametre adları kod ile birebir aynıdır: `lib/analytics/parent_notif_ga4_params.dart`.
- `variant` sayısal raporlama için GA4’te dimension tipi **Integer** (mümkünse) seçin; yoksa **Text** de olur.
- Boyutlar oluşturduktan sonra raporlarda görünmesi **24–48 saat** sürebilir.
- Property başına event-scoped custom dimension kotası vardır; gereksiz boyut açmayın.

**Explorations / Reports**

- Exploration’da **Event name** filtresi: `parent_notif_open` (tıklama hunisi).
- `kind` × `variant` kırılımı A/B metin analizi için yeterlidir.

# MathFun — Math Adventure

A **child-focused math learning and practice app** built with Flutter. It uses short, game-like sessions, feedback, and progression to reinforce core numeracy skills.

> **Turkish product name:** *Matematik Macerası* (see `pubspec.yaml` description).

---

## What this app is for

- Make math **approachable and repeatable** through themed games, quick drills, and clear right/wrong feedback.
- Support **family oversight**: parent panel, PIN, and reporting so usage stays visible for younger learners.
- Sustain motivation with **badges**, **daily tasks**, **story maps**, **avatars**, and a light **economy** (coins, shop).

This repository holds the **client application**. Legal documents (below) must still be published on your **store listings** and/or **website**.

---

## Target age and audience

| Track | Approximate age / notes |
|--------|-------------------------|
| Preschool / discovery | Counting, objects, low-pressure UI |
| Early elementary | Addition/subtraction, true/false, topic games |
| More advanced modes | Wider number ranges, more multiplication/division (depends on game mode) |

Some in-app copy references **example age bands** (e.g. 9–11) for unlocks; you should state the **final** target audience in store metadata.

**Important:** Accounts and device use for young children should assume **parental consent and supervision**. The app provides tools to help; it does not replace legal or parental responsibility.

---

## Curriculum alignment (high level)

There is **no claim** of official national-curriculum certification. Content is aligned with **common primary-school math themes** (Turkey and similar systems):

- **Numbers & operations:** addition, subtraction, multiplication, division; quick practice and endless mode  
- **Fractions & proportion:** themed games (e.g. fraction “bakery”)  
- **Geometry & patterns:** shapes, patterns, spot-the-difference style tasks  
- **Measurement & time:** measurement themes, clock/time activities, magic-clock mini-game  
- **Logic / attention:** Simon-style games, puzzle-like mini-games  

Story mode and topic hubs **package** these skills inside narratives and characters.

---

## Privacy, children, and data (summary — not legal advice)

This section is for **orientation only**. You must publish a full **Privacy Policy** (and where applicable **Children’s Privacy** guidance, e.g. COPPA in the US, GDPR and regional child-data rules in the EU) with **legal review** on your store and website.

From the codebase, the technical surface includes:

- **Identity:** Firebase Authentication (e.g. Google / Apple sign-in, guest flows).  
- **Cloud data:** Cloud Firestore (progress, profile, game stats, etc.).  
- **Monetization:** AdMob, in-app purchase plumbing (may need final store configuration).  
- **Device:** secure storage (e.g. parent PIN), offline helper services.

**Suggested principles (README summary):**

1. Tell parents **what** is collected and **why**, in plain language.  
2. Avoid collecting unnecessary personal data for child accounts; align with store **family** programs where relevant.  
3. Configure ads/analytics SDKs for **child-directed** modes where required.  
4. Define how you handle **deletion** and **export** requests.

Consider adding `docs/PRIVACY.md` or a hosted policy URL later.

---

## Feature overview (non-technical)

- Story mode, topic games, mini-games, daily challenge, endless mode  
- Badges and daily task progress  
- Lives / combo and light economy (coins, shop)  
- Multi-language UI  
- Parent panel (charts, PDF share, PIN)  
- Friends / social features (configuration-dependent)

---

## Tech stack

- **Flutter** (Dart SDK `>=3.6.0 <4.0.0`)  
- **Firebase:** Auth, Firestore, Cloud Functions  
- **State:** Provider  
- **Others:** localization, charts (parent), ads, IAP, secure storage — see `pubspec.yaml`

---

## Developer setup

```bash
flutter pub get
```

Firebase configuration (`firebase_options.dart`, security rules, indexes) and store credentials are project-specific and are not documented here.

```bash
flutter run
```

Static analysis:

```bash
dart analyze lib
```

---

## License and contact

`publish_to: 'none'` in `pubspec.yaml` — distribution model and SPDX license are up to the maintainer; add a `LICENSE` file and contact details when ready.

---

*This README replaces the default Flutter template with a product-oriented overview.*

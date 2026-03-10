# VoteNG 2027 — Nigeria Mock Election Social Experiment Platform

> A full-stack platform for Nigeria's 2027 General Elections social experiment — enabling crowd-sourced mock voting and comparing results against official INEC outcomes.

---

## Project Structure

```
National Election/
├── voteng_app/          # Flutter app (Android + iOS + Web)
├── voteng_api/          # Node.js/Express REST API + WebSocket
├── database/
│   ├── schema.sql       # MySQL schema
│   └── seed.sql         # Parties, states, candidates, election config
└── README.md
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile App | Flutter 3.x (Android + iOS) |
| Web (Admin) | Flutter Web |
| State Management | Riverpod 2.x |
| Navigation | GoRouter 14.x |
| Backend API | Node.js + Express |
| Database | MySQL 8.x |
| Auth | JWT + OTP (via email/SMS) |
| Real-time | WebSocket (ws library) |
| Charts | fl_chart + percent_indicator |

---

## Quick Start

### 1. Database Setup
```bash
# Import schema and seed data
mysql -u root -p < database/schema.sql
mysql -u root -p < database/seed.sql
```

### 2. Backend API
```bash
cd voteng_api

# Copy environment config
cp .env.example .env
# Edit .env with your MySQL credentials and JWT secret

# Install dependencies
npm install

# Install nodemon for development
npm install -g nodemon

# Run in development
npm run dev

# API runs on http://localhost:3000
# WebSocket on ws://localhost:3000
```

### 3. Flutter App
```bash
cd voteng_app

# Get dependencies
flutter pub get

# Update API URL in lib/core/constants/app_constants.dart:
# const String kApiBaseUrl = 'http://YOUR_IP:3000';

# Run on Android
flutter run -d android

# Run on iOS
flutter run -d ios

# Run as Web (admin panel)
flutter run -d chrome
```

---

## API Endpoints

### Auth
| Method | Endpoint | Description |
|---|---|---|
| POST | `/auth/register` | Register new voter |
| POST | `/auth/verify-otp` | Verify OTP, get JWT |
| POST | `/auth/login` | Login with phone + password |
| POST | `/auth/resend-otp` | Resend OTP |
| GET | `/auth/me` | Get current user profile |

### Candidates & Parties
| Method | Endpoint | Description |
|---|---|---|
| GET | `/candidates?type=presidential` | List candidates by election type |
| GET | `/candidates/parties/all` | List all parties |
| GET | `/candidates/states/all` | List all 36 states + FCT |

### Voting
| Method | Endpoint | Description |
|---|---|---|
| POST | `/votes` | Cast a vote (JWT required) |
| GET | `/votes/status` | Get user's vote status across all tiers |
| GET | `/votes/receipt/:type` | Get vote receipt for a specific election |

### Analytics
| Method | Endpoint | Description |
|---|---|---|
| GET | `/analytics/results?type=presidential` | Live results |
| GET | `/analytics/threshold` | Presidential 25%/24-state tracker |
| GET | `/analytics/demographics?type=presidential` | Gender/age/zone breakdown |
| GET | `/analytics/turnout` | Voter turnout stats |
| GET | `/analytics/comparison?type=presidential` | Platform vs INEC results |
| GET | `/analytics/state-results?type=presidential` | State-by-state results |
| GET | `/analytics/timeline?type=presidential` | Votes over time |

### Admin (JWT + Admin role required)
| Method | Endpoint | Description |
|---|---|---|
| GET | `/admin/stats` | Dashboard stats overview |
| POST/PUT/DELETE | `/admin/candidates` | Manage candidates |
| PUT | `/admin/election-config/:type` | Open/close voting tiers |
| POST | `/admin/actual-results` | Input official INEC results |
| GET/PUT | `/admin/users` | Manage/flag users |
| POST | `/admin/notifications` | Broadcast notifications |

---

## Electoral Rules Implemented

### Presidential Election (February 20, 2027)
- **Round 1**: Winner needs plurality + 25% of votes in ≥ 24 of 36 states + FCT
- **Round 2**: If no winner — top 2 candidates, same threshold  
- **Round 3**: If still no winner — simple majority wins

The `/analytics/threshold` endpoint tracks each candidate's qualifying state count in real-time.

---

## Nigerian Parties Pre-loaded

| Party | Abbreviation | Color |
|---|---|---|
| All Progressives Congress | APC | `#008751` (Green) |
| Peoples Democratic Party | PDP | `#C8102E` (Red) |
| Labour Party | LP | `#FF6B00` (Orange) |
| Africa Democratic Congress | ADC | `#003893` (Blue) |
| New Nigeria Peoples Party | NNPP | `#6A0DAD` (Purple) |
| All Progressives Grand Alliance | APGA | `#007A5E` (Teal) |

---

## Presidential Candidates Seeded

1. **Bola Ahmed Tinubu** — APC (Incumbent, running mate: Kashim Shettima)
2. **Atiku Abubakar** — ADC
3. **Peter Obi** — Labour Party
4. **Rabiu Musa Kwankwaso** — NNPP

---

## Admin Access

Default admin credentials:
- **Phone**: `+2340000000000`
- **Password**: `Admin@2027`

> ⚠️ Change admin credentials before deploying to production!

---

## Key Features

- ✅ One vote per election tier per user (MySQL unique constraint + server check)
- ✅ 5 election tiers: Presidential, Senate, HoR, Governorship, State Assembly
- ✅ Real-time analytics via WebSocket (updates every 30s)
- ✅ 25%/24-state presidential threshold tracker
- ✅ Demographic breakdown: gender, age group, geopolitical zone, state
- ✅ Platform vs INEC comparison panel (post-election accuracy scoring)
- ✅ INEC-style ballot UI with party color accents
- ✅ "I Voted" share card (social share)
- ✅ Admin panel: candidate CRUD, tier open/close, actual results input
- ✅ 36 states + FCT pre-loaded with geopolitical zones
- ✅ Dark mode Material Design 3 UI (Nigeria green theme)

---

## UI Design

All screens designed via **Google Stitch MCP** (Project ID: `10981592206892819855`):
- Splash + 3-slide Onboarding
- Voter Registration (Step 1 of 2)
- Home Dashboard (countdown, voting status grid, leaderboard)
- Presidential Ballot (INEC-style)
- Analytics Dashboard (results, threshold, demographics)
- Admin Panel (desktop)

---

## Social Experiment Comparison

After the real election (Feb 20, 2027), admin inputs INEC results via:
```
POST /admin/actual-results
[{ "candidate_id": 1, "election_type": "presidential", "real_vote_count": 8794726, "real_percentage": 36.2 }]
```

The [`/comparison`] screen then shows side-by-side accuracy with a scoring system.

---

## License
MIT — Built for educational, social science, and civic engagement purposes.

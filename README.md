# 🦁 FinWiz - AI Voice & SMS Expense Tracker

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)

> **Stop Typing. Start Speaking.** > FinWiz is a next-generation expense tracker that uses Voice Commands and SMS Automation to log your finances instantly.

---

## 📱 Screenshots

| Home (Dark Mode) | Interactive Charts | Voice Command |
|:---:|:---:|:---:|
| <img src="screenshots/home_dark.png" width="200" /> | <img src="screenshots/charts.png" width="200" /> | <img src="screenshots/voice.png" width="200" /> |

*(Note: Add your screenshots in a folder named `screenshots`)*

---

## 💡 Inspiration
Traditional expense trackers add friction. You have to open the app, navigate forms, and type details. We built FinWiz to be **invisible**. Whether it's auto-detecting a bank SMS or listening to a 2-second voice command, FinWiz removes the effort from financial discipline.

## 🚀 Key Features

### 🎙️ Voice-First Entry
- Just tap and say: *"300 for Coffee"* or *"1200 for Groceries"*.
- Uses **Speech-to-Text** combined with custom **Regex Parsing** to extract Amount, Category, and Title automatically.

### 📩 SMS Auto-Detection
- Automatically reads incoming transactional SMS from banks.
- Filters out OTPs and Spam.
- Extracts the amount and merchant name to suggest expenses without opening the app.

### 📊 Floating Glassmorphism UI
- **Interactive Heatmaps:** Visualize spending intensity over the month.
- **Floating Charts:** Pie charts and Bar graphs slide in overlaying the UI.
- **Persistent Theme:** Dark/Light mode preference is synced to the cloud.

### ⚡ Supabase Backend
- **Real-time Sync:** Data updates instantly across devices using Supabase Streams.
- **Auth & Security:** Secure Email/Password login with Row Level Security (RLS).

---

## 🛠️ Tech Stack

- **Framework:** Flutter (Dart)
- **Backend:** Supabase (PostgreSQL, Auth, Realtime)
- **State Management:** StatefulWidget & Streams
- **Key Packages:**
  - `speech_to_text`: For voice input.
  - `fl_chart`: For data visualization.
  - `supabase_flutter`: For backend integration.
  - `telephony` / `flutter_sms_inbox`: For reading SMS.
  - `google_fonts`: For typography.

---

## ⚙️ Installation & Setup

1. **Clone the repo**
Bash
flutter pub get
Supabase Configuration
Create a .env file in the root directory and add your keys:

Code snippet
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
Run the App

Bash
flutter run
🗄️ Database Schema (Supabase SQL)
Run this in your Supabase SQL Editor to set up the tables:

SQL
-- 1. Create Transactions Table
create table transactions (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users not null,
  title text not null,
  amount numeric not null,
  category text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. Create User Settings Table (For Theme & Budget)
create table users_settings (
  user_id uuid references auth.users not null primary key,
  monthly_limit numeric default 5000,
  is_dark boolean default false
);

-- 3. Enable RLS (Security)
alter table transactions enable row level security;
alter table users_settings enable row level security;

-- 4. Add Policies (Users can only see their own data)
create policy "Users can see their own transactions" on transactions
  for select using (auth.uid() = user_id);

create policy "Users can insert their own transactions" on transactions
  for insert with check (auth.uid() = user_id);

create policy "Users can update own settings" on users_settings
  for all using (auth.uid() = user_id);
🧠 How It Works (The Logic)
The Voice/SMS Regex Engine
FinWiz doesn't just "listen"; it "understands". We use pattern matching to parse unstructured text.

Example Logic:

Input: "I paid 500 bucks for Pizza"

Amount Extraction: Looks for digits (\d+) near currency keywords. -> 500

Keyword Matching: Matches "Pizza" to Category.food.

Result: Transaction created { Title: "Pizza", Amount: 500, Category: Food }

🔮 Future Roadmap
[ ] Biometric Lock: Secure app with FaceID.

[ ] Budget Alerts: Push notifications when 90% budget is crossed.

[ ] PDF Export: Download monthly financial reports.

🤝 Contributing
Contributions are welcome! Fork the repo and submit a PR.

📄 License
This project is licensed under the MIT License.

Built with ❤️ by Yash Gupta

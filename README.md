\# SDG Rewards — Hackathon MVP



> One wallet. Many campaigns. Every point measured against an SDG.
## Setup & Installation

This project consists of three main parts: the Node.js backend, the Flutter mobile app, and the web interfaces (Dashboard, Partner, Gemini). 

### Prerequisites
- **Node.js** (v18 or higher)
- **Flutter SDK** (v3.0 or higher)
- A **Firebase Project** (with Authentication and Firestore enabled)
- A **Google Gemini API Key** (from Google AI Studio)

---

### 1. Backend Setup (Node.js)

The backend handles QR validation, Firestore updates, and Gemini AI verification.

```bash
# Navigate to the backend directory
cd backend

# Install dependencies
npm install

# Create a .env file and add your secrets
# (See .env.example for the required format)
touch .env


A user signs up with their phone number, scans a QR code to earn points, spends points for a discount, and the Sponsor dashboard shows pool balance and SDG impact.



\## Google Tools Used

\- Firebase Authentication

\- Cloud Firestore

\- Cloud Functions

\- Gemini API

\- Firebase Hosting



\## Repo Structure

\- `/backend` — Firebase functions and seed script

\- `/user-app` — Flutter app for Mama Alice

\- `/partner-app` — Web page to generate reward QRs

\- `/dashboard` — Sponsor dashboard (HTML/JS)

\- `/gemini` — Social verification page

\- `/docs` — Planning documents



\## Setup

\*(Will be filled in as we build)\*


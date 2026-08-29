# ✈️ SplitTrip API & Mobile Client

SplitTrip is a full-stack group expense management system designed to track shared costs during trips, handle selective participant splitting, and calculate optimal debt settlements.

## 🏗️ Architecture & Tech Stack

- **Backend:** Java 21, Spring Boot, Spring Data JPA, Hibernate
- **Database:** PostgreSQL (AWS Cloud Database) / H2 (Local Development)
- **Containerization & Deployment:** Docker (Multi-stage build), Heroku Container Registry
- **Frontend / Client:** Flutter (Android & Web PWA)

## ✨ Key Features

- **Selective Expense Splitting:** Allows granular selection of involved members per transaction with exact cent settlement.
- **Smart Debt Balancing:** Calculates net balances and generates minimum transaction settlement instructions.
- **Cross-Platform Access:** Native Android APK and responsive Web PWA for iOS Safari integration.

## 🚀 Deployment & Local Setup

\`\`\`bash
# Run with Docker
docker build -t splittrip-api ./backend
docker run -p 8080:8080 splittrip-api
\`\`\`

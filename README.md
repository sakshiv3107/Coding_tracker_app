# CodeSphere – Unified Coding Analytics App

CodeSphere is a Flutter-based mobile application that aggregates coding activity from multiple platforms and presents meaningful analytics to help developers track their real progress.

---

## 🚀 Project Overview

The app allows a user to log in, connect their coding platform accounts, and view automated statistics without any manual data entry.

Platforms Planned:

* LeetCode
* Codeforces
* GitHub
* (Extensible to CodeChef / GFG)

---

## ✨ Features to be Implemented

### 1. Authentication System

* Email & password login
* Google Sign-In support
* Persistent sessions
* Secure logout
* Auth state management using Provider

### 2. User Profile Management

* Store platform usernames
* Edit profile details
* Validation of handles
* Profile linked to authenticated user

### 3. Multi-Platform Data Integration

* Fetch statistics from LeetCode API
* Fetch rating & submissions from Codeforces
* Fetch commits and languages from GitHub
* Normalize all data into common model

### 4. Dashboard

* Total problems solved
* Platform-wise split
* Daily activity heatmap
* Current streak counter
* Recent activity list

### 5. Platform Detail Pages

* LeetCode difficulty distribution
* Codeforces rating graph
* CodeChef Contest
* GitHub contribution stats
* Recent problems/commits

### 6. Analytics & Visualization

* Weekly progress charts
* Language usage graph
* Acceptance rate
* Strong vs weak topic analysis

### 7. Local Caching

* Hive based offline storage
* Auto refresh after 24 hours
* Manual sync option

### 8. State Management

* AuthProvider
* ProfileProvider
* StatsProvider
* Centralized error handling


### 9. Settings

* Edit connected platforms
* Dark/Light theme
* Clear cache
* Logout

---

## 🛠 Tech Stack

* Flutter & Dart
* Provider (State Management)
* Hive (Local DB)
* REST APIs
* fl_chart (Visualization)
* Firebase Authentication

---

## 📂 Folder Structure

lib/
├── models/
├── providers/
├── services/
├── screens/
├── widgets/
└── utils/

---

## 🎯 Outcome

* Automated coding analytics
* Real-world API integration 
---

## 📌 Future Scope

* CodeChef integration
* Contest reminders
* PDF report export
* Social sharing of stats

---

Built as a portfolio project to demonstrate Flutter development, API integration,

# Safe-Guard 🚨

## Project Overview

**Safe-Guard** is a comprehensive emergency alert Flutter application designed to provide users with a reliable and efficient way to send and receive emergency notifications. The application enables quick dissemination of critical alerts to designated emergency contacts, emergency services, and community members during times of crisis.

With an intuitive user interface and robust backend infrastructure, Safe-Guard empowers users to:

- Send emergency alerts with one tap  
- Receive real-time notifications from trusted contacts  
- Share location information with responders  
- Maintain a network of trusted emergency contacts  
- Track alert status and response metrics  

---

## Features 🎯

### Core Emergency Features
- **One-Tap Emergency Alert**: Send alerts instantly to all designated emergency contacts  
- **Real-Time Notifications**: Receive immediate alerts from trusted contacts  
- **Location Sharing**: Automatically share GPS location with responders  
- **Alert Customization**: Personalize alert messages by type and severity  
- **Geofencing Support**: Trigger alerts automatically based on location  

### User Management
- **Contact Management**: Maintain a trusted emergency contact list  
- **User Profile**: Store personal and emergency details  
- **Multi-Contact Alerts**: Notify multiple contacts simultaneously  
- **Contact Groups**: Organize contacts (family, work, neighbors, etc.)  

### Communication & Tracking
- **Alert History**: View sent and received alerts  
- **Response Tracking**: Monitor acknowledgment status  
- **Message Threads**: Coordinate responses within alerts  
- **Offline Mode**: Limited offline functionality with sync on reconnect  

### Security & Privacy
- **End-to-End Encryption**: Secure data transmission  
- **Permission Management**: Control location and notification access  
- **Data Privacy**: No data shared without consent  
- **Secure Authentication**: Encrypted login credentials  

---

## Installation Instructions 📲

### Prerequisites
Ensure the following are installed:

- **Flutter SDK** ≥ 3.0  
- **Dart SDK** ≥ 3.0 (included with Flutter)  
- **Android Studio** or **Xcode**  
- **Git**  
- **Active Internet Connection**

### Step-by-Step Installation

#### 1. Clone the Repository
```bash
git clone https://github.com/dev-simion/Safe-Guard.git
cd Safe-Guard
````

#### 2. Install Dependencies

```bash
flutter pub get
```

---

## Required Dependencies

Key packages used:

* `flutter` – Core Flutter framework
* `firebase_core` – Firebase initialization
* `firebase_messaging` – Push notifications
* `geolocator` – GPS services
* `provider` – State management
* `sqflite` – Local database
* `http` – API communication
* `uuid` – Unique identifiers
* `intl` – Internationalization

---

## Usage Guide 📖

### Getting Started

#### First Launch

1. Install and open the app
2. Accept required permissions
3. Create an account
4. Verify via email or SMS
5. Set up emergency profile

### Emergency Profile Setup

Navigate to **Settings → Emergency Profile** and enter:

* Full Name
* Emergency Contact Number
* Medical Conditions
* Allergies
* Medications
* Home Address

### Add Emergency Contacts

1. Open **Contacts**
2. Tap **+ Add Contact**
3. Enter contact details
4. Save

---

## Sending an Emergency Alert

### Quick Alert (Recommended)

1. Tap the red **SOS** button
2. Select emergency type
3. Add optional message
4. Confirm and send

Location is shared automatically.

### Custom Alert

1. Open **Create Alert**
2. Choose type and severity
3. Select contacts
4. Add message
5. Send

---

## Managing Alerts

### View Alert History

* Navigate to **History**
* Filter by:

  * Sent / Received
  * Date range
  * Alert type

### Respond to Alerts

Options include:

* Acknowledge receipt
* Confirm help
* Call sender
* Share location
* Send message

### Cancel an Active Alert

1. Open **Active Alerts**
2. Select alert
3. Tap **Cancel**
4. Confirm

All contacts are notified.

---

## Location Services

### Enable Location Sharing

**Settings → Location**

* Enable sharing
* Choose update frequency:

  * Real-time
  * 30 seconds
  * 5 minutes

### View Contact Location

* Open received alert
* Tap map icon
* Get directions via native maps

---

## Project Structure 🏗️

```
Safe-Guard/
├── android/
├── ios/
├── lib/
│   ├── main.dart
│   ├── models/
│   ├── services/
│   ├── providers/
│   ├── screens/
│   ├── widgets/
│   ├── utils/
│   ├── config/
│   └── l10n/
├── test/
├── pubspec.yaml
├── README.md
├── CHANGELOG.md
└── LICENSE
```

### Key Directories

* `models/` – Data structures
* `services/` – Business logic
* `providers/` – State management
* `screens/` – UI pages
* `widgets/` – Reusable components
* `utils/` – Helpers & constants

---

## Contributing Guidelines 🤝

### Before You Start

* Fork the repo
* Create a feature branch
* Write focused commits
* Test thoroughly

### Naming Conventions

* Classes: `PascalCase`
* Methods/Variables: `camelCase`
* Constants: `const camelCase`
* Private members: `_underscore`

---

## Contact Information 📞

**Maintainer:** Simion Sterling
**GitHub:** @dev-simion
**Email:** [simionksterling@gmail.com](mailto:simionksterling@gmail.com)

---

## License 📄

MIT License – see `LICENSE` file.

### Summary

* ✅ Free for personal & commercial use
* ✅ Modification & distribution allowed
* ⚠️ License must be included
* ⚠️ No warranty

---

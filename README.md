# BuddyApp

A native iOS app for creating groups, planning events, and staying connected with friends. Built with Swift, SwiftUI, and Firebase.

---

## Tech Stack

- **iOS 17+** · SwiftUI · Swift Concurrency (async/await)
- **Firebase**: Auth, Firestore, Cloud Messaging (FCM), Cloud Functions (TypeScript)
- **MapKit** for event location previews
- **MVVM** with `@Observable` view models

---

## Project Structure

```
buddyapp/
├── buddyapp.xcodeproj/
├── buddyapp/
│   ├── BuddyApp.swift           # App entry point + AppDelegate
│   ├── Models/                  # AppUser, Group, Invite, Event
│   ├── Views/
│   │   ├── Auth/                # Login, SignUp, ResetPassword
│   │   ├── Groups/              # GroupsTab, GroupDetail, Invite, Members
│   │   ├── Events/              # EventsTab, EventDetail, CreateEvent
│   │   └── Profile/             # Profile, EditProfile, NotificationSettings
│   ├── ViewModels/              # GroupsViewModel, GroupDetailViewModel, EventsViewModel
│   ├── Services/                # AuthService, FirebaseService, NotificationService
│   └── Components/              # Reusable UI: cards, buttons, text fields
├── functions/
│   └── src/index.ts             # Cloud Functions: onEventCreated, onInviteCreated
├── firestore.rules              # Security rules
├── firestore.indexes.json       # Composite indexes
└── firebase.json
```

---

## Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com) and create a new project.
2. Add an **iOS app** with bundle ID `com.buddyapp.app`.
3. Download **`GoogleService-Info.plist`** and drag it into the `buddyapp/` folder in Xcode (ensure "Copy items if needed" is checked).

### 2. Enable Firebase Services

In the Firebase Console:

- **Authentication** → Sign-in method → Enable **Email/Password**
- **Firestore** → Create database (start in production mode)
- **Cloud Messaging** → No extra setup needed (configured via APNs below)

### 3. Enable APNs (Push Notifications)

1. In [Apple Developer Portal](https://developer.apple.com):
   - Create an **APNs Authentication Key** (or certificate) under Certificates, Identifiers & Profiles → Keys
   - Enable **Push Notifications** capability for your App ID
2. In Firebase Console → Project Settings → Cloud Messaging:
   - Upload the APNs **Auth Key** (or p12 certificate), entering your Team ID and Key ID

3. In Xcode:
   - Select the `buddyapp` target → Signing & Capabilities
   - Add **Push Notifications** capability
   - Add **Background Modes** capability and check **Remote notifications**

### 4. Add Firebase SDK via Swift Package Manager

In Xcode: **File → Add Package Dependencies...**

- URL: `https://github.com/firebase/firebase-ios-sdk`
- Version: Up to Next Major from `10.0.0`
- Add these products to the `buddyapp` target:
  - `FirebaseAuth`
  - `FirebaseFirestore`
  - `FirebaseMessaging`

### 5. Deploy Firestore Rules & Indexes

```bash
# Install Firebase CLI if needed
npm install -g firebase-tools

# Login
firebase login

# Set your project
firebase use --add   # select your project

# Deploy rules and indexes
firebase deploy --only firestore
```

### 6. Deploy Cloud Functions

```bash
cd functions
npm install

# Build & deploy
firebase deploy --only functions
```

The two functions deployed are:
- **`onEventCreated`** — notifies all group members when a new event is created
- **`onInviteCreated`** — notifies the invited user when they receive a group invite

---

## Firestore Security Rules Summary

| Collection | Read | Write |
|---|---|---|
| `users` | Any authenticated user | Own document only |
| `groups` (public) | Any authenticated user | Creator (all fields); members (join/leave only) |
| `groups` (private) | Members only | Creator (all fields); members (leave only) |
| `events` | Group members only | Group members (create/RSVP); creator (delete) |
| `invites` | Invited user, inviter, group members | Group members (create for private groups); invited user (accept/decline) |

Search queries for groups are restricted to `visibility == "public"` at the rules level.

---

## Data Models

### User
```
id, email, displayName, profileImageURL?, fcmToken?, groupIDs[]
```

### Group
```
id, name, description, visibility ("public"|"private"), creatorID, memberIDs[], createdAt
```

### Invite (private groups only)
```
id, groupID, groupName, invitedUserID, invitedByUserID, invitedByDisplayName,
status ("pending"|"accepted"|"declined"), createdAt
```

### Event
```
id, groupID, groupName, creatorID, title, description, address, dateTime,
rsvps: {userID: "going"|"not_going"|"maybe"}, createdAt
```

---

## Seeding Test Data

A seed script creates 7 test users, 5 groups (3 public, 2 private), 11 events, and 3 pending invites so you have a fully populated dev environment immediately.

```bash
cd scripts
npm install

# Copy your Firebase service account key here (from Console → Project Settings → Service accounts)
cp ~/Downloads/your-serviceAccountKey.json serviceAccountKey.json

# Seed the database
FIREBASE_PROJECT_ID=your-project-id npm run seed

# Or wipe all seed data and re-seed cleanly
FIREBASE_PROJECT_ID=your-project-id npm run seed:clean
```

### Seeded data

**7 test accounts** — all use password `Test1234!`

| Email | Name | Groups |
|---|---|---|
| `alex@test.com` | Alex Rivera | Weekend Hikers, SF Foodies, Indie Hackers SF |
| `jamie@test.com` | Jamie Chen | Weekend Hikers, SF Foodies, Indie Hackers SF |
| `morgan@test.com` | Morgan Blake | Weekend Hikers, The Page Turners, Morning Yoga Crew |
| `casey@test.com` | Casey Kim | Weekend Hikers, The Page Turners, Morning Yoga Crew |
| `taylor@test.com` | Taylor Nguyen | SF Foodies, Indie Hackers SF, 📨 invite to Page Turners |
| `riley@test.com` | Riley Santos | Weekend Hikers, The Page Turners, Morning Yoga Crew, 📨 invite to Indie Hackers |
| `sam@test.com` | Sam Patel | SF Foodies, Indie Hackers SF, Morning Yoga Crew, 📨 invite to Page Turners |

**5 groups**
- 🌐 Weekend Hikers — 3 upcoming hikes, 5 members
- 🌐 SF Foodies — 3 dining events, 4 members
- 🌐 Morning Yoga Crew — 2 sessions, 4 members
- 🔒 The Page Turners — monthly book club, 3 members (2 pending invites)
- 🔒 Indie Hackers SF — hackathon + demo night, 4 members (1 pending invite)

**Sign in as `taylor@test.com`** to experience the invite flow — Taylor has a pending invite to The Page Turners waiting.

---

## Features

- **Auth**: Sign up, log in, persistent sessions, password reset, sign out
- **Groups**: Create public/private groups; public groups are searchable and instantly joinable; private groups are invite-only
- **Invites**: Members of private groups can invite by name/email; invited users get push notifications; accept/decline from Invitations sheet
- **Events**: Any group member can create events with title, description, address (with map preview), and date/time; RSVP with Going/Maybe/Not Going
- **Aggregated Events tab**: Upcoming events across all joined groups in one chronological list
- **Push Notifications**: FCM token stored on login; Cloud Functions trigger notifications on new events and new invites; tapping deep-links to the relevant screen
- **Dark mode**: Full support via system colors and `.ultraThinMaterial` backgrounds

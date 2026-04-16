/**
 * BuddyApp Firestore Seed Script
 *
 * Usage:
 *   cd scripts && npm install
 *   npm run seed              # seed the database
 *   npm run seed:clean        # wipe all seed data, then re-seed
 *
 * Prerequisites:
 *   - Set GOOGLE_APPLICATION_CREDENTIALS env var to your Firebase service account JSON, OR
 *   - Place serviceAccountKey.json in this scripts/ folder
 *   - Set FIREBASE_PROJECT_ID env var (or edit PROJECT_ID below)
 */

import * as admin from "firebase-admin";
import * as fs from "fs";
import * as path from "path";

// ─── Config ────────────────────────────────────────────────────────────────

const PROJECT_ID = process.env.FIREBASE_PROJECT_ID ?? "YOUR_PROJECT_ID";
const SEED_PASSWORD = "Test1234!"; // password for all seed accounts

// Try local service account key first, then fall back to ADC
const serviceAccountPath = path.join(__dirname, "serviceAccountKey.json");
if (fs.existsSync(serviceAccountPath)) {
  const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, "utf8"));
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: PROJECT_ID,
  });
} else {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: PROJECT_ID,
  });
}

const db = admin.firestore();
const auth = admin.auth();

// ─── Data Definitions ──────────────────────────────────────────────────────

const SEED_USERS = [
  { email: "alex@test.com",    displayName: "Alex Rivera",    id: "seed_user_alex" },
  { email: "jamie@test.com",   displayName: "Jamie Chen",     id: "seed_user_jamie" },
  { email: "morgan@test.com",  displayName: "Morgan Blake",   id: "seed_user_morgan" },
  { email: "casey@test.com",   displayName: "Casey Kim",      id: "seed_user_casey" },
  { email: "taylor@test.com",  displayName: "Taylor Nguyen",  id: "seed_user_taylor" },
  { email: "riley@test.com",   displayName: "Riley Santos",   id: "seed_user_riley" },
  { email: "sam@test.com",     displayName: "Sam Patel",      id: "seed_user_sam" },
];

// Convenience aliases
const [ALEX, JAMIE, MORGAN, CASEY, TAYLOR, RILEY, SAM] = SEED_USERS.map(u => u.id);

type Visibility = "public" | "private";

interface SeedGroup {
  id: string;
  name: string;
  description: string;
  visibility: Visibility;
  creatorID: string;
  memberIDs: string[];
}

const SEED_GROUPS: SeedGroup[] = [
  {
    id: "seed_group_hikers",
    name: "Weekend Hikers",
    description: "Exploring trails every weekend. All skill levels welcome!",
    visibility: "public",
    creatorID: ALEX,
    memberIDs: [ALEX, JAMIE, MORGAN, CASEY, RILEY],
  },
  {
    id: "seed_group_foodies",
    name: "SF Foodies",
    description: "Discovering the best restaurants, food trucks, and hidden gems in the Bay Area.",
    visibility: "public",
    creatorID: JAMIE,
    memberIDs: [JAMIE, TAYLOR, SAM, ALEX],
  },
  {
    id: "seed_group_bookclub",
    name: "The Page Turners",
    description: "Monthly book club — we read everything from sci-fi to literary fiction.",
    visibility: "private",
    creatorID: MORGAN,
    memberIDs: [MORGAN, CASEY, RILEY],
  },
  {
    id: "seed_group_devs",
    name: "Indie Hackers SF",
    description: "Side projects, startup war stories, and weekend hackathons.",
    visibility: "private",
    creatorID: SAM,
    memberIDs: [SAM, ALEX, JAMIE, TAYLOR],
  },
  {
    id: "seed_group_yoga",
    name: "Morning Yoga Crew",
    description: "6am sunrise yoga in Dolores Park. Bring a mat and good vibes.",
    visibility: "public",
    creatorID: CASEY,
    memberIDs: [CASEY, MORGAN, RILEY, SAM],
  },
];

const now = Date.now();
const DAY = 86400000;
const HOUR = 3600000;

interface SeedEvent {
  id: string;
  groupID: string;
  groupName: string;
  creatorID: string;
  title: string;
  description: string;
  address: string;
  dateTime: admin.firestore.Timestamp;
  rsvps: Record<string, string>;
}

const SEED_EVENTS: SeedEvent[] = [
  // Weekend Hikers events
  {
    id: "seed_event_marin",
    groupID: "seed_group_hikers",
    groupName: "Weekend Hikers",
    creatorID: ALEX,
    title: "Marin Headlands Loop",
    description: "8-mile loop with stunning views of the Golden Gate. Moderate difficulty. We'll meet at the Conzelman Rd trailhead and carpool from there.",
    address: "Conzelman Rd, Sausalito, CA 94965",
    dateTime: admin.firestore.Timestamp.fromMillis(now + 3 * DAY + 9 * HOUR),
    rsvps: {
      [ALEX]: "going",
      [JAMIE]: "going",
      [MORGAN]: "maybe",
      [CASEY]: "going",
      [RILEY]: "not_going",
    },
  },
  {
    id: "seed_event_muirwoods",
    groupID: "seed_group_hikers",
    groupName: "Weekend Hikers",
    creatorID: JAMIE,
    title: "Muir Woods Morning Walk",
    description: "Easy 4-mile stroll through the old-growth redwoods. Dog-friendly trail. Arrive early to beat the crowds — parking fills up by 9am.",
    address: "1 Muir Woods Rd, Mill Valley, CA 94941",
    dateTime: admin.firestore.Timestamp.fromMillis(now + 10 * DAY + 8 * HOUR),
    rsvps: {
      [JAMIE]: "going",
      [ALEX]: "going",
      [RILEY]: "going",
    },
  },
  {
    id: "seed_event_mt_tam",
    groupID: "seed_group_hikers",
    groupName: "Weekend Hikers",
    creatorID: MORGAN,
    title: "Mt. Tamalpais Summit",
    description: "Challenging 12-mile round trip to the East Peak summit. Bring layers — it gets windy at the top. Epic 360° views on clear days.",
    address: "801 Panoramic Hwy, Mill Valley, CA 94941",
    dateTime: admin.firestore.Timestamp.fromMillis(now + 17 * DAY + 7 * HOUR),
    rsvps: {
      [MORGAN]: "going",
      [CASEY]: "maybe",
    },
  },

  // SF Foodies events
  {
    id: "seed_event_ramen",
    groupID: "seed_group_foodies",
    groupName: "SF Foodies",
    creatorID: JAMIE,
    title: "Ramen Crawl — Japantown",
    description: "We're hitting 3 ramen spots in one afternoon: Marufuku, Mensho, and Nojo Ramen Bar. Pace yourself. Strong stomachs only 🍜",
    address: "1581 Webster St, San Francisco, CA 94115",
    dateTime: admin.firestore.Timestamp.fromMillis(now + 2 * DAY + 13 * HOUR),
    rsvps: {
      [JAMIE]: "going",
      [TAYLOR]: "going",
      [SAM]: "going",
      [ALEX]: "maybe",
    },
  },
  {
    id: "seed_event_ferry_building",
    groupID: "seed_group_foodies",
    groupName: "SF Foodies",
    creatorID: TAYLOR,
    title: "Ferry Building Saturday Market",
    description: "Farmer's market morning followed by brunch at The Slanted Door. Meet at the Ferry Building clock tower at 10am.",
    address: "Ferry Building, San Francisco, CA 94105",
    dateTime: admin.firestore.Timestamp.fromMillis(now + 5 * DAY + 10 * HOUR),
    rsvps: {
      [TAYLOR]: "going",
      [JAMIE]: "going",
      [SAM]: "not_going",
    },
  },
  {
    id: "seed_event_dim_sum",
    groupID: "seed_group_foodies",
    groupName: "SF Foodies",
    creatorID: SAM,
    title: "Dim Sum Sunday — Yank Sing",
    description: "Classic dim sum at Yank Sing. Reservations for 6 — we'll do carts. Show up hungry.",
    address: "101 Spear St, San Francisco, CA 94105",
    dateTime: admin.firestore.Timestamp.fromMillis(now + 12 * DAY + 11 * HOUR),
    rsvps: {
      [SAM]: "going",
      [JAMIE]: "going",
      [TAYLOR]: "going",
      [ALEX]: "going",
    },
  },

  // The Page Turners (private)
  {
    id: "seed_event_bookclub_meeting",
    groupID: "seed_group_bookclub",
    groupName: "The Page Turners",
    creatorID: MORGAN,
    title: "April Book Discussion — \"Piranesi\"",
    description: "We're discussing Susanna Clarke's Piranesi. Please finish it before the meeting! Morgan's hosting — bring snacks.",
    address: "789 Castro St, San Francisco, CA 94114",
    dateTime: admin.firestore.Timestamp.fromMillis(now + 7 * DAY + 19 * HOUR),
    rsvps: {
      [MORGAN]: "going",
      [CASEY]: "going",
      [RILEY]: "maybe",
    },
  },

  // Indie Hackers (private)
  {
    id: "seed_event_hackathon",
    groupID: "seed_group_devs",
    groupName: "Indie Hackers SF",
    creatorID: SAM,
    title: "Weekend Hackathon — Ship It",
    description: "48-hour build weekend. Theme: AI tools for everyday people. Judging Sunday at 5pm. Prizes for top 3 projects. Bring your laptop and ideas.",
    address: "Galvanize SF, 44 Tehama St, San Francisco, CA 94105",
    dateTime: admin.firestore.Timestamp.fromMillis(now + 4 * DAY + 10 * HOUR),
    rsvps: {
      [SAM]: "going",
      [ALEX]: "going",
      [JAMIE]: "going",
      [TAYLOR]: "maybe",
    },
  },
  {
    id: "seed_event_demo_night",
    groupID: "seed_group_devs",
    groupName: "Indie Hackers SF",
    creatorID: ALEX,
    title: "Demo Night & Drinks",
    description: "Show off what you've been building. 5-min demos, feedback from the group, then we head to Zeitgeist. All skill levels welcome — works in progress encouraged.",
    address: "Noisebridge, 272 Capp St, San Francisco, CA 94110",
    dateTime: admin.firestore.Timestamp.fromMillis(now + 14 * DAY + 18 * HOUR),
    rsvps: {
      [ALEX]: "going",
      [SAM]: "going",
      [TAYLOR]: "going",
    },
  },

  // Morning Yoga Crew
  {
    id: "seed_event_yoga_tuesday",
    groupID: "seed_group_yoga",
    groupName: "Morning Yoga Crew",
    creatorID: CASEY,
    title: "Sunrise Flow — Dolores Park",
    description: "60-min vinyasa flow with Casey leading. Bring your own mat. If it's raining we'll move to the community room at the YMCA.",
    address: "Dolores Park, San Francisco, CA 94114",
    dateTime: admin.firestore.Timestamp.fromMillis(now + 1 * DAY + 6 * HOUR),
    rsvps: {
      [CASEY]: "going",
      [MORGAN]: "going",
      [RILEY]: "going",
      [SAM]: "maybe",
    },
  },
  {
    id: "seed_event_yoga_saturday",
    groupID: "seed_group_yoga",
    groupName: "Morning Yoga Crew",
    creatorID: RILEY,
    title: "Saturday Restorative Yoga",
    description: "Slower pace this week — we're doing a restorative yin session. Great for recovery. Props provided. 75 minutes.",
    address: "Dolores Park, San Francisco, CA 94114",
    dateTime: admin.firestore.Timestamp.fromMillis(now + 6 * DAY + 8 * HOUR),
    rsvps: {
      [RILEY]: "going",
      [CASEY]: "going",
      [MORGAN]: "not_going",
      [SAM]: "going",
    },
  },
];

interface SeedInvite {
  id: string;
  groupID: string;
  groupName: string;
  invitedUserID: string;
  invitedByUserID: string;
  invitedByDisplayName: string;
  status: "pending";
}

// Pending invites — private groups only
// Taylor and Sam have pending invites to The Page Turners
// Riley has a pending invite to Indie Hackers
const SEED_INVITES: SeedInvite[] = [
  {
    id: "seed_invite_taylor_bookclub",
    groupID: "seed_group_bookclub",
    groupName: "The Page Turners",
    invitedUserID: TAYLOR,
    invitedByUserID: MORGAN,
    invitedByDisplayName: "Morgan Blake",
    status: "pending",
  },
  {
    id: "seed_invite_sam_bookclub",
    groupID: "seed_group_bookclub",
    groupName: "The Page Turners",
    invitedUserID: SAM,
    invitedByUserID: CASEY,
    invitedByDisplayName: "Casey Kim",
    status: "pending",
  },
  {
    id: "seed_invite_riley_devs",
    groupID: "seed_group_devs",
    groupName: "Indie Hackers SF",
    invitedUserID: RILEY,
    invitedByUserID: SAM,
    invitedByDisplayName: "Sam Patel",
    status: "pending",
  },
];

// ─── Helpers ───────────────────────────────────────────────────────────────

const SEED_IDS = {
  users: SEED_USERS.map(u => u.id),
  groups: SEED_GROUPS.map(g => g.id),
  events: SEED_EVENTS.map(e => e.id),
  invites: SEED_INVITES.map(i => i.id),
};

async function deleteCollection(collectionPath: string, ids: string[]) {
  const batch = db.batch();
  for (const id of ids) {
    batch.delete(db.collection(collectionPath).doc(id));
  }
  await batch.commit();
}

async function deleteAuthUsers(ids: string[]) {
  for (const id of ids) {
    try {
      await auth.deleteUser(id);
    } catch {
      // User may not exist — ignore
    }
  }
}

// ─── Clean ─────────────────────────────────────────────────────────────────

async function cleanSeedData() {
  console.log("🧹 Cleaning existing seed data...");
  await Promise.all([
    deleteCollection("users", SEED_IDS.users),
    deleteCollection("groups", SEED_IDS.groups),
    deleteCollection("events", SEED_IDS.events),
    deleteCollection("invites", SEED_IDS.invites),
    deleteAuthUsers(SEED_IDS.users),
  ]);
  console.log("   ✓ Seed data removed");
}

// ─── Seed ──────────────────────────────────────────────────────────────────

async function seedUsers() {
  console.log("\n👤 Creating users...");
  for (const user of SEED_USERS) {
    // Build groupIDs for this user
    const groupIDs = SEED_GROUPS
      .filter(g => g.memberIDs.includes(user.id))
      .map(g => g.id);

    // Create Firebase Auth user with fixed UID
    try {
      await auth.createUser({
        uid: user.id,
        email: user.email,
        password: SEED_PASSWORD,
        displayName: user.displayName,
        emailVerified: true,
      });
    } catch (err: any) {
      if (err.code === "auth/uid-already-exists" || err.code === "auth/email-already-exists") {
        // Already exists — update instead
        await auth.updateUser(user.id, {
          email: user.email,
          password: SEED_PASSWORD,
          displayName: user.displayName,
        });
      } else {
        throw err;
      }
    }

    // Write Firestore user doc
    await db.collection("users").doc(user.id).set({
      email: user.email,
      displayName: user.displayName,
      profileImageURL: null,
      fcmToken: null,
      groupIDs,
    });

    console.log(`   ✓ ${user.displayName} (${user.email})`);
  }
}

async function seedGroups() {
  console.log("\n🏘  Creating groups...");
  const batch = db.batch();
  for (const group of SEED_GROUPS) {
    batch.set(db.collection("groups").doc(group.id), {
      name: group.name,
      description: group.description,
      visibility: group.visibility,
      creatorID: group.creatorID,
      memberIDs: group.memberIDs,
      createdAt: admin.firestore.Timestamp.fromMillis(now - 14 * DAY),
    });
    const vis = group.visibility === "public" ? "🌐" : "🔒";
    console.log(`   ✓ ${vis} ${group.name} (${group.memberIDs.length} members)`);
  }
  await batch.commit();
}

async function seedEvents() {
  console.log("\n📅 Creating events...");
  const batch = db.batch();
  for (const event of SEED_EVENTS) {
    batch.set(db.collection("events").doc(event.id), {
      groupID: event.groupID,
      groupName: event.groupName,
      creatorID: event.creatorID,
      title: event.title,
      description: event.description,
      address: event.address,
      dateTime: event.dateTime,
      rsvps: event.rsvps,
      createdAt: admin.firestore.Timestamp.fromMillis(now - 2 * DAY),
    });
    const going = Object.values(event.rsvps).filter(s => s === "going").length;
    console.log(`   ✓ "${event.title}" — ${going} going`);
  }
  await batch.commit();
}

async function seedInvites() {
  console.log("\n📨 Creating pending invites...");
  const batch = db.batch();
  for (const invite of SEED_INVITES) {
    batch.set(db.collection("invites").doc(invite.id), {
      groupID: invite.groupID,
      groupName: invite.groupName,
      invitedUserID: invite.invitedUserID,
      invitedByUserID: invite.invitedByUserID,
      invitedByDisplayName: invite.invitedByDisplayName,
      status: invite.status,
      createdAt: admin.firestore.Timestamp.fromMillis(now - 1 * DAY),
    });
    const invitedUser = SEED_USERS.find(u => u.id === invite.invitedUserID);
    console.log(`   ✓ ${invite.invitedByDisplayName} → ${invitedUser?.displayName} (${invite.groupName})`);
  }
  await batch.commit();
}

// ─── Main ──────────────────────────────────────────────────────────────────

async function main() {
  const isClean = process.argv.includes("--clean");

  console.log("═══════════════════════════════════════");
  console.log("  BuddyApp Seed Script");
  console.log(`  Project: ${PROJECT_ID}`);
  console.log("═══════════════════════════════════════");

  if (isClean) {
    await cleanSeedData();
  }

  await seedUsers();
  await seedGroups();
  await seedEvents();
  await seedInvites();

  console.log("\n═══════════════════════════════════════");
  console.log("  ✅ Seed complete!\n");
  console.log("  Test accounts (password: Test1234!)");
  console.log("  ─────────────────────────────────────");
  for (const user of SEED_USERS) {
    const groups = SEED_GROUPS.filter(g => g.memberIDs.includes(user.id));
    const pendingInvites = SEED_INVITES.filter(i => i.invitedUserID === user.id);
    const extras = [
      ...groups.map(g => g.name),
      ...pendingInvites.map(i => `📨 invite: ${i.groupName}`),
    ].join(", ");
    console.log(`  ${user.email.padEnd(22)} ${user.displayName.padEnd(16)} [${extras}]`);
  }
  console.log("═══════════════════════════════════════\n");
}

main().catch(err => {
  console.error("❌ Seed failed:", err);
  process.exit(1);
});

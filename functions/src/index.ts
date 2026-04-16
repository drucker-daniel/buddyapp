import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// ─── Helper ────────────────────────────────────────────────────────────────

async function getUserFCMToken(userID: string): Promise<string | null> {
  const doc = await db.collection("users").document(userID).get();
  return doc.data()?.fcmToken ?? null;
}

async function sendPushNotification(params: {
  token: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}): Promise<void> {
  try {
    await messaging.send({
      token: params.token,
      notification: { title: params.title, body: params.body },
      data: params.data ?? {},
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    });
  } catch (err) {
    functions.logger.error("FCM send error", err);
  }
}

// ─── Trigger 1: New Event Created ──────────────────────────────────────────

export const onEventCreated = functions.firestore.onDocumentCreated(
  "events/{eventID}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const { groupID, groupName, creatorID, title } = data as {
      groupID: string;
      groupName: string;
      creatorID: string;
      title: string;
    };

    // Fetch the group to get member IDs
    const groupDoc = await db.collection("groups").document(groupID).get();
    const memberIDs: string[] = groupDoc.data()?.memberIDs ?? [];

    // Notify all members except the creator
    const recipients = memberIDs.filter((id) => id !== creatorID);

    await Promise.allSettled(
      recipients.map(async (userID) => {
        const token = await getUserFCMToken(userID);
        if (!token) return;
        await sendPushNotification({
          token,
          title: `New event in ${groupName}`,
          body: title,
          data: {
            type: "new_event",
            eventID: event.params.eventID,
            groupID,
          },
        });
      })
    );
  }
);

// ─── Trigger 2: New Invite Created ─────────────────────────────────────────

export const onInviteCreated = functions.firestore.onDocumentCreated(
  "invites/{inviteID}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const { invitedUserID, invitedByDisplayName, groupName } = data as {
      invitedUserID: string;
      invitedByDisplayName: string;
      groupName: string;
    };

    const token = await getUserFCMToken(invitedUserID);
    if (!token) return;

    await sendPushNotification({
      token,
      title: "You've been invited!",
      body: `${invitedByDisplayName} invited you to join ${groupName}`,
      data: {
        type: "new_invite",
        inviteID: event.params.inviteID,
      },
    });
  }
);

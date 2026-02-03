const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();

/**
 * Trigger: Sync user profile to the matching_pool collection
 * whenever a user document is updated.
 */
exports.syncToMatchingPool = functions.firestore
    .document("users/{userId}")
    .onWrite(async (change, context) => {
        const userId = context.params.userId;
        const data = change.after.exists ? change.after.data() : null;

        if (!data) {
            // User deleted, remove from pool
            return db.collection("matching_pool").doc(userId).delete();
        }

        // Only sync necessary fields for matching
        const poolData = {
            uid: userId,
            fullName: data.fullName || "Stranger",
            profilePicUrl: data.profilePicUrl || "",
            gender: data.gender || "Any",
            age: parseInt(data.age) || 0,
            interests: data.chatPreferences?.interests || data.interests || [],
            dealBreakers: data.chatPreferences?.dealBreakers || [],
            latitude: data.latitude || null,
            longitude: data.longitude || null,
            lastSeen: data.lastSeen || admin.firestore.FieldValue.serverTimestamp(),
            verificationLevel: data.verificationLevel || 0,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        return db.collection("matching_pool").doc(userId).set(poolData, { merge: true });
    });

/**
 * Callable: Find a global match for the calling user.
 */
exports.findGlobalMatch = functions.https.onCall(async (data, context) => {
    try {
        if (!context.auth) {
            throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
        }

        const callerId = context.auth.uid;
        console.log(`Starting global match for caller: ${callerId}`);

        const {
            preferredGender,
            preferredMinAge,
            preferredMaxAge,
            preferVerifiedOnly,
            interests,
            dealBreakers,
            latitude,
            longitude
        } = data;

        // 1. Fetch potential candidates active in last 48 hours
        const fortyEightHoursAgo = new Date(Date.now() - 48 * 60 * 60 * 1000);
        const poolSnapshot = await db.collection("matching_pool")
            .where("lastSeen", ">=", fortyEightHoursAgo)
            .limit(100)
            .get();

        if (poolSnapshot.empty) {
            console.log("Matching pool is empty or no recently active users.");
            return { status: "no_match_found" };
        }

        // 2. Fetch blocked users and existing connections
        const userDoc = await db.collection("users").doc(callerId).get();
        if (!userDoc.exists) {
            console.error(`User document for ${callerId} not found in 'users' collection.`);
            return { status: "error", message: "User profile not found. Please complete your profile." };
        }

        const userData = userDoc.data() || {};
        const blockedUsers = userData.blockedUsers || [];
        const friends = userData.friends || [];
        const userGender = userData.gender || "Any";
        const strangersList = userData.strangersList || [];

        // Check if a match was ALREADY created just seconds ago (Strong Consistency)
        // This prevents double matches from accidental rapid clicks or retries
        const recentMatch = strangersList.find(s => {
            if (!s.matchedAt) return false;
            const matchTime = s.matchedAt.toDate ? s.matchedAt.toDate() : new Date(s.matchedAt);
            return (Date.now() - matchTime.getTime()) < 10000; // 10 seconds grace period
        });

        if (recentMatch) {
            console.log(`Found a very recent match (${recentMatch.userId}). Returning it instead of creating new one.`);
            // Fetch match details to return them
            const partnerDoc = await db.collection("users").doc(recentMatch.userId).get();
            const partnerData = partnerDoc.data() || {};
            return {
                status: "matched",
                chatRoomId: recentMatch.chatRoomId,
                matchedUserId: recentMatch.userId,
                matchedUserName: partnerData.fullName || "Stranger",
                matchedUserProfilePic: partnerData.profilePicUrl || "",
                compatibilityScore: 100 // Already matched
            };
        }

        const existingStrangerIds = strangersList.map(s => s.userId);

        const candidates = [];

        poolSnapshot.forEach(doc => {
            const candidate = doc.data();
            const candId = candidate.uid;

            // Skip self, blocked, friends, or existing strangers
            if (candId === callerId) return;
            if (blockedUsers.includes(candId)) return;
            if (friends.includes(candId)) return;
            if (existingStrangerIds.includes(candId)) return;

            // Helper to normalize strings (lowercase, trim) for comparison
            const normalize = (str) => typeof str === "string" ? str.toLowerCase().trim() : "";

            // Normalize my dealbreakers and my interests
            const myDealBreakers = (dealBreakers || []).map(normalize);
            const myInterests = (interests || []).map(normalize);

            // Strict Criteria: Deal-breakers
            // Does candidate have an interest I dislike?
            if (myDealBreakers.length > 0 && candidate.interests && Array.isArray(candidate.interests)) {
                const candInterests = candidate.interests.map(normalize);
                if (myDealBreakers.some(dbItem => candInterests.some(ci => ci.includes(dbItem) || dbItem.includes(ci)))) {
                    console.log(`Skipping ${candidate.fullName}: Candidate has an interest I dislike.`);
                    return;
                }
            }
            // Do I have an interest candidate dislikes?
            if (candidate.dealBreakers && Array.isArray(candidate.dealBreakers) && myInterests.length > 0) {
                const candDealBreakers = candidate.dealBreakers.map(normalize);
                if (candDealBreakers.some(dbItem => myInterests.some(mi => mi.includes(dbItem) || dbItem.includes(mi)))) {
                    console.log(`Skipping ${candidate.fullName}: I have an interest candidate dislikes.`);
                    return;
                }
            }

            // Strict Criteria: Gender
            if (preferredGender === "opposite") {
                if (candidate.gender === userGender) return;
            } else if (preferredGender && preferredGender !== "Any") {
                if (candidate.gender !== preferredGender) return;
            }

            // Strict Criteria: Verification
            if (preferVerifiedOnly && (candidate.verificationLevel || 0) < 2) return;

            // 3. Scoring
            let score = 0;
            let interestScore = 0;
            let commonDealBreakerScore = 0;
            let ageScore = 0;
            let verificationScore = 0;
            let locationScore = 0;

            // Interest Score (40%) - Common interests are good
            if (myInterests.length > 0 && candidate.interests && Array.isArray(candidate.interests)) {
                const candInterests = candidate.interests.map(normalize);
                const common = myInterests.filter(mi => candInterests.some(ci => ci.includes(mi) || mi.includes(ci))).length;
                interestScore = (common / Math.max(myInterests.length, 1)) * 40;
                score += interestScore;
            }

            // Common Deal-breakers Score (10%) - Sharing same dislikes is also compatibility
            if (myDealBreakers.length > 0 && candidate.dealBreakers && Array.isArray(candidate.dealBreakers)) {
                const candDealBreakers = candidate.dealBreakers.map(normalize);
                const sharedDislikes = myDealBreakers.filter(md => candDealBreakers.some(cd => cd.includes(md) || md.includes(cd))).length;
                commonDealBreakerScore = (sharedDislikes / Math.max(myDealBreakers.length, 1)) * 10;
                score += commonDealBreakerScore;
            }

            // Age Score (20%)
            if (userData.age && candidate.age) {
                const ageDiff = Math.abs(parseInt(userData.age) - parseInt(candidate.age));
                ageScore = Math.max(0, 20 - (ageDiff * 1));
                score += ageScore;
            }

            // Verification Score (15%)
            if ((candidate.verificationLevel || 0) > 1) {
                verificationScore = 15;
                score += verificationScore;
            }

            // Location Proximity Score (15%)
            if (latitude && longitude && candidate.latitude && candidate.longitude) {
                const dist = calculateDistance(latitude, longitude, candidate.latitude, candidate.longitude);
                if (!isNaN(dist)) {
                    locationScore = Math.max(0, 15 - (dist / 10)); // 1 point less per 10km
                    score += locationScore;
                }
            }

            console.log(`Candidate ${candidate.fullName} (${candId}) | Total Score: ${score.toFixed(2)} [Int: ${interestScore.toFixed(2)}, CommonDB: ${commonDealBreakerScore.toFixed(2)}, Age: ${ageScore.toFixed(2)}, Ver: ${verificationScore.toFixed(2)}, Loc: ${locationScore.toFixed(2)}]`);

            candidates.push({ ...candidate, score: score || 0 });
        });

        if (candidates.length === 0) {
            console.log("No compatible candidates found after filtering.");
            return { status: "no_match_found" };
        }

        // Sort by score and pick best
        candidates.sort((a, b) => b.score - a.score);
        const bestMatch = candidates[0];
        console.log(`Match found! Matched ${callerId} with ${bestMatch.uid} (Score: ${bestMatch.score})`);

        // 4. Create Chat Room (Server-side)
        // Generate ID matching the app: 6-char prefix of sorted UIDs
        const sortedUids = [callerId, bestMatch.uid].sort();
        const p1 = sortedUids[0].substring(0, 6);
        const p2 = sortedUids[1].substring(0, 6);
        const chatRoomId = `${p1}_${p2}`;

        const expiresAt = new Date(Date.now() + 48 * 60 * 60 * 1000); // 48 hours expiry

        // Identify who is user1 and user2 based on sorting
        const isCallerUser1 = callerId === sortedUids[0];

        const chatRoomData = {
            chatRoomId: chatRoomId,
            user1Id: sortedUids[0],
            user2Id: sortedUids[1],
            user1Name: isCallerUser1 ? (userData.fullName || "Someone") : (bestMatch.fullName || "Stranger"),
            user2Name: isCallerUser1 ? (bestMatch.fullName || "Stranger") : (userData.fullName || "Someone"),
            user1ProfilePic: isCallerUser1 ? (userData.profilePicUrl || "") : (bestMatch.profilePicUrl || ""),
            user2ProfilePic: isCallerUser1 ? (bestMatch.profilePicUrl || "") : (userData.profilePicUrl || ""),
            users: sortedUids,
            roomType: "stranger",
            status: "active",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
            lastMessage: "🎉 You've been matched! Say hello!",
            lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
            lastMessageSenderId: "system",
            user1UnreadCount: isCallerUser1 ? 0 : 1,
            user2UnreadCount: isCallerUser1 ? 1 : 0,
            user1HasLiked: false,
            user2HasLiked: false,
        };

        const batch = db.batch();
        batch.set(db.collection("chats").doc(chatRoomId), chatRoomData);

        // Update strangersList for both users
        const matchEntryForCaller = {
            userId: bestMatch.uid,
            chatRoomId: chatRoomId,
            matchedAt: new Date(),
        };
        const matchEntryForTarget = {
            userId: callerId,
            chatRoomId: chatRoomId,
            matchedAt: new Date(),
        };

        batch.set(db.collection("users").doc(callerId), {
            strangersList: admin.firestore.FieldValue.arrayUnion(matchEntryForCaller)
        }, { merge: true });

        batch.set(db.collection("users").doc(bestMatch.uid), {
            strangersList: admin.firestore.FieldValue.arrayUnion(matchEntryForTarget)
        }, { merge: true });

        await batch.commit();

        return {
            status: "matched",
            chatRoomId: chatRoomId,
            matchedUserId: bestMatch.uid,
            matchedUserName: bestMatch.fullName,
            matchedUserProfilePic: bestMatch.profilePicUrl,
            compatibilityScore: bestMatch.score
        };
    } catch (error) {
        console.error("Error in findGlobalMatch:", error);
        return {
            status: "error",
            message: error.message || "An internal error occurred during matching."
        };
    }
});

/**
 * Temporary utility to seed dummy users into the matching pool.
 * Delete this before production!
 */
exports.seedMatchingPool = functions.https.onCall(async (data, context) => {
    const dummies = [
        {
            uid: "aria_p_perfect_match",
            fullName: "Aria",
            gender: "Female",
            age: 23,
            interests: ["🎮 Gaming", "🎵 Music", "💻 Technology"],
            dealBreakers: ["🚬 Smoking"],
            latitude: 31.55,
            longitude: 75.90,
            verificationLevel: 2,
            lastSeen: admin.firestore.FieldValue.serverTimestamp(),
        },
        {
            uid: "zoe_a_artistic_soul",
            fullName: "Zoe",
            gender: "Female",
            age: 22,
            interests: ["🎨 Art", "✈️ Travel", "📷 Photography"],
            dealBreakers: ["🍺 Drinking"],
            latitude: 31.54,
            longitude: 75.89,
            verificationLevel: 2,
            lastSeen: admin.firestore.FieldValue.serverTimestamp(),
        },
        {
            uid: "marcus_f_fit_chef",
            fullName: "Marcus",
            gender: "Male",
            age: 26,
            interests: ["🏋️ Fitness", "🍳 Cooking", "🏎️ Cars"],
            dealBreakers: ["🚬 Smoking"],
            latitude: 31.57,
            longitude: 75.92,
            verificationLevel: 2,
            lastSeen: admin.firestore.FieldValue.serverTimestamp(),
        },
        {
            uid: "chloe_d_dealbreaker",
            fullName: "Chloe",
            gender: "Female",
            age: 21,
            interests: ["🍿 Anime", "🎨 Art", "👘 Cosplay"],
            dealBreakers: ["🎮 Gaming"],
            latitude: 31.56,
            longitude: 75.91,
            verificationLevel: 1,
            lastSeen: admin.firestore.FieldValue.serverTimestamp(),
        },
        {
            uid: "sofia_f_far_away",
            fullName: "Sofia",
            gender: "Female",
            age: 25,
            interests: ["📷 Photography", "🍳 Cooking", "🧘 Yoga"],
            dealBreakers: [],
            latitude: 40.71,
            longitude: -74.00,
            verificationLevel: 2,
            lastSeen: admin.firestore.FieldValue.serverTimestamp(),
        }
    ];

    const batch = db.batch();
    dummies.forEach(d => {
        const ref = db.collection("matching_pool").doc(d.uid);
        batch.set(ref, { ...d, updatedAt: admin.firestore.FieldValue.serverTimestamp() });

        // Also create a basic user doc for them so the system doesn't crash on cross-checks
        const userRef = db.collection("users").doc(d.uid);
        batch.set(userRef, {
            uid: d.uid,
            fullName: d.fullName,
            gender: d.gender,
            age: d.age.toString(),
            profilePicUrl: "", // Ensure it's empty to trigger fallback
            lastSeen: d.lastSeen,
            verificationLevel: d.verificationLevel
        }, { merge: true });
    });

    await batch.commit();
    return { status: "success", message: "Seeded 3 dummy users." };
});

function calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371; // Radius of the earth in km
    const dLat = deg2rad(lat2 - lat1);
    const dLon = deg2rad(lon2 - lon1);
    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c; // Distance in km
}

function deg2rad(deg) {
    return deg * (Math.PI / 180);
}

// ====================================================================================
// NOTIFICATION FUNCTIONS
// ====================================================================================

/**
 * Helper function to send FCM notification to a user
 * @param {string} userId - The user ID to send notification to
 * @param {object} notification - The notification object {title, body, imageUrl}
 * @param {object} data - Additional data payload
 */
async function sendNotificationToUser(userId, notification, data = {}) {
    try {
        const userDoc = await db.collection("users").doc(userId).get();
        if (!userDoc.exists) {
            console.log(`User ${userId} not found for notification`);
            return { success: false, reason: "user_not_found" };
        }

        const userData = userDoc.data();
        const fcmTokens = userData.fcmTokens || [];

        if (fcmTokens.length === 0) {
            console.log(`No FCM tokens found for user ${userId}`);
            return { success: false, reason: "no_tokens" };
        }

        // Check notification preferences
        const notifPrefs = userData.notificationPreferences || {};
        const type = data.type || "system_announcement";
        
        // Check if user has disabled this type of notification
        if (type === "new_message" && notifPrefs.messages === false) {
            return { success: false, reason: "disabled_by_user" };
        }
        if ((type === "new_match" || type === "mutual_like") && notifPrefs.matches === false) {
            return { success: false, reason: "disabled_by_user" };
        }
        if (type === "promotional" && notifPrefs.promotional === false) {
            return { success: false, reason: "disabled_by_user" };
        }

        // Prepare the message
        const message = {
            notification: {
                title: notification.title,
                body: notification.body,
            },
            data: {
                ...data,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                // Include image URL in data payload for foreground handling
                ...(notification.imageUrl && { imageUrl: notification.imageUrl }),
            },
            android: {
                priority: "high",
                notification: {
                    channelId: type === "new_message" ? "veil_messages" : 
                               (type === "new_match" || type === "mutual_like") ? "veil_matches" : "veil_general",
                    sound: "default",
                    // Image for Android notification tray (MUST be HTTPS)
                    ...(notification.imageUrl && { imageUrl: notification.imageUrl }),
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: "default",
                        badge: 1,
                        // Image for iOS notification
                        ...(notification.imageUrl && { "mutable-content": 1 }),
                    },
                },
                // FCM options for iOS image
                ...(notification.imageUrl && { 
                    fcm_options: { 
                        image: notification.imageUrl 
                    } 
                }),
            },
        };

        // Add image to notification payload (for web and fallback)
        if (notification.imageUrl) {
            message.notification.imageUrl = notification.imageUrl;
        }

        // Send to all tokens
        const tokensToRemove = [];
        const sendPromises = fcmTokens.map(async (token) => {
            try {
                await admin.messaging().send({ ...message, token });
                console.log(`Notification sent to token: ${token.substring(0, 20)}...`);
                return { success: true, token };
            } catch (error) {
                console.error(`Error sending to token ${token.substring(0, 20)}...:`, error.code);
                // Remove invalid tokens
                if (error.code === "messaging/invalid-registration-token" ||
                    error.code === "messaging/registration-token-not-registered") {
                    tokensToRemove.push(token);
                }
                return { success: false, token, error: error.code };
            }
        });

        const results = await Promise.all(sendPromises);

        // Remove invalid tokens
        if (tokensToRemove.length > 0) {
            await db.collection("users").doc(userId).update({
                fcmTokens: admin.firestore.FieldValue.arrayRemove(...tokensToRemove),
            });
            console.log(`Removed ${tokensToRemove.length} invalid tokens for user ${userId}`);
        }

        return { success: true, results };
    } catch (error) {
        console.error(`Error sending notification to user ${userId}:`, error);
        return { success: false, error: error.message };
    }
}

/**
 * Trigger: Send notification when a new message is created
 */
exports.onNewMessage = functions.firestore
    .document("chats/{chatRoomId}/messages/{messageId}")
    .onCreate(async (snapshot, context) => {
        const { chatRoomId, messageId } = context.params;
        const messageData = snapshot.data();

        // Don't send notification for system messages
        if (messageData.senderId === "system") {
            return null;
        }

        const senderId = messageData.senderId;
        const receiverId = messageData.receiverId;

        // Safety check: ensure we have valid sender and receiver
        if (!senderId || !receiverId) {
            console.log(`Missing senderId (${senderId}) or receiverId (${receiverId}) for message ${messageId}`);
            return null;
        }

        // Get chat room to find receiver and unread count
        const chatRoomDoc = await db.collection("chats").doc(chatRoomId).get();
        if (!chatRoomDoc.exists) {
            console.log(`Chat room ${chatRoomId} not found`);
            return null;
        }

        const chatRoom = chatRoomDoc.data();
        
        // Safety check: ensure chat room data is valid
        if (!chatRoom || !chatRoom.user1Id || !chatRoom.user2Id) {
            console.log(`Invalid chat room data for ${chatRoomId}`);
            return null;
        }
        
        const isUser1Sender = chatRoom.user1Id === senderId;
        const receiverName = isUser1Sender ? chatRoom.user2Name : chatRoom.user1Name;
        const senderName = isUser1Sender ? chatRoom.user1Name : chatRoom.user2Name;
        const senderProfilePic = isUser1Sender ? chatRoom.user1ProfilePic : chatRoom.user2ProfilePic;
        const unreadCount = (isUser1Sender ? chatRoom.user2UnreadCount : chatRoom.user1UnreadCount) || 1;

        // Prepare notification content
        let messagePreview = messageData.text || "";
        if (messageData.type === "image") {
            messagePreview = "📷 Sent an image";
        } else if (messageData.type === "voice") {
            messagePreview = "🎤 Sent a voice message";
        } else if (messagePreview.length > 50) {
            messagePreview = messagePreview.substring(0, 47) + "...";
        }

        const notification = {
            title: senderName || "New Message",
            body: unreadCount > 1 
                ? `${unreadCount} new messages: ${messagePreview}`
                : messagePreview,
            imageUrl: senderProfilePic || null,
        };

        const data = {
            type: "new_message",
            chatRoomId: chatRoomId,
            senderId: senderId,
            senderName: senderName || "Someone",
            unreadCount: unreadCount.toString(),
            messageId: messageId,
        };

        return sendNotificationToUser(receiverId, notification, data);
    });

/**
 * Trigger: Send notification when mutual like happens (both users liked each other)
 */
exports.onMutualLike = functions.firestore
    .document("chats/{chatRoomId}")
    .onUpdate(async (change, context) => {
        const { chatRoomId } = context.params;
        const beforeData = change.before.data();
        const afterData = change.after.data();

        // Check if both users just liked each other (transition from stranger to friend eligible)
        const wasMutualBefore = beforeData.user1HasLiked && beforeData.user2HasLiked;
        const isMutualNow = afterData.user1HasLiked && afterData.user2HasLiked;

        if (!wasMutualBefore && isMutualNow) {
            console.log(`Mutual like detected in chat room ${chatRoomId}`);

            // Send notification to both users
            const user1Notification = {
                title: "❤️ New Friend!",
                body: `You and ${afterData.user2Name || "Someone"} are now friends!`,
            };
            const user2Notification = {
                title: "❤️ New Friend!",
                body: `You and ${afterData.user1Name || "Someone"} are now friends!`,
            };

            const data1 = {
                type: "mutual_like",
                chatRoomId: chatRoomId,
                friendId: afterData.user2Id,
                friendName: afterData.user2Name || "Someone",
            };
            const data2 = {
                type: "mutual_like",
                chatRoomId: chatRoomId,
                friendId: afterData.user1Id,
                friendName: afterData.user1Name || "Someone",
            };

            await Promise.all([
                sendNotificationToUser(afterData.user1Id, user1Notification, data1),
                sendNotificationToUser(afterData.user2Id, user2Notification, data2),
            ]);
        }

        return null;
    });

/**
 * Callable: Send promotional notification to all users or specific segments
 * Only callable by admin (add your own admin check)
 */
exports.sendPromotionalNotification = functions.https.onCall(async (data, context) => {
    // TODO: Add admin authentication check here
    // if (!context.auth || !isAdmin(context.auth.uid)) {
    //     throw new functions.https.HttpsError("permission-denied", "Only admins can send promotional notifications");
    // }

    const { title, body, imageUrl, targetTopic, targetUserIds } = data;

    if (!title || !body) {
        throw new functions.https.HttpsError("invalid-argument", "Title and body are required");
    }

    const notification = { title, body, imageUrl };
    const payload = {
        type: "promotional",
        title,
        body,
    };

    // Send to specific users
    if (targetUserIds && Array.isArray(targetUserIds)) {
        const results = await Promise.all(
            targetUserIds.map(uid => sendNotificationToUser(uid, notification, payload))
        );
        return { success: true, sentTo: targetUserIds.length, results };
    }

    // Send to a topic (e.g., "all_users")
    if (targetTopic) {
        try {
            const message = {
                notification: { title, body },
                data: payload,
                topic: targetTopic,
            };
            if (imageUrl) message.notification.imageUrl = imageUrl;

            await admin.messaging().send(message);
            return { success: true, sentTo: targetTopic };
        } catch (error) {
            console.error("Error sending topic notification:", error);
            throw new functions.https.HttpsError("internal", error.message);
        }
    }

    throw new functions.https.HttpsError("invalid-argument", "Provide targetTopic or targetUserIds");
});

/**
 * Scheduled: Check for expiring stranger chats and send warnings
 * Runs every 6 hours
 */
exports.checkExpiringChats = functions.pubsub
    .schedule("every 6 hours")
    .onRun(async (context) => {
        const now = admin.firestore.Timestamp.now();
        const twelveHoursFromNow = admin.firestore.Timestamp.fromDate(
            new Date(now.toDate().getTime() + 12 * 60 * 60 * 1000)
        );

        // Find stranger chats expiring within 12 hours
        const expiringChats = await db.collection("chats")
            .where("roomType", "==", "stranger")
            .where("status", "==", "active")
            .where("expiresAt", "<=", twelveHoursFromNow)
            .where("expiresAt", ">", now)
            .get();

        console.log(`Found ${expiringChats.size} chats expiring soon`);

        const notifications = [];

        for (const doc of expiringChats.docs) {
            const chat = doc.data();
            const hoursRemaining = Math.ceil(
                (chat.expiresAt.toDate().getTime() - now.toDate().getTime()) / (1000 * 60 * 60)
            );

            // Check if we already sent a warning (store in chat doc)
            if (chat.expiryWarningsSent && chat.expiryWarningsSent.includes(hoursRemaining)) {
                continue;
            }

            // Send to user1
            notifications.push(
                sendNotificationToUser(chat.user1Id, {
                    title: "⏰ Chat Expiring Soon",
                    body: `Your chat with ${chat.user2Name || "a stranger"} expires in ${hoursRemaining} hours. Like each other to become friends!`,
                }, {
                    type: "chat_expiring",
                    chatRoomId: doc.id,
                    otherUserName: chat.user2Name || "Stranger",
                    hoursRemaining: hoursRemaining.toString(),
                })
            );

            // Send to user2
            notifications.push(
                sendNotificationToUser(chat.user2Id, {
                    title: "⏰ Chat Expiring Soon",
                    body: `Your chat with ${chat.user1Name || "a stranger"} expires in ${hoursRemaining} hours. Like each other to become friends!`,
                }, {
                    type: "chat_expiring",
                    chatRoomId: doc.id,
                    otherUserName: chat.user1Name || "Stranger",
                    hoursRemaining: hoursRemaining.toString(),
                })
            );

            // Mark warning as sent
            await doc.ref.update({
                expiryWarningsSent: admin.firestore.FieldValue.arrayUnion(hoursRemaining),
            });
        }

        await Promise.all(notifications);
        console.log(`Sent ${notifications.length} expiry warning notifications`);

        return null;
    });

/**
 * Callable: Send notification when match is found
 * This is called from the findGlobalMatch function result
 */
exports.sendMatchNotification = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be logged in");
    }

    const { targetUserId, matchedUserName, matchedUserProfilePic, chatRoomId, compatibilityScore } = data;

    if (!targetUserId || !chatRoomId) {
        throw new functions.https.HttpsError("invalid-argument", "targetUserId and chatRoomId are required");
    }

    const notification = {
        title: "🎭 New Match Found!",
        body: `You've been matched with ${matchedUserName || "someone new"}! Say hello!`,
        imageUrl: matchedUserProfilePic || null,
    };

    const payload = {
        type: "new_match",
        chatRoomId: chatRoomId,
        matchedUserId: context.auth.uid,
        matchedUserName: matchedUserName || "Someone",
        compatibilityScore: compatibilityScore ? compatibilityScore.toString() : "0",
    };

    const result = await sendNotificationToUser(targetUserId, notification, payload);
    return result;
});

/**
 * Callable: Send notification to a specific topic (user segment)
 * Only callable by admin (add your own admin check)
 * 
 * Topics available:
 * - all_users: All app users
 * - premium_users / free_users: Based on subscription
 * - gender_male / gender_female / gender_other: Gender-based
 * - age_18_25 / age_26_35 / age_36_50 / age_over_50: Age groups
 * - verified_users: Verified users only
 * - region_<country>: Country-based (e.g., region_india, region_us)
 */
exports.sendTopicNotification = functions.https.onCall(async (data, context) => {
    // TODO: Add admin authentication check
    // if (!context.auth || !isAdmin(context.auth.uid)) {
    //     throw new functions.https.HttpsError("permission-denied", "Only admins can send topic notifications");
    // }

    const { topic, title, body, imageUrl, customData } = data;

    if (!topic || !title || !body) {
        throw new functions.https.HttpsError("invalid-argument", "topic, title, and body are required");
    }

    // Validate topic format (alphanumeric, underscores, hyphens only)
    const validTopicRegex = /^[a-zA-Z0-9_-]+$/;
    if (!validTopicRegex.test(topic)) {
        throw new functions.https.HttpsError("invalid-argument", "Invalid topic format");
    }

    try {
        const message = {
            notification: {
                title: title,
                body: body,
            },
            data: {
                type: "promotional",
                topic: topic,
                ...(customData || {}),
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "veil_general",
                    sound: "default",
                    ...(imageUrl && { imageUrl: imageUrl }),
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: "default",
                        badge: 1,
                    },
                },
                ...(imageUrl && { 
                    fcm_options: { 
                        image: imageUrl 
                    } 
                }),
            },
            topic: topic,  // Send to this topic
        };

        const response = await admin.messaging().send(message);
        console.log(`Successfully sent topic notification to ${topic}:`, response);
        
        return { 
            success: true, 
            topic: topic,
            messageId: response,
        };
    } catch (error) {
        console.error(`Error sending topic notification to ${topic}:`, error);
        throw new functions.https.HttpsError("internal", error.message);
    }
});

/**
 * Callable: Send notification to multiple topics at once
 * Useful for complex targeting (e.g., premium AND verified users)
 */
exports.sendMultiTopicNotification = functions.https.onCall(async (data, context) => {
    // TODO: Add admin authentication check

    const { condition, title, body, imageUrl, customData } = data;

    // Condition example: "'premium_users' in topics && 'verified_users' in topics"
    // This targets users who are BOTH premium AND verified

    if (!condition || !title || !body) {
        throw new functions.https.HttpsError("invalid-argument", "condition, title, and body are required");
    }

    try {
        const message = {
            notification: {
                title: title,
                body: body,
            },
            data: {
                type: "promotional",
                ...(customData || {}),
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "veil_general",
                    sound: "default",
                    ...(imageUrl && { imageUrl: imageUrl }),
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: "default",
                        badge: 1,
                    },
                },
            },
            condition: condition,  // Topic condition
        };

        const response = await admin.messaging().send(message);
        console.log(`Successfully sent multi-topic notification:`, response);
        
        return { 
            success: true, 
            condition: condition,
            messageId: response,
        };
    } catch (error) {
        console.error(`Error sending multi-topic notification:`, error);
        throw new functions.https.HttpsError("internal", error.message);
    }
});

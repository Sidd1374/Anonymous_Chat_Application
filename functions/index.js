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

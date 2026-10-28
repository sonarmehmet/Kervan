import {onDocumentUpdated} from "firebase-functions/v2/firestore";

import "../common";
import {notifyWaitlist} from "../waitlist/waitlist";

/** Katılımcı sayısı azalırsa veya kapasite artarsa bekleme listesini bilgilendirir. */
export const onEventUpdated = onDocumentUpdated(
  "events/{eventId}",
  async (event) => {
    const before = event.data?.before;
    const after = event.data?.after;
    if (!before || !after) return;

    const freed =
      Number(after.get("acceptedCount")) < Number(before.get("acceptedCount")) ||
      Number(after.get("capacity")) > Number(before.get("capacity"));
    if (!freed) return;

    await notifyWaitlist(event.params.eventId);
  }
);

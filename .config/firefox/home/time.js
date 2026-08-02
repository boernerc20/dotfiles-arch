// 12-hour clock for the start page.
//
// The previous version did `hrs = (hrs > 12) ? hrs - 12 : hrs`, which is right
// for every hour except midnight: getHours() returns 0 there, 0 is not > 12, so
// it rendered "00:14 AM" instead of "12:14 AM". `h % 12 || 12` maps both 0 and
// 12 to 12 and leaves everything else alone.
function realtimeClock() {
  const now = new Date();
  const h24 = now.getHours();
  const hrs = String(h24 % 12 || 12).padStart(2, "0");
  const mins = String(now.getMinutes()).padStart(2, "0");
  const amPm = h24 < 12 ? "AM" : "PM";

  const el = document.getElementById("clock");
  if (el) el.textContent = `${hrs}:${mins} ${amPm}`;

  // Re-run just after the next minute boundary instead of polling twice a
  // second. The old 500ms setTimeout rewrote the DOM 120 times a minute to
  // change a value that moves once, and drifted because it never aligned to
  // the boundary.
  const msToNextMinute = 60000 - (now.getSeconds() * 1000 + now.getMilliseconds());
  setTimeout(realtimeClock, msToNextMinute + 50);
}

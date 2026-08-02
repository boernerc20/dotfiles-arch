// 12-hour clock for the start page.
//
// Emits the colon and the meridiem as separate elements so CSS can dim them and
// let the eye land on the digits. That is the whole typographic idea of the
// hero, so it has to be structural rather than a single text node.
//
// The version before this did `hrs = (hrs > 12) ? hrs - 12 : hrs`, correct for
// every hour except midnight: getHours() returns 0 there, 0 is not > 12, so it
// rendered "00:14 AM". `h % 12 || 12` maps both 0 and 12 to 12.
function realtimeClock() {
  const now = new Date();
  const h24 = now.getHours();
  const hrs = String(h24 % 12 || 12).padStart(2, "0");
  const mins = String(now.getMinutes()).padStart(2, "0");
  const amPm = h24 < 12 ? "am" : "pm";

  const el = document.getElementById("clock");
  if (el) {
    el.innerHTML = "";
    const part = (text, cls) => {
      const s = document.createElement("span");
      if (cls) s.className = cls;
      s.textContent = text;
      return s;
    };
    el.append(part(hrs), part(":", "tick"), part(mins), part(amPm, "meridiem"));
  }

  // Re-run just after the next minute boundary instead of polling twice a
  // second. The old 500ms setTimeout rewrote the DOM 120 times a minute to
  // change a value that moves once, and drifted because it never aligned.
  const msToNextMinute = 60000 - (now.getSeconds() * 1000 + now.getMilliseconds());
  setTimeout(realtimeClock, msToNextMinute + 50);
}

// Clones a <template> into phone frames with a theme and direction.
function renderFrames(list) {
  const host = document.getElementById('frames');
  for (const f of list) {
    const wrap = document.createElement('div');
    wrap.className = 'frame-wrap';
    const label = document.createElement('div');
    label.className = 'frame-label';
    label.textContent = f.label;
    const phone = document.createElement('div');
    phone.className = 'phone';
    phone.dataset.theme = f.theme;
    if (f.rtl) { phone.dir = 'rtl'; phone.lang = 'ur'; }
    // Taller frames show the full scroll height for review.
    if (f.height) phone.style.height = f.height + 'px';
    phone.appendChild(document.getElementById(f.tpl).content.cloneNode(true));
    wrap.append(label, phone);
    host.appendChild(wrap);
  }
}

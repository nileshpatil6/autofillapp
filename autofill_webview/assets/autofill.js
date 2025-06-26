(function(data) {
  Object.keys(data).forEach(key => {
    const selector = `[name="${key}"], #${key}, [placeholder="${key}"]`;
    const el = document.querySelector(selector);
    if (!el) return;
    switch (el.tagName.toLowerCase()) {
      case 'input':
        el.value = data[key]; break;
      case 'textarea':
        el.value = data[key]; break;
      case 'select':
        el.value = data[key];
        el.dispatchEvent(new Event('change', { bubbles: true }));
        break;
    }
    el.dispatchEvent(new Event('input', { bubbles: true }));
  });
  if (data.__autoSubmit) {
    const btn = document.querySelector('[type=submit]');
    if (btn) btn.click();
  }
})(%MAPPING%);

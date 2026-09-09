window.MIKIS_COMMERCE_READY = false;
window.MIKIS_STORE_CONFIG = null;

fetch("/data/store-config.json", {
  cache: "no-store"
})
.then(r => r.json())
.then(config => {

  window.MIKIS_STORE_CONFIG = config;
  window.MIKIS_COMMERCE_READY =
    config.commerce_ready === true;

  if (!window.MIKIS_COMMERCE_READY) {

    const banner =
      document.createElement("div");

    banner.id = "legal-prelaunch-banner";

    banner.style.cssText =
      "position:sticky;top:0;z-index:99999;" +
      "background:#2b153b;color:white;" +
      "padding:12px;text-align:center;" +
      "font-family:Arial,sans-serif";

    banner.textContent =
      "Catalogusmodus: verkoop is tijdelijk geblokkeerd " +
      "tot bedrijfs- en productcompliance volledig is geverifieerd.";

    document.body.prepend(banner);

  }

})
.catch(() => {
  window.MIKIS_COMMERCE_READY = false;
});

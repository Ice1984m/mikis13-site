"use strict";

const products = [
  {
    id: 1,
    name: "Console reinigingsset",
    category: "repair",
    categoryLabel: "Reparatie",
    icon: "🧹",
    description: "Zachte borstels en hulpmiddelen voor veilig extern onderhoud.",
    price: 14.95,
    badge: "Populair"
  },
  {
    id: 2,
    name: "Precisieschroevendraaierset",
    category: "repair",
    categoryLabel: "Reparatie",
    icon: "🪛",
    description: "Compacte bitset voor consoles, controllers, laptops en kleine elektronica.",
    price: 24.95,
    badge: "Pro keuze"
  },
  {
    id: 3,
    name: "Controllerhouder",
    category: "gaming",
    categoryLabel: "Gaming",
    icon: "🎮",
    description: "Stevige bureauhouder voor PlayStation-, Xbox- en andere controllers.",
    price: 16.95,
    badge: "Nieuw"
  },
  {
    id: 4,
    name: "Gaming headsetstandaard",
    category: "gaming",
    categoryLabel: "Gaming",
    icon: "🎧",
    description: "Houd je headset netjes, veilig en direct bereikbaar op je bureau.",
    price: 19.95,
    badge: ""
  },
  {
    id: 5,
    name: "Verstelbare laptopstandaard",
    category: "pc",
    categoryLabel: "PC",
    icon: "💻",
    description: "Ergonomische standaard voor betere houding en luchtcirculatie.",
    price: 27.95,
    badge: "Aanrader"
  },
  {
    id: 6,
    name: "USB-C hub",
    category: "pc",
    categoryLabel: "PC",
    icon: "🔌",
    description: "Meer aansluitingen voor laptop, tablet en moderne Android-apparaten.",
    price: 29.95,
    badge: ""
  },
  {
    id: 7,
    name: "Webcamcover – 3 stuks",
    category: "security",
    categoryLabel: "Privacy",
    icon: "🛡️",
    description: "Eenvoudige fysieke privacybescherming voor laptop en tablet.",
    price: 4.95,
    badge: "Budget"
  },
  {
    id: 8,
    name: "RFID-beschermhoes",
    category: "security",
    categoryLabel: "Privacy",
    icon: "💳",
    description: "Bescherm compatibele kaarten tegen ongewenst draadloos uitlezen.",
    price: 7.95,
    badge: ""
  },
  {
    id: 9,
    name: "Veilige Android-checklist",
    category: "digital",
    categoryLabel: "Digitaal",
    icon: "📱",
    description: "Praktische Nederlandstalige checklist voor privacy, updates en back-ups.",
    price: 4.99,
    badge: "Direct"
  },
  {
    id: 10,
    name: "Console-onderhoudsgids",
    category: "digital",
    categoryLabel: "Digitaal",
    icon: "📘",
    description: "Stapsgewijze gids voor veilig onderhoud van consoles en controllers.",
    price: 6.99,
    badge: "Direct"
  }
];

let activeCategory = "all";
let searchTerm = "";
let cart = JSON.parse(localStorage.getItem("mikis13-cart") || "[]");

const productGrid = document.getElementById("productGrid");
const cartCount = document.getElementById("cartCount");
const cartItems = document.getElementById("cartItems");
const cartTotal = document.getElementById("cartTotal");
const cartDrawer = document.getElementById("cartDrawer");
const overlay = document.getElementById("overlay");
const toast = document.getElementById("toast");

const formatPrice = value =>
  new Intl.NumberFormat("nl-BE", {
    style: "currency",
    currency: "EUR"
  }).format(value);

function renderProducts() {
  const filtered = products.filter(product => {
    const categoryMatches =
      activeCategory === "all" || product.category === activeCategory;

    const text = `${product.name} ${product.description} ${product.categoryLabel}`
      .toLowerCase();

    return categoryMatches && text.includes(searchTerm);
  });

  if (!filtered.length) {
    productGrid.innerHTML =
      '<div class="empty-state">Geen producten gevonden. Probeer een andere zoekterm.</div>';
    return;
  }

  productGrid.innerHTML = filtered.map(product => `
    <article class="product-card">
      <div class="product-visual">
        ${product.badge ? `<span class="product-badge">${product.badge}</span>` : ""}
        <span>${product.icon}</span>
      </div>

      <div class="product-content">
        <span class="product-category">${product.categoryLabel}</span>
        <h3>${product.name}</h3>
        <p>${product.description}</p>

        <div class="product-footer">
          <span class="product-price">${formatPrice(product.price)}</span>
          <button class="add-button" data-product-id="${product.id}" type="button">
            Toevoegen
          </button>
        </div>
      </div>
    </article>
  `).join("");

  document.querySelectorAll(".add-button").forEach(button => {
    button.addEventListener("click", () => {
      addToCart(Number(button.dataset.productId));
    });
  });
}

function addToCart(productId) {
  const existing = cart.find(item => item.id === productId);

  if (existing) {
    existing.quantity += 1;
  } else {
    cart.push({ id: productId, quantity: 1 });
  }

  saveCart();
  showToast("Product toegevoegd aan je winkelwagen.");
}

function removeFromCart(productId) {
  cart = cart.filter(item => item.id !== productId);
  saveCart();
}

function saveCart() {
  localStorage.setItem("mikis13-cart", JSON.stringify(cart));
  renderCart();
}

function renderCart() {
  const itemCount = cart.reduce((sum, item) => sum + item.quantity, 0);
  cartCount.textContent = itemCount;

  if (!cart.length) {
    cartItems.innerHTML =
      '<div class="empty-state">Je winkelwagen is nog leeg.</div>';
    cartTotal.textContent = formatPrice(0);
    return;
  }

  let total = 0;

  cartItems.innerHTML = cart.map(item => {
    const product = products.find(product => product.id === item.id);
    const subtotal = product.price * item.quantity;
    total += subtotal;

    return `
      <div class="cart-item">
        <div class="cart-item-icon">${product.icon}</div>
        <div>
          <strong>${product.name}</strong>
          <small>${item.quantity} × ${formatPrice(product.price)}</small>
        </div>
        <button class="remove-button"
                data-remove-id="${product.id}"
                type="button">
          Verwijder
        </button>
      </div>
    `;
  }).join("");

  cartTotal.textContent = formatPrice(total);

  document.querySelectorAll(".remove-button").forEach(button => {
    button.addEventListener("click", () => {
      removeFromCart(Number(button.dataset.removeId));
    });
  });
}

function openCart() {
  cartDrawer.classList.add("open");
  overlay.classList.add("show");
  cartDrawer.setAttribute("aria-hidden", "false");
}

function closeCart() {
  cartDrawer.classList.remove("open");
  overlay.classList.remove("show");
  cartDrawer.setAttribute("aria-hidden", "true");
}

function showToast(message) {
  toast.textContent = message;
  toast.classList.add("show");

  window.setTimeout(() => {
    toast.classList.remove("show");
  }, 2500);
}

document.querySelectorAll(".category").forEach(button => {
  button.addEventListener("click", () => {
    document.querySelectorAll(".category").forEach(item => {
      item.classList.remove("active");
    });

    button.classList.add("active");
    activeCategory = button.dataset.category;
    renderProducts();
  });
});

document.getElementById("searchInput").addEventListener("input", event => {
  searchTerm = event.target.value.trim().toLowerCase();
  renderProducts();
});

document.getElementById("cartButton").addEventListener("click", openCart);
document.getElementById("closeCart").addEventListener("click", closeCart);
overlay.addEventListener("click", closeCart);

document.getElementById("checkoutButton").addEventListener("click", () => {
  if (!cart.length) {
    showToast("Voeg eerst een product toe.");
    return;
  }

  showToast("De betaalfunctie staat nog veilig in demomodus.");
});

document.getElementById("newsletterForm").addEventListener("submit", event => {
  event.preventDefault();

  const email = document.getElementById("newsletterEmail").value.trim();
  const message = document.getElementById("newsletterMessage");

  message.textContent =
    `Bedankt! ${email} is lokaal geregistreerd als demo-inschrijving.`;

  event.target.reset();
});

renderProducts();
renderCart();

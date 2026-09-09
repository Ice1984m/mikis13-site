"use strict";

const products = window.MIKIS_PRODUCTS || [];

let cart = JSON.parse(
  localStorage.getItem("mikis13-cart") || "[]"
);

const money = cents =>
  new Intl.NumberFormat("nl-BE",{
    style:"currency",
    currency:"EUR"
  }).format(cents / 100);

function save(){
  localStorage.setItem(
    "mikis13-cart",
    JSON.stringify(cart)
  );
}

function optionButtons(values,type,id){
  if(!values || !values.length) return "";

  return `
    <div class="option-group">
      <strong>${type === "size" ? "Maat" : "Kleur"}</strong>
      <div class="option-row">
        ${values.map((v,i)=>`
          <label class="option-pill">
            <input
              type="radio"
              name="${type}-${id}"
              value="${v}"
              ${i===0 ? "checked" : ""}
            >
            <span>${v}</span>
          </label>
        `).join("")}
      </div>
    </div>
  `;
}

function renderProducts(){
  document.querySelector("#products").innerHTML =
    products.map(p => `
      <article class="product">
        <div class="product-image-wrap">
          <img
            src="${p.image}"
            alt="${p.name}"
            class="product-image"
            loading="lazy"
            onerror="this.closest('.product-image-wrap').classList.add('missing-image')"
          >
        </div>

        <div class="product-body">
          <h3>${p.name}</h3>
          <div class="price">${money(p.price)}</div>

          ${optionButtons(p.colors,"color",p.id)}
          ${optionButtons(p.sizes,"size",p.id)}

          <button data-add="${p.id}">
            Toevoegen aan winkelmand
          </button>
        </div>
      </article>
    `).join("");
}

function renderCart(){
  const box = document.querySelector("#cart");

  if(!cart.length){
    box.innerHTML = "<p>Winkelmand is leeg.</p>";
  } else {
    box.innerHTML = cart.map(item => {
      const p = products.find(x => x.id === item.id);
      if(!p) return "";

      return `
        <div class="cart-item">
          <div>
            <strong>${p.name}</strong><br>
            <small>
              ${item.color ? "Kleur: " + item.color : ""}
              ${item.size ? " • Maat: " + item.size : ""}
            </small>
          </div>

          <div class="cart-controls">
            <button data-minus="${item.key}">−</button>
            <span>${item.qty}</span>
            <button data-plus="${item.key}">+</button>
            <button data-remove="${item.key}">×</button>
          </div>

          <strong>${money(p.price * item.qty)}</strong>
        </div>
      `;
    }).join("");
  }

  const total = cart.reduce((sum,item)=>{
    const p = products.find(x => x.id === item.id);
    return p ? sum + p.price * item.qty : sum;
  },0);

  document.querySelector("#total").textContent = money(total);

  document.querySelector("#cart-count").textContent =
    cart.reduce((s,x)=>s+x.qty,0);
}

function getVariant(id){
  const product = products.find(p=>p.id===id);
  if(!product) return {};

  const colorInput =
    document.querySelector(`input[name="color-${id}"]:checked`);

  const sizeInput =
    document.querySelector(`input[name="size-${id}"]:checked`);

  return {
    color: colorInput?.value || "",
    size: sizeInput?.value || ""
  };
}

document.addEventListener("click",e=>{

  const addId = e.target.dataset.add;

  if(addId){
    const variant = getVariant(addId);

    const key = [
      addId,
      variant.color,
      variant.size
    ].join("|");

    const existing = cart.find(x=>x.key===key);

    if(existing){
      existing.qty++;
    }else{
      cart.push({
        key,
        id:addId,
        qty:1,
        ...variant
      });
    }

    save();
    renderCart();
    return;
  }

  const plus = e.target.dataset.plus;
  if(plus){
    const item = cart.find(x=>x.key===plus);
    if(item) item.qty++;
    save();
    renderCart();
    return;
  }

  const minus = e.target.dataset.minus;
  if(minus){
    const item = cart.find(x=>x.key===minus);
    if(item){
      item.qty--;
      if(item.qty <= 0){
        cart = cart.filter(x=>x.key!==minus);
      }
    }
    save();
    renderCart();
    return;
  }

  const remove = e.target.dataset.remove;
  if(remove){
    cart = cart.filter(x=>x.key!==remove);
    save();
    renderCart();
  }
});

document.querySelector("#checkout").addEventListener("click",async()=>{

  const message = document.querySelector("#message");

  if(!cart.length){
    message.textContent = "Je winkelmand is leeg.";
    return;
  }

  message.textContent =
    "Checkout is voorbereid maar echte betaling staat nog veilig uit.";

  /*
  Later Stripe activeren:

  const response = await fetch("/api/checkout/create",{
    method:"POST",
    headers:{"Content-Type":"application/json"},
    body:JSON.stringify({items:cart})
  });

  const data = await response.json();

  if(data.url){
    location.href = data.url;
  }
  */
});

renderProducts();
renderCart();

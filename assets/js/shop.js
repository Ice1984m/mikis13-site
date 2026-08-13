"use strict";

const products = [
  {
    id:"repair",
    name:"Repair Diagnose",
    price:1500
  },
  {
    id:"website",
    name:"Website Controle",
    price:2500
  },
  {
    id:"termux",
    name:"Termux Setup",
    price:3500
  }
];

let cart = JSON.parse(
  localStorage.getItem("mikis13-cart") || "[]"
);

const money = cents =>
  new Intl.NumberFormat("nl-BE",{
    style:"currency",
    currency:"EUR"
  }).format(cents/100);

function save(){
  localStorage.setItem(
    "mikis13-cart",
    JSON.stringify(cart)
  );
}

function renderProducts(){
  document.querySelector("#products").innerHTML =
    products.map(p => `
      <article class="product">
        <h2>${p.name}</h2>
        <div class="price">${money(p.price)}</div>
        <button data-add="${p.id}">
          Toevoegen
        </button>
      </article>
    `).join("");
}

function renderCart(){
  const box = document.querySelector("#cart");

  if(!cart.length){
    box.innerHTML = "<p>Winkelmand is leeg.</p>";
  }else{
    box.innerHTML = cart.map(item => {
      const p = products.find(x => x.id === item.id);

      return `
        <div class="cart-item">
          <span>${p.name} × ${item.qty}</span>
          <span>${money(p.price * item.qty)}</span>
        </div>
      `;
    }).join("");
  }

  const total = cart.reduce((sum,item)=>{
    const p = products.find(x => x.id === item.id);
    return sum + p.price * item.qty;
  },0);

  document.querySelector("#total").textContent =
    money(total);
}

document.addEventListener("click",e=>{
  const id = e.target.dataset.add;

  if(!id) return;

  const existing = cart.find(x => x.id === id);

  if(existing){
    existing.qty++;
  }else{
    cart.push({id,qty:1});
  }

  save();
  renderCart();
});

document.querySelector("#checkout")
.addEventListener("click",async()=>{

  const message =
    document.querySelector("#message");

  if(!cart.length){
    message.textContent =
      "Winkelmand is leeg.";
    return;
  }

  try{
    const response = await fetch(
      "/api/checkout/create",
      {
        method:"POST",
        headers:{
          "Content-Type":"application/json"
        },
        body:JSON.stringify({
          items:cart.map(x=>({
            id:x.id,
            quantity:x.qty
          }))
        })
      }
    );

    const data = await response.json();

    if(data.url){
      location.href = data.url;
    }else{
      message.textContent =
        data.error || "Checkout nog niet ingesteld.";
    }

  }catch(error){
    message.textContent =
      "Serverfout: " + error.message;
  }
});

renderProducts();
renderCart();

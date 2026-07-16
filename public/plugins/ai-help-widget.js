(function(){
  const endpoint = document.currentScript?.dataset?.endpoint || "/api/ai-chat";
  const b=document.createElement("button"); b.className="aiw-launcher"; b.textContent="Abraham AI";
  const s=document.createElement("div"); s.className="aiw-shell";
  s.innerHTML='<input id="q" placeholder="Typ vraag"/><button id="send">Send</button><div id="out"></div>';
  document.body.append(b,s);
  b.onclick=()=>s.classList.toggle("aiw-open");
  s.querySelector("#send").onclick=async()=>{
    const q=s.querySelector("#q").value.trim();
    if(!q) return;
    const r=await fetch(endpoint,{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({message:q})});
    const d=await r.json();
    s.querySelector("#out").textContent=d.reply||d.error||"Geen antwoord";
  };
})();

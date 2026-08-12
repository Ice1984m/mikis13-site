document.documentElement.classList.add("js");

const year = document.querySelector("[data-year]");

if (year) {
  year.textContent = new Date().getFullYear();
}

document.querySelectorAll('a[href^="#"]').forEach(link => {
  link.addEventListener("click", event => {
    const target = document.querySelector(link.getAttribute("href"));

    if (target) {
      event.preventDefault();
      target.scrollIntoView({
        behavior: "smooth",
        block: "start"
      });
    }
  });
});

console.log("Mikis13 Neon System actief");

const menuBtn = document.getElementById("menuBtn");
const navLinks = document.getElementById("navLinks");
const navItems = document.querySelectorAll(".nav-links a");
const filterButtons = document.querySelectorAll(".filter-btn");
const skillCards = document.querySelectorAll(".skill-card");
const viewSections = document.querySelectorAll(".view-section");
const viewLinks = document.querySelectorAll("[data-view]");

menuBtn.addEventListener("click", () => {
  navLinks.classList.toggle("active");
});

function setActiveNav(targetId) {
  navItems.forEach((link) => {
    link.classList.toggle("active", link.getAttribute("href") === `#${targetId}`);
  });
}

function showMain(targetId) {
  document.body.classList.remove("single-view");
  viewSections.forEach((section) => section.classList.remove("active-view"));
  setActiveNav(targetId);

  const target = document.getElementById(targetId);
  if (target) {
    target.scrollIntoView({ behavior: "smooth", block: "start" });
  }
}

function showOnlySection(targetId) {
  document.body.classList.add("single-view");

  viewSections.forEach((section) => {
    section.classList.toggle("active-view", section.id === targetId);
  });

  setActiveNav(targetId);
  window.scrollTo({ top: 0, behavior: "smooth" });

  if (targetId === "skills") {
    filterButtons.forEach((btn) => btn.classList.remove("active"));
    const allBtn = document.querySelector('.filter-btn[data-filter="all"]');
    if (allBtn) allBtn.classList.add("active");
    skillCards.forEach((card) => card.classList.remove("hide"));
  }
}

viewLinks.forEach((link) => {
  link.addEventListener("click", (event) => {
    const targetId = link.getAttribute("href").replace("#", "");
    const viewType = link.getAttribute("data-view");

    event.preventDefault();
    navLinks.classList.remove("active");

    if (viewType === "main") {
      showMain(targetId);
    } else {
      showOnlySection(targetId);
    }
  });
});

filterButtons.forEach((button) => {
  button.addEventListener("click", () => {
    const filterValue = button.getAttribute("data-filter");

    filterButtons.forEach((btn) => btn.classList.remove("active"));
    button.classList.add("active");

    skillCards.forEach((card) => {
      const cardCategory = card.getAttribute("data-category");

      if (filterValue === "all" || filterValue === cardCategory) {
        card.classList.remove("hide");
      } else {
        card.classList.add("hide");
      }
    });
  });
});

window.addEventListener("scroll", () => {
  if (document.body.classList.contains("single-view")) return;

  const sections = document.querySelectorAll(".main-section[id]");
  const scrollPosition = window.scrollY + 130;

  sections.forEach((section) => {
    const sectionTop = section.offsetTop;
    const sectionHeight = section.offsetHeight;
    const sectionId = section.getAttribute("id");

    if (scrollPosition >= sectionTop && scrollPosition < sectionTop + sectionHeight) {
      setActiveNav(sectionId);
    }
  });
});

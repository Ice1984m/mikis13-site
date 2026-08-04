(() => {
    "use strict";

    const STORAGE_KEY = "mikis13VisualEditorSettingsV1";
    const EDITABLE_SELECTOR = [
        "button",
        "a",
        "h1",
        "h2",
        "h3",
        "h4",
        "h5",
        "h6",
        "p",
        "span",
        "label",
        "li",
        "section",
        "article",
        ".card",
        ".button",
        "img"
    ].join(",");

    let editorActive = false;
    let selectedElement = null;
    let settings = loadSettings();

    function loadSettings() {
        try {
            return JSON.parse(localStorage.getItem(STORAGE_KEY) || "{}");
        } catch {
            return {};
        }
    }

    function saveSettings() {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(settings));
    }

    function elementId(element) {
        if (!element.dataset.m13EditorId) {
            element.dataset.m13EditorId =
                "m13-" + Math.random().toString(36).slice(2, 11);
        }

        return element.dataset.m13EditorId;
    }

    function markEditableElements() {
        document.querySelectorAll(EDITABLE_SELECTOR).forEach((element) => {
            if (
                element.closest("#m13-editor-panel") ||
                element.id === "m13-editor-toggle" ||
                element.id === "m13-editor-status"
            ) {
                return;
            }

            element.dataset.m13Editable = "true";
            elementId(element);
        });
    }

    function applyOne(element, config) {
        if (!element || !config) {
            return;
        }

        if (
            typeof config.text === "string" &&
            element.tagName !== "IMG"
        ) {
            element.textContent = config.text;
        }

        if (
            typeof config.href === "string" &&
            element.tagName === "A"
        ) {
            element.setAttribute("href", config.href || "#");
        }

        if (
            typeof config.src === "string" &&
            element.tagName === "IMG"
        ) {
            element.setAttribute("src", config.src);
        }

        if (typeof config.alt === "string" && element.tagName === "IMG") {
            element.setAttribute("alt", config.alt);
        }

        if (typeof config.className === "string") {
            const editorId = element.dataset.m13EditorId;
            const editable = element.dataset.m13Editable;

            element.className = config.className;

            element.dataset.m13EditorId = editorId;
            element.dataset.m13Editable = editable;
        }

        const style = config.style || {};

        Object.entries(style).forEach(([property, value]) => {
            if (value === null || value === undefined || value === "") {
                element.style.removeProperty(property);
            } else {
                element.style.setProperty(property, value);
            }
        });

        if (config.hidden === true) {
            element.style.setProperty("display", "none");
        }
    }

    function applyAllSettings() {
        Object.entries(settings).forEach(([id, config]) => {
            const element = document.querySelector(
                `[data-m13-editor-id="${CSS.escape(id)}"]`
            );

            applyOne(element, config);
        });
    }

    function createEditorInterface() {
        const toggle = document.createElement("button");
        toggle.id = "m13-editor-toggle";
        toggle.type = "button";
        toggle.textContent = "⚙️ Bewerken";
        toggle.setAttribute("aria-label", "Visuele beheermodus openen");

        const status = document.createElement("div");
        status.id = "m13-editor-status";
        status.textContent =
            "Beheermodus actief — klik op tekst, een knop, afbeelding of kaart.";

        const panel = document.createElement("aside");
        panel.id = "m13-editor-panel";

        panel.innerHTML = `
            <button
                type="button"
                class="m13-editor-close"
                id="m13-editor-close"
                aria-label="Editor sluiten"
            >✕</button>

            <h2>Mikis13 instellingen</h2>
            <p id="m13-editor-description">
                Selecteer eerst een onderdeel op de pagina.
            </p>

            <div id="m13-editor-form" hidden>
                <h3>Inhoud</h3>

                <div class="m13-editor-field">
                    <label for="m13-text">Tekst</label>
                    <textarea id="m13-text"></textarea>
                </div>

                <div class="m13-editor-field" id="m13-link-field">
                    <label for="m13-href">Knop- of paginalink</label>
                    <input id="m13-href" type="text">
                </div>

                <div class="m13-editor-field" id="m13-image-field">
                    <label for="m13-src">Afbeeldingsadres</label>
                    <input id="m13-src" type="text">

                    <label for="m13-alt">Beschrijving afbeelding</label>
                    <input id="m13-alt" type="text">
                </div>

                <h3>Vormgeving</h3>

                <div class="m13-editor-grid">
                    <div class="m13-editor-field">
                        <label for="m13-color">Tekstkleur</label>
                        <input id="m13-color" type="color">
                    </div>

                    <div class="m13-editor-field">
                        <label for="m13-background">Achtergrond</label>
                        <input id="m13-background" type="color">
                    </div>
                </div>

                <div class="m13-editor-grid">
                    <div class="m13-editor-field">
                        <label for="m13-font-size">Lettergrootte</label>
                        <input
                            id="m13-font-size"
                            type="text"
                            placeholder="bijvoorbeeld 18px"
                        >
                    </div>

                    <div class="m13-editor-field">
                        <label for="m13-font-weight">Tekstdikte</label>
                        <select id="m13-font-weight">
                            <option value="">Standaard</option>
                            <option value="400">Normaal</option>
                            <option value="600">Halfvet</option>
                            <option value="700">Vet</option>
                            <option value="900">Extra vet</option>
                        </select>
                    </div>
                </div>

                <div class="m13-editor-grid">
                    <div class="m13-editor-field">
                        <label for="m13-width">Breedte</label>
                        <input
                            id="m13-width"
                            type="text"
                            placeholder="100%, 300px of auto"
                        >
                    </div>

                    <div class="m13-editor-field">
                        <label for="m13-height">Hoogte</label>
                        <input
                            id="m13-height"
                            type="text"
                            placeholder="auto of 200px"
                        >
                    </div>
                </div>

                <div class="m13-editor-grid">
                    <div class="m13-editor-field">
                        <label for="m13-padding">Binnenruimte</label>
                        <input
                            id="m13-padding"
                            type="text"
                            placeholder="bijvoorbeeld 16px"
                        >
                    </div>

                    <div class="m13-editor-field">
                        <label for="m13-radius">Afgeronde hoeken</label>
                        <input
                            id="m13-radius"
                            type="text"
                            placeholder="bijvoorbeeld 14px"
                        >
                    </div>
                </div>

                <div class="m13-editor-field">
                    <label for="m13-align">Uitlijning</label>
                    <select id="m13-align">
                        <option value="">Standaard</option>
                        <option value="left">Links</option>
                        <option value="center">Midden</option>
                        <option value="right">Rechts</option>
                    </select>
                </div>

                <div class="m13-editor-field">
                    <label for="m13-class">CSS-klassen</label>
                    <input id="m13-class" type="text">
                </div>

                <div class="m13-editor-field">
                    <label for="m13-custom-css">
                        Eigen CSS, één eigenschap per regel
                    </label>
                    <textarea
                        id="m13-custom-css"
                        placeholder="border: 2px solid #38bdf8;&#10;box-shadow: 0 10px 30px rgba(0,0,0,.4);"
                    ></textarea>
                </div>

                <div class="m13-editor-field">
                    <label>
                        <input id="m13-hidden" type="checkbox">
                        Onderdeel verbergen
                    </label>
                </div>

                <div class="m13-editor-actions">
                    <button
                        type="button"
                        class="m13-editor-action primary"
                        id="m13-save"
                    >Opslaan</button>

                    <button
                        type="button"
                        class="m13-editor-action warning"
                        id="m13-reset-element"
                    >Onderdeel herstellen</button>
                </div>
            </div>

            <h3>Volledige pagina</h3>

            <div class="m13-editor-actions">
                <button
                    type="button"
                    class="m13-editor-action"
                    id="m13-export"
                >Instellingen exporteren</button>

                <button
                    type="button"
                    class="m13-editor-action"
                    id="m13-import"
                >Instellingen importeren</button>

                <button
                    type="button"
                    class="m13-editor-action danger"
                    id="m13-reset-all"
                >Alles herstellen</button>
            </div>

            <input
                type="file"
                id="m13-import-file"
                accept="application/json"
                hidden
            >
        `;

        document.body.append(toggle, status, panel);

        toggle.addEventListener("click", toggleEditor);

        panel
            .querySelector("#m13-editor-close")
            .addEventListener("click", closePanel);

        panel
            .querySelector("#m13-save")
            .addEventListener("click", saveSelectedElement);

        panel
            .querySelector("#m13-reset-element")
            .addEventListener("click", resetSelectedElement);

        panel
            .querySelector("#m13-export")
            .addEventListener("click", exportSettings);

        panel
            .querySelector("#m13-import")
            .addEventListener("click", () => {
                panel.querySelector("#m13-import-file").click();
            });

        panel
            .querySelector("#m13-import-file")
            .addEventListener("change", importSettings);

        panel
            .querySelector("#m13-reset-all")
            .addEventListener("click", resetAllSettings);

        document.addEventListener("click", selectEditableElement, true);
    }

    function toggleEditor() {
        editorActive = !editorActive;

        document.documentElement.classList.toggle(
            "m13-editor-active",
            editorActive
        );

        const toggle = document.querySelector("#m13-editor-toggle");

        toggle.classList.toggle("active", editorActive);
        toggle.textContent = editorActive
            ? "✕ Stop bewerken"
            : "⚙️ Bewerken";

        if (!editorActive) {
            clearSelection();
            closePanel();
        }
    }

    function selectEditableElement(event) {
        if (!editorActive) {
            return;
        }

        const element = event.target.closest(
            '[data-m13-editable="true"]'
        );

        if (!element) {
            return;
        }

        if (
            element.closest("#m13-editor-panel") ||
            element.id === "m13-editor-toggle"
        ) {
            return;
        }

        event.preventDefault();
        event.stopPropagation();
        event.stopImmediatePropagation();

        clearSelection();

        selectedElement = element;
        selectedElement.classList.add("m13-editor-selected");

        openElementSettings(element);
    }

    function openElementSettings(element) {
        const panel = document.querySelector("#m13-editor-panel");
        const form = panel.querySelector("#m13-editor-form");
        const id = elementId(element);
        const current = settings[id] || {};
        const computed = getComputedStyle(element);

        panel.classList.add("open");
        form.hidden = false;

        panel.querySelector("#m13-editor-description").textContent =
            `${element.tagName.toLowerCase()} geselecteerd — ${id}`;

        panel.querySelector("#m13-text").value =
            element.tagName === "IMG"
                ? ""
                : current.text ?? element.textContent.trim();

        panel.querySelector("#m13-href").value =
            current.href ??
            (element.tagName === "A"
                ? element.getAttribute("href") || ""
                : "");

        panel.querySelector("#m13-src").value =
            current.src ??
            (element.tagName === "IMG"
                ? element.getAttribute("src") || ""
                : "");

        panel.querySelector("#m13-alt").value =
            current.alt ??
            (element.tagName === "IMG"
                ? element.getAttribute("alt") || ""
                : "");

        panel.querySelector("#m13-link-field").hidden =
            element.tagName !== "A";

        panel.querySelector("#m13-image-field").hidden =
            element.tagName !== "IMG";

        panel.querySelector("#m13-color").value =
            rgbToHex(computed.color) || "#ffffff";

        panel.querySelector("#m13-background").value =
            rgbToHex(computed.backgroundColor) || "#0f172a";

        panel.querySelector("#m13-font-size").value =
            current.style?.["font-size"] || computed.fontSize || "";

        panel.querySelector("#m13-font-weight").value =
            current.style?.["font-weight"] || "";

        panel.querySelector("#m13-width").value =
            current.style?.width || "";

        panel.querySelector("#m13-height").value =
            current.style?.height || "";

        panel.querySelector("#m13-padding").value =
            current.style?.padding || "";

        panel.querySelector("#m13-radius").value =
            current.style?.["border-radius"] || "";

        panel.querySelector("#m13-align").value =
            current.style?.["text-align"] || "";

        panel.querySelector("#m13-class").value =
            current.className ?? element.className;

        panel.querySelector("#m13-custom-css").value =
            current.customCss || "";

        panel.querySelector("#m13-hidden").checked =
            current.hidden === true;
    }

    function saveSelectedElement() {
        if (!selectedElement) {
            return;
        }

        const panel = document.querySelector("#m13-editor-panel");
        const id = elementId(selectedElement);
        const customCss = panel
            .querySelector("#m13-custom-css")
            .value.trim();

        const style = {
            color: panel.querySelector("#m13-color").value,
            "background-color":
                panel.querySelector("#m13-background").value,
            "font-size":
                panel.querySelector("#m13-font-size").value.trim(),
            "font-weight":
                panel.querySelector("#m13-font-weight").value,
            width: panel.querySelector("#m13-width").value.trim(),
            height: panel.querySelector("#m13-height").value.trim(),
            padding: panel.querySelector("#m13-padding").value.trim(),
            "border-radius":
                panel.querySelector("#m13-radius").value.trim(),
            "text-align":
                panel.querySelector("#m13-align").value
        };

        Object.assign(style, parseCustomCss(customCss));

        const config = {
            text:
                selectedElement.tagName === "IMG"
                    ? undefined
                    : panel.querySelector("#m13-text").value,
            href:
                selectedElement.tagName === "A"
                    ? panel.querySelector("#m13-href").value.trim()
                    : undefined,
            src:
                selectedElement.tagName === "IMG"
                    ? panel.querySelector("#m13-src").value.trim()
                    : undefined,
            alt:
                selectedElement.tagName === "IMG"
                    ? panel.querySelector("#m13-alt").value.trim()
                    : undefined,
            className: panel.querySelector("#m13-class").value.trim(),
            customCss,
            hidden: panel.querySelector("#m13-hidden").checked,
            style
        };

        settings[id] = config;
        saveSettings();
        applyOne(selectedElement, config);

        alert("Instellingen opgeslagen op dit apparaat.");
    }

    function resetSelectedElement() {
        if (!selectedElement) {
            return;
        }

        const id = elementId(selectedElement);

        if (!confirm("Dit onderdeel herstellen?")) {
            return;
        }

        delete settings[id];
        saveSettings();

        alert(
            "Instelling verwijderd. Herlaad de pagina om de originele vorm te tonen."
        );

        window.location.reload();
    }

    function resetAllSettings() {
        if (
            !confirm(
                "Alle visuele instellingen van deze pagina verwijderen?"
            )
        ) {
            return;
        }

        localStorage.removeItem(STORAGE_KEY);
        window.location.reload();
    }

    function exportSettings() {
        const blob = new Blob(
            [JSON.stringify(settings, null, 2)],
            { type: "application/json" }
        );

        const url = URL.createObjectURL(blob);
        const anchor = document.createElement("a");

        anchor.href = url;
        anchor.download = "mikis13-instellingen.json";
        anchor.click();

        URL.revokeObjectURL(url);
    }

    async function importSettings(event) {
        const file = event.target.files?.[0];

        if (!file) {
            return;
        }

        try {
            const imported = JSON.parse(await file.text());

            if (
                !imported ||
                typeof imported !== "object" ||
                Array.isArray(imported)
            ) {
                throw new Error("Ongeldig instellingenbestand");
            }

            settings = imported;
            saveSettings();
            window.location.reload();
        } catch (error) {
            alert("Importeren mislukt: " + error.message);
        }
    }

    function parseCustomCss(text) {
        const result = {};

        text.split(";").forEach((line) => {
            const separator = line.indexOf(":");

            if (separator < 1) {
                return;
            }

            const property = line
                .slice(0, separator)
                .trim()
                .toLowerCase();

            const value = line.slice(separator + 1).trim();

            if (property && value) {
                result[property] = value;
            }
        });

        return result;
    }

    function rgbToHex(value) {
        if (!value || value === "transparent") {
            return null;
        }

        if (value.startsWith("#")) {
            return value.slice(0, 7);
        }

        const match = value.match(/\d+/g);

        if (!match || match.length < 3) {
            return null;
        }

        return (
            "#" +
            match
                .slice(0, 3)
                .map((number) =>
                    Number(number).toString(16).padStart(2, "0")
                )
                .join("")
        );
    }

    function clearSelection() {
        document
            .querySelectorAll(".m13-editor-selected")
            .forEach((element) => {
                element.classList.remove("m13-editor-selected");
            });

        selectedElement = null;
    }

    function closePanel() {
        document
            .querySelector("#m13-editor-panel")
            ?.classList.remove("open");
    }

    function initialise() {
        markEditableElements();
        applyAllSettings();
        createEditorInterface();

        const observer = new MutationObserver(() => {
            markEditableElements();
            applyAllSettings();
        });

        observer.observe(document.body, {
            childList: true,
            subtree: true
        });
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", initialise);
    } else {
        initialise();
    }
})();

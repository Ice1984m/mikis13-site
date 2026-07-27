"use strict";

const http = require("http");
const fs = require("fs");
const path = require("path");

const host = "0.0.0.0";
const port = Number(process.env.PORT || 10000);
const root = path.resolve(__dirname);

const mimeTypes = {
    ".html": "text/html; charset=utf-8",
    ".css": "text/css; charset=utf-8",
    ".js": "application/javascript; charset=utf-8",
    ".json": "application/json; charset=utf-8",
    ".png": "image/png",
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".gif": "image/gif",
    ".svg": "image/svg+xml",
    ".ico": "image/x-icon",
    ".webp": "image/webp",
    ".mp3": "audio/mpeg",
    ".mp4": "video/mp4",
    ".woff": "font/woff",
    ".woff2": "font/woff2",
    ".txt": "text/plain; charset=utf-8"
};

function sendFile(filePath, response) {
    fs.stat(filePath, (statError, stats) => {
        if (statError || !stats.isFile()) {
            const fallback = path.join(root, "index.html");

            fs.readFile(fallback, (fallbackError, data) => {
                if (fallbackError) {
                    response.writeHead(404, {
                        "Content-Type": "text/plain; charset=utf-8"
                    });

                    response.end("Pagina niet gevonden.");
                    return;
                }

                response.writeHead(200, {
                    "Content-Type": "text/html; charset=utf-8",
                    "X-Content-Type-Options": "nosniff",
                    "Referrer-Policy":
                        "strict-origin-when-cross-origin"
                });

                response.end(data);
            });

            return;
        }

        const extension = path.extname(filePath).toLowerCase();
        const contentType =
            mimeTypes[extension] ||
            "application/octet-stream";

        response.writeHead(200, {
            "Content-Type": contentType,
            "X-Content-Type-Options": "nosniff",
            "Referrer-Policy":
                "strict-origin-when-cross-origin"
        });

        fs.createReadStream(filePath).pipe(response);
    });
}

const server = http.createServer((request, response) => {
    let requestPath;

    try {
        requestPath = decodeURIComponent(
            new URL(
                request.url,
                `http://${request.headers.host || "localhost"}`
            ).pathname
        );
    } catch {
        response.writeHead(400, {
            "Content-Type": "text/plain; charset=utf-8"
        });

        response.end("Ongeldige aanvraag.");
        return;
    }

    if (requestPath === "/health") {
        response.writeHead(200, {
            "Content-Type": "application/json; charset=utf-8"
        });

        response.end(
            JSON.stringify({
                status: "ok",
                service: "mikis13-site"
            })
        );

        return;
    }

    if (requestPath === "/") {
        requestPath = "/index.html";
    }

    const requestedFile = path.resolve(
        root,
        `.${requestPath}`
    );

    if (
        requestedFile !== root &&
        !requestedFile.startsWith(`${root}${path.sep}`)
    ) {
        response.writeHead(403, {
            "Content-Type": "text/plain; charset=utf-8"
        });

        response.end("Verboden.");
        return;
    }

    sendFile(requestedFile, response);
});

server.listen(port, host, () => {
    console.log(
        `Mikis13 luistert op http://${host}:${port}`
    );
});

server.on("error", error => {
    console.error("Serverfout:", error);
    process.exit(1);
});

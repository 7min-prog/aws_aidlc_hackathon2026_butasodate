import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { randomUUID } from "crypto";
import { readFileSync } from "fs";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";

// Load .env from project root
const __dirname = dirname(fileURLToPath(import.meta.url));
try {
  const envPath = resolve(__dirname, "..", ".env");
  const envContent = readFileSync(envPath, "utf-8");
  for (const line of envContent.split("\n")) {
    const match = line.match(/^([^#=]+)=(.*)$/);
    if (match && !process.env[match[1].trim()]) {
      process.env[match[1].trim()] = match[2].trim();
    }
  }
} catch {}

const API_URL = process.env.PENPOT_API_URL || "https://design.penpot.app/api";
const TOKEN = process.env.PENPOT_ACCESS_TOKEN;

async function penpotPost(method, params = {}) {
  const res = await fetch(`${API_URL}/rpc/command/${method}`, {
    method: "POST",
    headers: { "Authorization": `Token ${TOKEN}`, "Content-Type": "application/transit+json", "Accept": "application/transit+json" },
    body: transitEncode(params),
  });
  if (!res.ok) throw new Error(`Penpot API error: ${res.status} ${await res.text()}`);
  const text = await res.text();
  try { return JSON.parse(text); } catch { return text; }
}

async function penpotGet(method, params = {}) {
  const query = Object.entries(params).map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`).join("&");
  const url = `${API_URL}/rpc/command/${method}${query ? "?" + query : ""}`;
  const res = await fetch(url, { headers: { "Authorization": `Token ${TOKEN}`, "Accept": "application/json" } });
  if (!res.ok) throw new Error(`Penpot API error: ${res.status} ${await res.text()}`);
  return res.json();
}

async function penpotPostJson(method, params = {}) {
  const res = await fetch(`${API_URL}/rpc/command/${method}`, {
    method: "POST",
    headers: { "Authorization": `Token ${TOKEN}`, "Content-Type": "application/json", "Accept": "application/json" },
    body: JSON.stringify(params),
  });
  if (!res.ok) throw new Error(`Penpot API error: ${res.status} ${await res.text()}`);
  const text = await res.text();
  try { return JSON.parse(text); } catch { return text; }
}

// Transit encoding for Penpot (simplified - converts camelCase to kebab-case keys)
function transitEncode(obj) {
  return JSON.stringify(camelToKebab(obj));
}

function camelToKebab(obj) {
  if (Array.isArray(obj)) return obj.map(camelToKebab);
  if (obj && typeof obj === "object") {
    const result = {};
    for (const [k, v] of Object.entries(obj)) {
      const key = k.replace(/([A-Z])/g, "-$1").toLowerCase().replace(/^-/, "");
      result[key] = camelToKebab(v);
    }
    return result;
  }
  return obj;
}

const server = new McpServer({ name: "penpot", version: "1.0.0" });

// --- Read tools ---
server.tool("get_profile", "Get current user profile", {}, async () => {
  const data = await penpotGet("get-profile");
  return { content: [{ type: "text", text: JSON.stringify(data, null, 2) }] };
});

server.tool("list_projects", "List all projects with their IDs", {}, async () => {
  const data = await penpotGet("get-all-projects");
  const summary = data.map(p => ({ id: p.id, name: p.name, teamName: p.teamName }));
  return { content: [{ type: "text", text: JSON.stringify(summary, null, 2) }] };
});

server.tool("get_project_files", "Get files in a project", { projectId: z.string() }, async ({ projectId }) => {
  const data = await penpotGet("get-project-files", { "project-id": projectId });
  const summary = data.map(f => ({ id: f.id, name: f.name, revn: f.revn, vern: f.vern }));
  return { content: [{ type: "text", text: JSON.stringify(summary, null, 2) }] };
});

server.tool("get_file_summary", "Get file pages and components", { fileId: z.string() }, async ({ fileId }) => {
  const data = await penpotGet("get-file", { id: fileId, components_v2: "true" });
  const pages = Object.values(data.data?.pagesIndex || {}).map(p => ({ id: p.id, name: p.name, shapeCount: Object.keys(p.objects || {}).length }));
  const components = Object.values(data.data?.components || {}).map(c => ({ id: c.id, name: c.name }));
  return { content: [{ type: "text", text: JSON.stringify({ pages, components }, null, 2) }] };
});

server.tool("get_page_shapes", "Get all shapes on a page", {
  fileId: z.string(),
  pageId: z.string(),
}, async ({ fileId, pageId }) => {
  const data = await penpotGet("get-file", { id: fileId, components_v2: "true" });
  const page = data.data?.pagesIndex?.[pageId];
  if (!page) throw new Error("Page not found");
  const shapes = Object.values(page.objects || {}).map(s => ({
    id: s.id, name: s.name, type: s.type, x: s.x, y: s.y, width: s.width, height: s.height, parentId: s.parentId, frameId: s.frameId
  }));
  return { content: [{ type: "text", text: JSON.stringify(shapes, null, 2) }] };
});

// --- Write tools ---
server.tool("create_page", "Create a new page in a file", {
  fileId: z.string(),
  name: z.string(),
}, async ({ fileId, name }) => {
  const file = await penpotGet("get-file", { id: fileId, components_v2: "true" });
  const pageId = randomUUID();
  const result = await penpotPostJson("update-file", {
    id: fileId,
    "session-id": randomUUID(),
    revn: file.revn,
    vern: file.vern || 0,
    changes: [{ type: "add-page", id: pageId, name }],
  });
  return { content: [{ type: "text", text: JSON.stringify({ success: true, pageId }, null, 2) }] };
});

server.tool("create_frame", "Create a frame (board/artboard) on a page", {
  fileId: z.string(),
  pageId: z.string(),
  name: z.string(),
  x: z.number(),
  y: z.number(),
  width: z.number(),
  height: z.number(),
  fillColor: z.string().optional(),
}, async ({ fileId, pageId, name, x, y, width, height, fillColor }) => {
  const file = await penpotGet("get-file", { id: fileId, components_v2: "true" });
  const frameId = randomUUID();
  const rootId = Object.values(file.data.pagesIndex[pageId].objects).find(s => s.type === "frame" && s.parentId === s.id)?.id || pageId;
  
  const obj = {
    id: frameId, name, type: "frame",
    x, y, width, height,
    "x1": x, "y1": y, "x2": x + width, "y2": y + height,
    "parent-id": rootId, "frame-id": rootId,
    selrect: { x, y, width, height, x1: x, y1: y, x2: x + width, y2: y + height },
    points: [{ x, y }, { x: x + width, y }, { x: x + width, y: y + height }, { x, y: y + height }],
    transform: { a: 1, b: 0, c: 0, d: 1, e: 0, f: 0 },
    "transform-inverse": { a: 1, b: 0, c: 0, d: 1, e: 0, f: 0 },
    fills: [{ "fill-color": fillColor || "#FFFFFF", "fill-opacity": 1 }],
    shapes: [],
  };

  const result = await penpotPostJson("update-file", {
    id: fileId,
    "session-id": randomUUID(),
    revn: file.revn,
    vern: file.vern || 0,
    changes: [
      { type: "add-obj", id: frameId, "page-id": pageId, "frame-id": rootId, "parent-id": rootId, obj },
      { type: "reg-objects", "page-id": pageId, shapes: [frameId] },
    ],
  });
  return { content: [{ type: "text", text: JSON.stringify({ success: true, frameId }, null, 2) }] };
});

server.tool("create_rect", "Create a rectangle shape", {
  fileId: z.string(),
  pageId: z.string(),
  frameId: z.string(),
  name: z.string(),
  x: z.number(),
  y: z.number(),
  width: z.number(),
  height: z.number(),
  fillColor: z.string().optional(),
  fillOpacity: z.number().optional(),
  r1: z.number().optional(),
  r2: z.number().optional(),
  r3: z.number().optional(),
  r4: z.number().optional(),
}, async ({ fileId, pageId, frameId, name, x, y, width, height, fillColor, fillOpacity, r1, r2, r3, r4 }) => {
  const file = await penpotGet("get-file", { id: fileId, components_v2: "true" });
  const shapeId = randomUUID();
  const obj = {
    id: shapeId, name, type: "rect",
    x, y, width, height,
    "x1": x, "y1": y, "x2": x + width, "y2": y + height,
    "parent-id": frameId, "frame-id": frameId,
    selrect: { x, y, width, height, x1: x, y1: y, x2: x + width, y2: y + height },
    points: [{ x, y }, { x: x + width, y }, { x: x + width, y: y + height }, { x, y: y + height }],
    transform: { a: 1, b: 0, c: 0, d: 1, e: 0, f: 0 },
    "transform-inverse": { a: 1, b: 0, c: 0, d: 1, e: 0, f: 0 },
    fills: [{ "fill-color": fillColor || "#D9D9D9", "fill-opacity": fillOpacity ?? 1 }],
    ...(r1 != null && { r1, r2: r2 ?? r1, r3: r3 ?? r1, r4: r4 ?? r1 }),
  };

  await penpotPostJson("update-file", {
    id: fileId, "session-id": randomUUID(), revn: file.revn, vern: file.vern || 0,
    changes: [
      { type: "add-obj", id: shapeId, "page-id": pageId, "frame-id": frameId, "parent-id": frameId, obj },
      { type: "reg-objects", "page-id": pageId, shapes: [shapeId] },
    ],
  });
  return { content: [{ type: "text", text: JSON.stringify({ success: true, shapeId }, null, 2) }] };
});

server.tool("create_text", "Create a text element", {
  fileId: z.string(),
  pageId: z.string(),
  frameId: z.string(),
  name: z.string(),
  x: z.number(),
  y: z.number(),
  width: z.number(),
  height: z.number(),
  text: z.string(),
  fontSize: z.string().optional(),
  fontWeight: z.string().optional(),
  fillColor: z.string().optional(),
  fontFamily: z.string().optional(),
}, async ({ fileId, pageId, frameId, name, x, y, width, height, text, fontSize, fontWeight, fillColor, fontFamily }) => {
  const file = await penpotGet("get-file", { id: fileId, components_v2: "true" });
  const shapeId = randomUUID();
  const fSize = fontSize || "16";
  const fWeight = fontWeight || "400";
  const fColor = fillColor || "#000000";
  const fFamily = fontFamily || "Inter";

  const content = {
    type: "root",
    children: [{
      type: "paragraph-set",
      children: [{
        type: "paragraph",
        children: [{
          text,
          fills: [{ "fill-color": fColor, "fill-opacity": 1 }],
          "font-family": fFamily,
          "font-size": fSize,
          "font-weight": fWeight,
          "font-style": "normal",
        }],
      }],
    }],
  };

  const obj = {
    id: shapeId, name, type: "text",
    x, y, width, height,
    "parent-id": frameId, "frame-id": frameId,
    selrect: { x, y, width, height, x1: x, y1: y, x2: x + width, y2: y + height },
    points: [{ x, y }, { x: x + width, y }, { x: x + width, y: y + height }, { x, y: y + height }],
    transform: { a: 1, b: 0, c: 0, d: 1, e: 0, f: 0 },
    "transform-inverse": { a: 1, b: 0, c: 0, d: 1, e: 0, f: 0 },
    content,
    "grow-type": "auto-height",
  };

  await penpotPostJson("update-file", {
    id: fileId, "session-id": randomUUID(), revn: file.revn, vern: file.vern || 0,
    changes: [
      { type: "add-obj", id: shapeId, "page-id": pageId, "frame-id": frameId, "parent-id": frameId, obj },
      { type: "reg-objects", "page-id": pageId, shapes: [shapeId] },
    ],
  });
  return { content: [{ type: "text", text: JSON.stringify({ success: true, shapeId }, null, 2) }] };
});

server.tool("create_circle", "Create a circle/ellipse shape", {
  fileId: z.string(),
  pageId: z.string(),
  frameId: z.string(),
  name: z.string(),
  x: z.number(),
  y: z.number(),
  width: z.number(),
  height: z.number(),
  fillColor: z.string().optional(),
}, async ({ fileId, pageId, frameId, name, x, y, width, height, fillColor }) => {
  const file = await penpotGet("get-file", { id: fileId, components_v2: "true" });
  const shapeId = randomUUID();
  const obj = {
    id: shapeId, name, type: "circle",
    x, y, width, height,
    "parent-id": frameId, "frame-id": frameId,
    selrect: { x, y, width, height, x1: x, y1: y, x2: x + width, y2: y + height },
    points: [{ x, y }, { x: x + width, y }, { x: x + width, y: y + height }, { x, y: y + height }],
    transform: { a: 1, b: 0, c: 0, d: 1, e: 0, f: 0 },
    "transform-inverse": { a: 1, b: 0, c: 0, d: 1, e: 0, f: 0 },
    fills: [{ "fill-color": fillColor || "#D9D9D9", "fill-opacity": 1 }],
  };

  await penpotPostJson("update-file", {
    id: fileId, "session-id": randomUUID(), revn: file.revn, vern: file.vern || 0,
    changes: [
      { type: "add-obj", id: shapeId, "page-id": pageId, "frame-id": frameId, "parent-id": frameId, obj },
      { type: "reg-objects", "page-id": pageId, shapes: [shapeId] },
    ],
  });
  return { content: [{ type: "text", text: JSON.stringify({ success: true, shapeId }, null, 2) }] };
});

server.tool("delete_shape", "Delete a shape from a page", {
  fileId: z.string(),
  pageId: z.string(),
  shapeId: z.string(),
}, async ({ fileId, pageId, shapeId }) => {
  const file = await penpotGet("get-file", { id: fileId, components_v2: "true" });
  await penpotPostJson("update-file", {
    id: fileId, "session-id": randomUUID(), revn: file.revn, vern: file.vern || 0,
    changes: [{ type: "del-obj", id: shapeId, "page-id": pageId }],
  });
  return { content: [{ type: "text", text: JSON.stringify({ success: true }, null, 2) }] };
});

const transport = new StdioServerTransport();
await server.connect(transport);

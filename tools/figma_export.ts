// Bun-скрипт: экспортирует ноды из Figma через WebSocket-сервер Talk To Figma
// и сохраняет PNG-байты в указанную папку.
//
// Запуск:  bun run tools/figma_export.ts
// Каналы/нода-айди — внизу в массиве `EXPORTS`.

import { mkdirSync, writeFileSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { randomUUID } from "node:crypto";

const WS_URL = "ws://localhost:3055";
const CHANNEL = "97hdzd61";
const OUT_DIR = "mobile/assets/images";

type ExportItem = {
  nodeId: string;
  out: string;        // имя файла внутри OUT_DIR
  scale?: number;
  format?: "PNG" | "SVG" | "JPG";
};

const EXPORTS: ExportItem[] = [
  // ===== 3D иллюстрации =====
  { nodeId: "3:198", out: "hero_logo_3d.png", scale: 3 },
  { nodeId: "3:218", out: "mic_3d.png", scale: 3 },
  { nodeId: "3:219", out: "camera_3d.png", scale: 3 },
  { nodeId: "66:156", out: "youtube_logo.png", scale: 3 },
  { nodeId: "10:5643", out: "mp3_doc_3d.png", scale: 3 },
  { nodeId: "3:1910", out: "music_note_3d.png", scale: 3 },

  // ===== Плоские UI-иконки (из Main Page) =====
  // Settings gear (header) — material-symbols:settings-rounded 24x24
  { nodeId: "3:247", out: "icons/ic_settings.png", scale: 4 },
  // Gallery icon в белом боксе 48x48 (внутри Gallery card)
  { nodeId: "3:273", out: "icons/ic_gallery.png", scale: 4 },
  // Files icon в белом боксе 48x48 (внутри Files card)
  { nodeId: "3:284", out: "icons/ic_files.png", scale: 4 },
  // Chevron-back (визуально это chevron-right, ориентация задаётся Figma) 20x20
  { nodeId: "3:270", out: "icons/ic_chevron_right.png", scale: 4 },
  // Clipboard в URL поле
  { nodeId: "3:302", out: "icons/ic_clipboard.png", scale: 4 },
  // Link icon
  { nodeId: "3:297", out: "icons/ic_link.png", scale: 4 },
  // More dots (history card)
  { nodeId: "3:320", out: "icons/ic_more.png", scale: 4 },

  // ===== Иконки из Result/Crop =====
  // Close (X)
  { nodeId: "3:1716", out: "icons/ic_close.png", scale: 4 },
  // Delete
  { nodeId: "3:1721", out: "icons/ic_delete.png", scale: 4 },
  // Pause
  { nodeId: "40:189", out: "icons/ic_pause.png", scale: 4 },
  // Arrow right (MP3 → WAV)
  { nodeId: "40:155", out: "icons/ic_arrow_right.png", scale: 4 },
];

type WsMessage = {
  type?: string;
  message?: any;
  channel?: string;
  id?: string;
};

function send(ws: WebSocket, payload: object) {
  ws.send(JSON.stringify(payload));
}

function exportOne(ws: WebSocket, item: ExportItem): Promise<Uint8Array> {
  return new Promise((resolve, reject) => {
    const id = randomUUID();
    const timeout = setTimeout(() => {
      ws.removeEventListener("message", handler as any);
      reject(new Error(`Timeout exporting ${item.nodeId}`));
    }, 60_000);

    const handler = (ev: MessageEvent) => {
      let data: WsMessage;
      try {
        data = JSON.parse(ev.data as string);
      } catch {
        return;
      }
      // Сообщения от других клиентов идут как {type:"broadcast", message: <inner>}
      // Inner has id, command, result
      const inner =
        data.message && typeof data.message === "object" ? data.message : null;
      if (!inner) return;
      if (inner.id !== id) return;

      // Successful response from Figma plugin
      ws.removeEventListener("message", handler as any);
      clearTimeout(timeout);
      const result = inner.result ?? inner;

      const imageData =
        result?.imageData ??
        result?.bytes ??
        (typeof result === "string" ? result : null);

      if (!imageData) {
        reject(
          new Error(
            `No image data in response for ${item.nodeId}. Got: ${JSON.stringify(result).slice(0, 300)}`,
          ),
        );
        return;
      }
      try {
        const bytes = Uint8Array.from(Buffer.from(imageData as string, "base64"));
        resolve(bytes);
      } catch (e) {
        reject(e as Error);
      }
    };
    ws.addEventListener("message", handler as any);

    send(ws, {
      id,
      type: "message",
      channel: CHANNEL,
      message: {
        id,
        command: "export_node_as_image",
        params: {
          nodeId: item.nodeId,
          format: item.format ?? "PNG",
          scale: item.scale ?? 2,
          commandId: id,
        },
      },
    });
  });
}

async function main() {
  console.log(`Connecting to ${WS_URL} ...`);
  const ws = new WebSocket(WS_URL);

  await new Promise<void>((res, rej) => {
    ws.addEventListener("open", () => res(), { once: true });
    ws.addEventListener("error", (e: Event) => rej(e), { once: true });
  });
  console.log("Connected. Joining channel...");

  await new Promise<void>((res) => {
    const onMsg = (ev: MessageEvent) => {
      let data: any;
      try { data = JSON.parse(ev.data as string); } catch { return; }
      if (data?.message?.result?.toString().includes("Connected to channel") ||
          (data?.type === "system" && data?.channel === CHANNEL)) {
        ws.removeEventListener("message", onMsg as any);
        res();
      }
    };
    ws.addEventListener("message", onMsg as any);
    send(ws, { type: "join", channel: CHANNEL, id: randomUUID() });
    setTimeout(() => res(), 1500);
  });
  console.log(`Joined channel ${CHANNEL}.`);

  if (!existsSync(OUT_DIR)) {
    mkdirSync(OUT_DIR, { recursive: true });
  }

  for (const item of EXPORTS) {
    process.stdout.write(`→ ${item.out} (${item.nodeId}) ... `);
    try {
      const bytes = await exportOne(ws, item);
      const fullPath = join(OUT_DIR, item.out);
      mkdirSync(dirname(fullPath), { recursive: true });
      writeFileSync(fullPath, bytes);
      console.log(`OK  ${(bytes.byteLength / 1024).toFixed(1)} KB`);
    } catch (e) {
      console.log(`FAIL  ${(e as Error).message}`);
    }
  }

  ws.close();
  console.log("Done.");
}

main().catch((e) => {
  console.error("Fatal:", e);
  process.exit(1);
});

#!/usr/bin/env node
/** Send a UTF-8 text file to the currently authorized WeChat user via iLink Bot API. */
import { readFile } from 'node:fs/promises';
import { randomBytes, randomUUID } from 'node:crypto';

const [textFile] = process.argv.slice(2);
if (!textFile) throw new Error('Usage: send-wechat-text.mjs <text-file>');

const home = process.env.HOME;
const credentials = JSON.parse(await readFile(`${home}/.pi/agent/wechat-assistant/credentials.json`, 'utf8'));
const contextState = JSON.parse(await readFile(`${home}/.pi/agent/wechat-assistant/context-tokens.json`, 'utf8'));
const userId = credentials.userId || contextState.lastUserId;
const contextToken = contextState.tokens?.[userId];
const text = (await readFile(textFile, 'utf8')).trim();
if (!userId || !contextToken) throw new Error('No WeChat recipient or context token is available');
if (!text) throw new Error('Refusing to send an empty message');

const uin = Buffer.from(String(randomBytes(4).readUInt32BE(0)), 'utf8').toString('base64');
const response = await fetch(`${credentials.baseUrl.replace(/\/+$/, '')}/ilink/bot/sendmessage`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    AuthorizationType: 'ilink_bot_token',
    Authorization: `Bearer ${credentials.token}`,
    'X-WECHAT-UIN': uin,
  },
  body: JSON.stringify({
    msg: {
      from_user_id: '', to_user_id: userId, client_id: randomUUID(),
      message_type: 2, message_state: 2, context_token: contextToken,
      item_list: [{ type: 1, text_item: { text } }],
    },
    base_info: { channel_version: '1.0.0' },
  }),
});
const body = await response.text();
let parsed = {};
try { parsed = body ? JSON.parse(body) : {}; } catch { /* retained below */ }
if (!response.ok || (typeof parsed.ret === 'number' && parsed.ret !== 0)) {
  throw new Error(`WeChat API rejected the message (HTTP ${response.status}): ${body}`);
}
console.log(`sent ${text.length} chars to WeChat`);

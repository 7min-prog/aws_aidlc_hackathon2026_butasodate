"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ulid = ulid;
const ENCODING = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
function ulid() {
    const time = Date.now();
    let timeStr = '';
    let t = time;
    for (let i = 0; i < 10; i++) {
        timeStr = ENCODING[t % 32] + timeStr;
        t = Math.floor(t / 32);
    }
    let randomStr = '';
    for (let i = 0; i < 16; i++) {
        randomStr += ENCODING[Math.floor(Math.random() * 32)];
    }
    return timeStr + randomStr;
}

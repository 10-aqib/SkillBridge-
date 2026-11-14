// A small in-memory stand-in for Firestore used by the function tests.
// Not Firebase: it supports just what functions/src uses (documents and
// subcollections, transactions that refuse reads after writes, ==, >,
// array-contains filters, count(), increments and server timestamps).
// Real rules and emulator behaviour are tested in rules-tests/.

const name = (v) => v && v.constructor && v.constructor.name;
const isServerTs = (v) => name(v) === "ServerTimestampTransform";
const isIncrement = (v) => name(v) === "NumericIncrementTransform";
const isPlain = (v) => v && typeof v === "object" && !Array.isArray(v) && v.constructor === Object;

/** A stored timestamp. `ts(1000)` stands for a Firestore Timestamp. */
const ts = (ms) => ({ toMillis: () => ms, _ms: ms });
const millis = (v) => (v && typeof v.toMillis === "function" ? v.toMillis() : v);

function clone(v) {
  if (isServerTs(v)) return { __ts: true };
  if (Array.isArray(v)) return v.map(clone);
  if (isPlain(v)) return Object.fromEntries(Object.entries(v).map(([k, x]) => [k, clone(x)]));
  return v; // primitives and timestamp-like values
}

function fieldOf(doc, path) {
  return path.split(".").reduce((o, p) => (o == null ? undefined : o[p]), doc);
}

function fakeDb(seed = {}) {
  const data = clone(seed);
  let auto = 0;
  let writes = 0;
  const coll = (c) => (data[c] ??= {});

  const apply = (target, patch) => {
    for (const [k, v] of Object.entries(patch)) {
      const parts = k.split(".");
      let o = target;
      for (const p of parts.slice(0, -1)) o = o[p] ??= {};
      const last = parts[parts.length - 1];
      o[last] = isIncrement(v) ? (o[last] ?? 0) + v.operand : clone(v);
    }
  };
  const merge = (target, patch) => {
    for (const [k, v] of Object.entries(patch)) {
      if (isPlain(v) && isPlain(target[k])) merge(target[k], v);
      else if (isIncrement(v)) target[k] = (target[k] ?? 0) + v.operand;
      else target[k] = clone(v);
    }
  };
  const write = {
    set: (c, id, v, opts) => {
      if (opts && opts.merge && coll(c)[id]) merge(coll(c)[id], v);
      else { coll(c)[id] = {}; merge(coll(c)[id], v); }
      writes++;
    },
    update: (c, id, v) => {
      if (!coll(c)[id]) throw Object.assign(new Error(`no doc ${c}/${id}`), { code: "not-found" });
      apply(coll(c)[id], v);
      writes++;
    },
    delete: (c, id) => { delete coll(c)[id]; writes++; },
  };

  const snap = (c, id) => ({
    id, exists: coll(c)[id] !== undefined, data: () => coll(c)[id], get: (f) => fieldOf(coll(c)[id], f), ref: ref(c, id),
  });
  const matches = (doc, [f, op, v]) => {
    const x = fieldOf(doc, f);
    switch (op) {
      case "==": return x === v;
      case ">": return x !== undefined && millis(x) > millis(v);
      case "array-contains": return Array.isArray(x) && x.includes(v);
      default: throw new Error(`fake db: unsupported operator ${op}`);
    }
  };
  const query = (c, filters) => {
    const run = () => {
      const docs = Object.keys(coll(c)).filter((id) => filters.every((f) => matches(coll(c)[id], f))).map((id) => snap(c, id));
      return { docs, empty: docs.length === 0, size: docs.length };
    };
    return {
      _q: true, run,
      where: (f, op, v) => query(c, [...filters, [f, op, v]]),
      get: async () => run(),
      count: () => ({ get: async () => ({ data: () => ({ count: run().size }) }) }),
    };
  };
  const ref = (c, id) => ({
    id, path: `${c}/${id}`, _c: c,
    collection: (sub) => collection(`${c}/${id}/${sub}`),
    get: async () => snap(c, id),
    set: async (v, opts) => write.set(c, id, v, opts),
    update: async (v) => write.update(c, id, v),
    delete: async () => write.delete(c, id),
  });
  const collection = (c) => ({
    doc: (id) => ref(c, id ?? `auto${++auto}`),
    where: (f, op, v) => query(c, [[f, op, v]]),
    get: async () => query(c, []).run(),
  });

  return {
    data,
    get writes() { return writes; },
    collection,
    runTransaction: async (fn) => {
      const pending = [];
      const tx = {
        get: async (r) => {
          if (pending.length > 0) throw new Error("read after write");
          return r._q ? r.run() : snap(r._c, r.id);
        },
        set: (r, v, opts) => { pending.push(() => write.set(r._c, r.id, v, opts)); },
        update: (r, v) => { pending.push(() => write.update(r._c, r.id, v)); },
        delete: (r) => { pending.push(() => write.delete(r._c, r.id)); },
      };
      const out = await fn(tx);
      for (const p of pending) p();
      return out;
    },
  };
}

async function rejects(assert, p, code) {
  await assert.rejects(p, (e) => e.code === code || String(e.code).includes(code));
}

module.exports = { fakeDb, ts, millis, rejects };

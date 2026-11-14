// Proposal count integrity and the "job filled" clean-up. Runs against an
// in-memory stand-in for Firestore that supports exactly the calls used.
const test = require("node:test");
const assert = require("node:assert/strict");
const {
  COUNTED_STATUSES,
  isCounted,
  jobsToRecount,
  recountJobProposals,
  jobJustFilled,
  closePendingProposals,
} = require("../.test-build/proposals.js");

function fakeDb({ jobs = {}, proposals = {} } = {}) {
  const data = { jobs: { ...jobs }, proposals: { ...proposals } };
  const writes = [];
  const docRef = (col, id) => ({
    id,
    path: `${col}/${id}`,
    get: async () => snap(col, id),
  });
  const snap = (col, id) => ({
    exists: data[col][id] !== undefined,
    get: (f) => data[col][id]?.[f],
    data: () => data[col][id],
    ref: docRef(col, id),
  });
  const query = (col, filters) => ({
    where: (f, op, v) => query(col, [...filters, [f, op, v]]),
    _docs: () =>
      Object.keys(data[col]).filter((id) =>
        filters.every(([f, op, v]) => (op === "in" ? v.includes(data[col][id][f]) : data[col][id][f] === v)),
      ),
    count: () => ({ get: async () => ({ data: () => ({ count: query(col, filters)._docs().length }) }) }),
    get: async () => {
      const ids = query(col, filters)._docs();
      return { empty: ids.length === 0, size: ids.length, docs: ids.map((id) => snap(col, id)) };
    },
  });
  return {
    data,
    writes,
    collection: (col) => ({ doc: (id) => docRef(col, id), where: (f, op, v) => query(col, [[f, op, v]]) }),
    runTransaction: async (fn) =>
      fn({
        get: async (ref) => snap(...ref.path.split("/")),
        update: (ref, patch) => {
          const [col, id] = ref.path.split("/");
          writes.push([ref.path, patch]);
          Object.assign(data[col][id], patch);
        },
      }),
    batch: () => {
      const pending = [];
      return {
        update: (ref, patch) => pending.push([ref, patch]),
        commit: async () => {
          for (const [ref, patch] of pending) {
            const [col, id] = ref.path.split("/");
            writes.push([ref.path, patch]);
            Object.assign(data[col][id], patch);
          }
        },
      };
    },
  };
}

test("withdrawn proposals are not counted", () => {
  assert.deepEqual(COUNTED_STATUSES, ["pending", "accepted", "rejected"]);
  assert.equal(isCounted("pending"), true);
  assert.equal(isCounted("withdrawn"), false);
  assert.equal(isCounted(undefined), false);
});

test("only count-relevant changes trigger a recount", () => {
  assert.deepEqual(jobsToRecount(undefined, { jobId: "j1", status: "pending" }), ["j1"], "new proposal");
  assert.deepEqual(jobsToRecount({ jobId: "j1", status: "pending" }, { jobId: "j1", status: "withdrawn" }), ["j1"]);
  assert.deepEqual(jobsToRecount({ jobId: "j1", status: "withdrawn" }, { jobId: "j1", status: "pending" }), ["j1"]);
  assert.deepEqual(jobsToRecount({ jobId: "j1", status: "pending" }, { jobId: "j1", status: "rejected" }), [], "still counted");
  assert.deepEqual(jobsToRecount({ jobId: "j1", status: "pending" }, undefined), ["j1"], "deleted by staff");
  assert.deepEqual(jobsToRecount(undefined, { status: "pending" }), [], "no job id");
});

test("recount sets the true number, ignoring withdrawn proposals and any forged value", async () => {
  const db = fakeDb({
    jobs: { j1: { totalProposals: 999 } },
    proposals: {
      j1_a: { jobId: "j1", status: "pending" },
      j1_b: { jobId: "j1", status: "rejected" },
      j1_c: { jobId: "j1", status: "withdrawn" },
      j2_a: { jobId: "j2", status: "pending" },
    },
  });
  assert.equal(await recountJobProposals(db, "j1"), 2);
  assert.equal(db.data.jobs.j1.totalProposals, 2);
});

test("retries and duplicate events never inflate the count", async () => {
  const db = fakeDb({ jobs: { j1: { totalProposals: 0 } }, proposals: { j1_a: { jobId: "j1", status: "pending" } } });
  for (let i = 0; i < 5; i++) await recountJobProposals(db, "j1");
  assert.equal(db.data.jobs.j1.totalProposals, 1);
  assert.equal(db.writes.length, 1, "unchanged counts are not rewritten");
});

test("a missing job is skipped", async () => {
  const db = fakeDb({ proposals: { gone_a: { jobId: "gone", status: "pending" } } });
  assert.equal(await recountJobProposals(db, "gone"), null);
  assert.equal(db.writes.length, 0);
});

test("filling a job closes only the proposals still pending, once", async () => {
  assert.equal(jobJustFilled({ status: "open" }, { status: "assigned" }), true);
  assert.equal(jobJustFilled({ status: "open" }, { status: "cancelled" }), false, "closing keeps proposals for a reopen");
  assert.equal(jobJustFilled({ status: "assigned" }, { status: "in_progress" }), false);

  const db = fakeDb({
    proposals: {
      j1_hired: { jobId: "j1", status: "accepted" },
      j1_late: { jobId: "j1", status: "pending" },
      j1_gone: { jobId: "j1", status: "withdrawn" },
      j1_no: { jobId: "j1", status: "rejected", closedReason: "client" },
    },
  });
  assert.equal(await closePendingProposals(db, "j1"), 1);
  assert.equal(db.data.proposals.j1_late.status, "rejected");
  assert.equal(db.data.proposals.j1_late.closedReason, "filled");
  assert.equal(db.data.proposals.j1_hired.status, "accepted");
  assert.equal(db.data.proposals.j1_no.closedReason, "client");
  assert.equal(await closePendingProposals(db, "j1"), 0, "running again changes nothing");
});

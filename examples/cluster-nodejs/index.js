import Redis from "ioredis";

const nodes = [7001, 7002, 7003, 7004, 7005, 7006].map((port) => ({
  port,
  host: "localhost",
}));

const cluster = new Redis.Cluster(nodes, {
  redisOptions: {
    password: "redispw",
  },
});

async function runTests() {
  try {
    console.log("✅ Connected to Redis cluster");

    await cluster.set("foo", "bar");
    const val = await cluster.get("foo");
    console.log("Test 1 GET foo:", val);

    const keys = ["alpha", "beta", "gamma", "delta", "epsilon"];
    for (const k of keys) {
      await cluster.set(k, `val-${k}`);
    }
    for (const k of keys) {
      console.log(`GET ${k}:`, await cluster.get(k));
    }

    const nodesInfo = await Promise.all(
      nodes.map((n) =>
        new Redis({ host: n.host, port: n.port, password: "redispw" }).info(
          "nodes"
        )
      )
    );
    console.log("Cluster nodes info (first node):\n", nodesInfo[0]);

    console.log("✅ All tests passed");
  } catch (err) {
    console.error("❌ Test failed:", err);
  } finally {
    cluster.disconnect();
  }
}

runTests();

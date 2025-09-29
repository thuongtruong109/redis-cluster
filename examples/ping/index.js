import Redis from "ioredis";

const nodes = [
  { host: "127.0.0.1", port: 6379 },
  { host: "127.0.0.1", port: 6380 },
  { host: "127.0.0.1", port: 6381 },
];

async function main() {
  for (const node of nodes) {
    const client = new Redis(node.port, node.host, { password: "redispw" });
    try {
      console.log(`🔌 Connecting to ${node.host}:${node.port}`);
      const pong = await client.ping();
      console.log(`✅ ${node.host}:${node.port} PONG=${pong}`);
      const info = await client.info();
      console.log(`ℹ️ ${node.host}:${node.port} INFO:\n`, info);
    } catch (err) {
      console.error(`❌ ${node.host}:${node.port} error`, err);
    } finally {
      client.disconnect();
    }
  }
}

main();

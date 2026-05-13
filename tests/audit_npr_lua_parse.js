const fs = require("fs");
const path = require("path");

const luaparse = require("../.npm-cache/_npx/987278021a42eeb8/node_modules/luaparse");

const roots = [
  "CooldownReminder/Core",
  "CooldownReminder/Data",
  "CooldownReminder/UI",
  "CooldownReminder/Runtime",
];

let failures = 0;
let files = 0;

for (const root of roots) {
  for (const name of fs.readdirSync(root)) {
    if (!name.endsWith(".lua")) {
      continue;
    }

    const fullPath = path.join(root, name);
    const source = fs.readFileSync(fullPath, "utf8");
    files += 1;

    try {
      luaparse.parse(source, { luaVersion: "5.1" });
      console.log("PARSE_OK", fullPath);
    } catch (error) {
      failures += 1;
      console.log("PARSE_FAIL", fullPath, error.message);
    }
  }
}

console.log("SUMMARY", files, "files", failures, "failures");

if (failures > 0) {
  process.exitCode = 1;
}

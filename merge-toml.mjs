#!/usr/bin/env node
"use strict";

import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const DEFAULT_OUT = "config.toml";
const DEFAULT_INPUTS = ["base.toml", "vim.keymapping.toml"];

const argv = process.argv.slice(2);

const parseArgs = (args) =>
  args.reduce(
    (acc, arg, i, arr) =>
      arg === "--out"
        ? { ...acc, out: arr[i + 1] ?? acc.out }
        : { ...acc, files: acc.files.concat(arg) },
    { out: DEFAULT_OUT, files: [] }
  );

const { out, files } = parseArgs(argv);
const inputs = files.length ? files : DEFAULT_INPUTS;

const isTableHeader = (s) =>
  s.startsWith("[") && s.endsWith("]") && !s.startsWith("[[");

const isArrayTableHeader = (s) => s.startsWith("[[") && s.endsWith("]]");

const parseKey = (line) => {
  let inQuote = false;
  let escape = false;
  for (let i = 0; i < line.length; i += 1) {
    const ch = line[i];
    if (escape) {
      escape = false;
      continue;
    }
    if (ch === "\\") {
      escape = true;
      continue;
    }
    if (ch === "\"") {
      inQuote = !inQuote;
      continue;
    }
    if (!inQuote && ch === "=") return line.slice(0, i).trim();
  }
  return null;
};

const ensureTable = (state, name) => {
  if (!state.tables.has(name)) {
    state.tables.set(name, { lines: [], keyIndex: new Map() });
    state.order.push(name);
  }
  return state.tables.get(name);
};

const addLine = (state, tableName, line) => {
  const table = ensureTable(state, tableName);
  table.lines.push(line);
  return state;
};

const addKeyLine = (state, tableName, key, line) => {
  const table = ensureTable(state, tableName);
  const existing = table.keyIndex.get(key);
  if (existing !== undefined) {
    table.lines[existing] = line;
    return state;
  }
  table.keyIndex.set(key, table.lines.length);
  table.lines.push(line);
  return state;
};

const mergeLines = (state, lines) =>
  lines.reduce(
    (acc, line) => {
      const trimmed = line.trim();
      if (trimmed === "" || trimmed.startsWith("#")) {
        addLine(acc, acc.current, line);
        return acc;
      }
      if (isArrayTableHeader(trimmed)) {
        throw new Error(`Array tables are not supported: ${trimmed}`);
      }
      if (isTableHeader(trimmed)) {
        acc.current = trimmed.slice(1, -1).trim();
        ensureTable(acc, acc.current);
        return acc;
      }
      const key = parseKey(line);
      return key
        ? (addKeyLine(acc, acc.current, key, line), acc)
        : (addLine(acc, acc.current, line), acc);
    },
    state
  );

const readFileLines = (file) => {
  const filePath = path.resolve(process.cwd(), file);
  if (!fs.existsSync(filePath)) {
    console.warn(`Warning: File ${file} not found, skipping...`);
    return [];
  }
  return fs.readFileSync(filePath, "utf8").split(/\r?\n/);
};

const initState = () => ({ tables: new Map(), order: [], current: "" });

const state = inputs.reduce(
  (acc, file) => mergeLines(acc, readFileLines(file)),
  initState()
);

const toOutputLines = ({ tables, order }) =>
  order.flatMap((name) => {
    const table = tables.get(name);
    const hasContent = table.lines.some((l) => l.trim() !== "");
    if (!hasContent) return [];
    const header = name ? [`[${name}]`] : [];
    return [...header, ...table.lines, ""];
  });

const output = toOutputLines(state).join("\n");
fs.writeFileSync(path.resolve(process.cwd(), out), output, "utf8");

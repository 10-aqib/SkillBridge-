import Database, { Database as DatabaseType } from 'better-sqlite3';
import path from 'path';
import fs from 'fs';

const DB_PATH = path.join(__dirname, '../../skillbridge.db');
const SCHEMA_PATH = path.join(__dirname, 'schema.sql');

const db: DatabaseType = new Database(DB_PATH);

// Enable WAL mode for better performance
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

// Initialize schema
const schema = fs.readFileSync(SCHEMA_PATH, 'utf-8');
db.exec(schema);

export default db;

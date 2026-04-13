// MongoDB initialization script – runs once on first container start
// This script seeds the 'fruits' collection in the 'octopusdb' database.

db = db.getSiblingDB('octopusdb');

// Create a limited read-only user for the application
db.createUser({
  user: process.env.MONGO_APP_USER || 'appuser',
  pwd: process.env.MONGO_APP_PASSWORD || 'changeme',
  roles: [{ role: 'readWrite', db: 'octopusdb' }],
});

// Drop and recreate collection to ensure idempotency
db.fruits.drop();

db.fruits.insertMany([
  { _id: 1, name: 'apples',   qty: 5, rating: 3 },
  { _id: 2, name: 'bananas',  qty: 7, rating: 1, microsieverts: 0.1 },
  { _id: 3, name: 'oranges',  qty: 6, rating: 2 },
  { _id: 4, name: 'avocados', qty: 3, rating: 5 },
]);

print('✅  Seeded fruits collection with', db.fruits.countDocuments(), 'documents.');

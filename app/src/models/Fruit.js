'use strict';

const mongoose = require('mongoose');

const fruitSchema = new mongoose.Schema(
  {
    _id: { type: Number, required: true },
    name: { type: String, required: true, trim: true },
    qty: { type: Number, required: true, min: 0 },
    rating: { type: Number, required: true, min: 1, max: 5 },
    microsieverts: { type: Number, default: null },
  },
  { _id: false }
);

module.exports = mongoose.model('Fruit', fruitSchema, 'fruits');

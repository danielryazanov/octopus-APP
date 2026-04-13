'use strict';

const express = require('express');
const Fruit = require('../models/Fruit');

const router = express.Router();

// GET /api/fruits – return all fruits
router.get('/', async (_req, res, next) => {
  try {
    const fruits = await Fruit.find().lean();
    res.json(fruits);
  } catch (err) {
    next(err);
  }
});

// GET /api/fruits/:name – return a specific fruit by name
router.get('/:name', async (req, res, next) => {
  try {
    const fruit = await Fruit.findOne({
      name: req.params.name.toLowerCase(),
    }).lean();
    if (!fruit) return res.status(404).json({ error: 'Fruit not found' });
    return res.json(fruit);
  } catch (err) {
    return next(err);
  }
});

module.exports = router;

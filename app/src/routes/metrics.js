'use strict';

const express = require('express');

const router = express.Router();

// GET /metrics – Prometheus scrape endpoint
router.get('/', async (req, res, next) => {
  try {
    const register = req.app.locals.register;
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
  } catch (err) {
    next(err);
  }
});

module.exports = router;

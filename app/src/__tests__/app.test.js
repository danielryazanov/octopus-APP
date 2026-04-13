'use strict';

const request = require('supertest');

// Mock mongoose before requiring the app
jest.mock('mongoose', () => {
  const actual = jest.requireActual('mongoose');
  return {
    ...actual,
    connect: jest.fn().mockResolvedValue({}),
    connection: { close: jest.fn().mockResolvedValue({}) },
    model: actual.model.bind(actual),
    Schema: actual.Schema,
  };
});

// Mock the Fruit model
jest.mock('../models/Fruit', () => {
  const fruits = [
    { _id: 1, name: 'apples', qty: 5, rating: 3 },
    { _id: 2, name: 'bananas', qty: 7, rating: 1, microsieverts: 0.1 },
    { _id: 3, name: 'oranges', qty: 6, rating: 2 },
    { _id: 4, name: 'avocados', qty: 3, rating: 5 },
  ];
  return {
    find: jest.fn().mockReturnValue({ lean: jest.fn().mockResolvedValue(fruits) }),
    findOne: jest.fn().mockImplementation(({ name }) => ({
      lean: jest.fn().mockResolvedValue(
        fruits.find(f => f.name === name) || null
      ),
    })),
  };
});

const { app } = require('../index');

describe('GET /healthz', () => {
  it('returns 200 OK', async () => {
    const res = await request(app).get('/healthz');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});

describe('GET /api/fruits', () => {
  it('returns all fruits', async () => {
    const res = await request(app).get('/api/fruits');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body).toHaveLength(4);
  });

  it('includes apples with qty 5', async () => {
    const res = await request(app).get('/api/fruits');
    const apple = res.body.find(f => f.name === 'apples');
    expect(apple).toBeDefined();
    expect(apple.qty).toBe(5);
  });
});

describe('GET /api/fruits/:name', () => {
  it('returns a single fruit by name', async () => {
    const res = await request(app).get('/api/fruits/apples');
    expect(res.status).toBe(200);
    expect(res.body.name).toBe('apples');
    expect(res.body.qty).toBe(5);
    expect(res.body.rating).toBe(3);
  });

  it('returns 404 for unknown fruit', async () => {
    const res = await request(app).get('/api/fruits/durian');
    expect(res.status).toBe(404);
  });
});

describe('GET /metrics', () => {
  it('returns Prometheus metrics', async () => {
    const res = await request(app).get('/metrics');
    expect(res.status).toBe(200);
    expect(res.text).toMatch(/# HELP/);
  });
});

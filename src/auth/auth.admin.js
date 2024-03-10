import { Router } from 'express';
const { generateAccessToken } = require('../helpers/jwt.js');
const bcryptjs = require('bcryptjs');
const crypto = require('crypto');
const respond = require('../helpers/response.js');

const router = Router();

router.post('/register', async (req, res) => {
    const { register_admin } = await import('../helpers/db.handler.js');
    const { update_refresh_token } = await import('../helpers/db.handler.js');

    let body = req.body;
    if (!body || !body.email || !body.password || !body.role) {
        respond(req, res, { error: 'Invalid request' }, null, 400);
        return;
    }

    // validate email
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(body.email)) {
        respond(req, res, { error: 'Invalid email' }, null, 400);
        return;
    }

    // validate password
    let password_regex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{8,}$/;
    if (!password_regex.test(body.password)) {
        respond(
            req,
            res,
            {
                error: 'Password must contain at least 1 capital letter, 1 small letter, 1 number, and at least 8 characters long',
            },
            null,
            400
        );
        return;
    }

    // validate role
    if (!['senior', 'medior', 'junior'].includes(body.role)) {
        respond(req, res, { error: 'Invalid role' }, null, 400);
        return;
    }

    let email = body.email;
    let password = body.password;
    let role = body.role;

    password = bcryptjs.hashSync(password, 10);

    let status = await register_admin(email, password, role);

    if (!status[0]) {
        respond(req, res, { error: 'Email already exists' }, null, 409);
        return;
    }

    const admin_id = status[1];
    const token = generateAccessToken({ admin_id: admin_id, role: 'admin' });

    const refresh_token = crypto.randomBytes(16).toString('hex');
    await update_refresh_token(admin_id, refresh_token, 'ADMIN');

    respond(req, res, { token: token, refresh_token: refresh_token }, 'auth');
});

router.post('/login', async (req, res) => {
    const { retrieve_password_hash_admin } = await import(
        '../helpers/db.handler.js'
    );
    const { update_refresh_token } = await import('../helpers/db.handler.js');

    let body = req.body;
    if (!body || !body.email || !body.password) {
        respond(req, res, { error: 'Invalid request' }, null, 400);
        return;
    }

    let email = body.email;
    let password = body.password;

    let db_entry = await retrieve_password_hash_admin(email);
    if (!db_entry[0]) {
        respond(req, res, { error: 'Invalid credentials' }, null, 401);
        return;
    }

    let db_password = db_entry[1];

    let status = bcryptjs.compareSync(password, db_password);
    if (!status) {
        respond(req, res, { error: 'Invalid credentials' }, null, 401);
        return;
    }

    let admin_id = Number(db_entry[2]);

    const token = generateAccessToken({ admin_id: admin_id, role: 'admin' });

    const refresh_token = crypto.randomBytes(16).toString('hex');
    await update_refresh_token(admin_id, refresh_token, 'ADMIN');

    respond(req, res, { token: token, refresh_token: refresh_token }, 'auth');
});

router.post('/refresh', async (req, res) => {
    const { retrieve_entity_by_refresh_token, update_refresh_token } =
        await import('../helpers/db.handler.js');

    let body = req.body;
    if (!body || !body.refresh_token) {
        respond(req, res, { error: 'Invalid request' }, null, 400);
        return;
    }

    let token = body.refresh_token;
    let status = await retrieve_entity_by_refresh_token(token, 'ADMIN');

    if (!status[0]) {
        respond(req, res, { error: 'Invalid token' }, null, 401);
        return;
    }

    let admin_id = status[1];

    let jwt_token = generateAccessToken({ admin_id: admin_id, role: 'admin' });
    let refresh_token = crypto.randomBytes(16).toString('hex');
    await update_refresh_token(admin_id, refresh_token, 'ADMIN');

    respond(
        req,
        res,
        { token: jwt_token, refresh_token: refresh_token },
        'auth'
    );
});

export default router;

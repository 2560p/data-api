import { Router } from 'express';
const { generateAccessToken, decodeAccessToken } = require('../helpers/jwt.js');
const bcryptjs = require('bcryptjs');
const crypto = require('crypto');
const respond = require('../helpers/response.js');

const router = Router();

// test code, TODO: remove
router.get('/viewToken', (req, res) => {
    let token = req.headers.authorization.split(' ')[1];

    if (!token) {
        res.status(400).send('Invalid request');
        return;
    }

    res.json({ data: decodeAccessToken(token) });
});

router.post('/register', async (req, res) => {
    const { register_user } = await import('../helpers/db.handler.js');
    const { update_refresh_token } = await import('../helpers/db.handler.js');

    let body = req.body;
    if (!body || !body.email || !body.password) {
        respond(req, res, { error: 'Invalid request' }, null, 400);
        return;
    }

    // validate email
    let email_regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!email_regex.test(body.email)) {
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

    let email = body.email;
    let password = body.password;
    password = bcryptjs.hashSync(password, 10);

    let status = await register_user(email, password);

    if (!status[0]) {
        respond(req, res, { error: 'Email already exists' }, null, 409);
        return;
    }

    let user_id = Number(status[1]);

    const token = generateAccessToken({
        user_id: user_id,
        role: 'user',
    });

    const refresh_token = crypto.randomBytes(16).toString('hex');
    await update_refresh_token(user_id, refresh_token, 'USER');

    respond(req, res, { token: token, refresh_token: refresh_token }, 'auth');
});

router.post('/login', async (req, res) => {
    const { retrieve_password_hash_user } = await import(
        '../helpers/db.handler.js'
    );
    const { update_refresh_token } = await import('../helpers/db.handler.js');

    let body = req.body;
    if (!body || !body.email || !body.password) {
        respond(req, res, { error: 'Invalid request' }, null, 400);
        return;
    }

    let email = body.email;
    let db_password = await retrieve_password_hash_user(email);

    if (!db_password[0]) {
        respond(req, res, { error: 'Invalid credentials' }, null, 401);
        return;
    }

    let status = bcryptjs.compareSync(body.password, db_password[1]);

    if (!status) {
        respond(req, res, { error: 'Invalid credentials' }, null, 401);
        return;
    }

    let user_id = Number(db_password[2]);

    const token = generateAccessToken({ user_id: user_id, role: 'user' });

    const refresh_token = crypto.randomBytes(16).toString('hex');
    await update_refresh_token(user_id, refresh_token, 'USER');

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
    let status = await retrieve_entity_by_refresh_token(token, 'USER');

    if (!status[0]) {
        respond(req, res, { error: 'Invalid token' }, null, 401);
        return;
    }

    let admin_id = status[1];

    let jwt_token = generateAccessToken({ user_id: admin_id, role: 'user' });
    let refresh_token = crypto.randomBytes(16).toString('hex');
    await update_refresh_token(admin_id, refresh_token, 'USER');

    respond(
        req,
        res,
        { token: jwt_token, refresh_token: refresh_token },
        'auth'
    );
});

export default router;

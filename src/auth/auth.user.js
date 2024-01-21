import { Router } from 'express';
const { generateAccessToken, decodeAccessToken } = require('../helpers/jwt.js');
const bcryptjs = require('bcryptjs');

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

    let body = req.body;
    if (!body || !body.email || !body.password) {
        res.status(400).send('Invalid request');
        return;
    }
    let email = body.email;
    let password = body.password;
    password = bcryptjs.hashSync(password, 10);

    let status = await register_user(email, password);

    if (!status[0]) {
        res.status(400).send('User already exists');
        return;
    }

    const token = generateAccessToken({ user_id: Number(status[1]) });
    res.json({ token: token });
});

router.post('/login', async (req, res) => {
    const { retrieve_password_hash_user } = await import(
        '../helpers/db.handler.js'
    );

    let body = req.body;
    if (!body || !body.email || !body.password) {
        res.status(400).send('Invalid request');
        return;
    }
    let email = body.email;
    let db_password = await retrieve_password_hash_user(email);

    if (!db_password[0]) {
        res.status(400).send('Invalid credentials');
        return;
    }

    let status = bcryptjs.compareSync(body.password, db_password[1]);

    if (!status) {
        res.status(400).send('Invalid credentials');
        return;
    }

    const token = generateAccessToken({ user_id: Number(db_password[2]) });
    res.json({ token: token });
});

export default router;

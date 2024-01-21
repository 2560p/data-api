import { Router } from 'express';
const { generateAccessToken } = require('../helpers/jwt.js');
const bcryptjs = require('bcryptjs');

const router = Router();

// this is a special route.
// it can't be accessed by normal users nor admins.
// to use this one, read the README section on registering an admin.
router.post('/register', async (req, res) => {
    const authHeader = req.headers['authorization'];
    const auth_token = authHeader && authHeader.split(' ')[1];

    if (!auth_token) {
        res.status(401).send('no auth token');
        return;
    }

    if (auth_token !== process.env.admin_key) {
        res.status(403).send('invalid auth token');
        return;
    }

    const { register_admin } = await import('../helpers/db.handler.js');

    let body = req.body;
    if (!body || !body.email || !body.password || !body.role) {
        res.status(400).send('Invalid request');
        return;
    }
    let email = body.email;
    let password = body.password;
    let role = body.role;

    password = bcryptjs.hashSync(password, 10);

    let status = await register_admin(email, password, role);

    if (!status[0]) {
        res.status(400).send('Admin already exists');
        return;
    }

    const token = generateAccessToken({ admin_id: Number(status[1]) });
    res.json({ token: token });
});

router.post('/login', async (req, res) => {
    const { retrieve_password_hash_admin } = await import(
        '../helpers/db.handler.js'
    );

    let body = req.body;
    if (!body || !body.email || !body.password) {
        res.status(400).send('Invalid request');
        return;
    }
    let email = body.email;
    let db_password = await retrieve_password_hash_admin(email);

    if (!db_password[0]) {
        res.status(400).send('Invalid credentials');
        return;
    }

    let status = bcryptjs.compareSync(body.password, db_password[1]);

    if (!status) {
        res.status(400).send('Invalid credentials');
        return;
    }

    const token = generateAccessToken({ admin_id: Number(db_password[2]) });
    res.json({ token: token });
});

export default router;

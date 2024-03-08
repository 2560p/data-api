const { verifyAccessToken, decodeAccessToken } = require('../helpers/jwt.js');

export function auth_middleware(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        res.status(401).send('Unauthorized');
        return;
    }

    if (!verifyAccessToken(token)) {
        res.status(403).send('invalid auth token');
        return;
    }

    next();
}

export function require_admin(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        res.status(401).send('Unauthorized');
        return;
    }

    if (!verifyAccessToken(token)) {
        res.status(401).send('Unauthorized');
        return;
    }

    let decoded = decodeAccessToken(token);

    if (decoded.role !== 'admin') {
        res.status(403).send('Forbidden');
        return;
    }

    next();
}

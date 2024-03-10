const { verifyAccessToken, decodeAccessToken } = require('../helpers/jwt.js');
const respond = require('../helpers/response.js');

export function auth_middleware(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        respond(req, res, { error: 'Unauthorized' }, null, 401);
        return;
    }

    if (!verifyAccessToken(token)) {
        respond(req, res, { error: 'Unauthorized' }, null, 403);
        return;
    }

    next();
}

export function require_admin(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        respond(req, res, { error: 'Unauthorized' }, null, 401);
        return;
    }

    if (!verifyAccessToken(token)) {
        respond(req, res, { error: 'Unauthorized' }, null, 401);
        return;
    }

    let decoded = decodeAccessToken(token);

    if (decoded !== null && decoded['role'] !== 'admin') {
        respond(req, res, { error: 'Forbidden' }, null, 403);
        return;
    }

    next();
}

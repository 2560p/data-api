const { verifyAccessToken } = require('../helpers/jwt.js');

function auth_middleware(req, res, next) {
    const authHeader = req.headers["authorization"];
    const token = authHeader && authHeader.split(" ")[1];

    if (!token) {
        res.status(401).send("no auth token");
        return;
    }

    if (!verifyAccessToken(token)) {
        res.status(403).send("invalid auth token");
        return;
    }

    next();
}

export default auth_middleware;

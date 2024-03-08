const sign = require('jsonwebtoken').sign;
const verify = require('jsonwebtoken').verify;

// we can safely assign a variable here because
// .env is checked in the helpers/env.js
const jwt_secret = process.env.jwt_secret;

function generateAccessToken(data) {
    let token = sign(data, jwt_secret, { expiresIn: 60 * 30 });
    return token;
}

function verifyAccessToken(token) {
    let success = true;
    verify(token, jwt_secret, (err) => {
        if (err) {
            success = false;
        }
    });

    return success;
}

function decodeAccessToken(token) {
    let decoded = null;
    verify(token, jwt_secret, (err, decodedToken) => {
        if (!err) {
            decoded = decodedToken;
        }
    });

    return decoded;
}

module.exports = { generateAccessToken, verifyAccessToken, decodeAccessToken };

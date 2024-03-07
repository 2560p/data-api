const sign = require('jsonwebtoken').sign;
const verify = require('jsonwebtoken').verify;

const jwt_secret = process.env.jwt_secret;
if (!jwt_secret) {
    console.error('FATAL ERROR: jwt_secret is not found in .env file.');
    process.exit(1);
}

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
    let decoded = 'no_info';
    verify(token, jwt_secret, (err, decodedToken) => {
        if (!err) {
            decoded = decodedToken;
        }
    });

    return decoded;
}

module.exports = { generateAccessToken, verifyAccessToken, decodeAccessToken };

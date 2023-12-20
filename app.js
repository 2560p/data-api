import express from 'express';
import { Router } from 'express';

import users from './src/users.js';
import auth from './src/auth/auth.router.js';
import protected_route from './src/protected_route.js';

const { sql } = await import('./src/helpers/db.handler.js');
import env_check from './src/helpers/env.js';

// dev requirement for the openapi documentation
import expressOasGenerator from 'express-oas-generator';

try {
    await sql`select 1`;
} catch (err) {
    console.error('Could not connect to database. Exiting...');
    process.exit(1);
}

env_check();

const port = process.env.port;
const app = express();
app.use(express.json());
expressOasGenerator.handleResponses(app, {});

const router = Router();

router.use('/auth', auth);

router.use('/users', users);
router.use('/protected', protected_route);

app.use(router);

app.get('/', (req, res) => {
    res.send('Hello World!');
});

expressOasGenerator.handleRequests();

// try to listen on port 8080, if it fails, notify the user that the port is already in use
try {
    app.listen(port, () => {
        console.log(`Listening on port ${port}...`);
    });
} catch (err) {
    console.error(`Could not listen on port ${port}. Is it already in use?`);
    process.exit(1);
}

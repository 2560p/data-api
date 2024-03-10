import { Router } from 'express';
import { auth_middleware } from '../auth/auth.middleware';
import { sql } from '../helpers/db.handler';
const respond = require('../helpers/response.js');

const router = Router();

// get requests
router.get('/', auth_middleware, async (req, res) => {
    let profiles = await sql`select * from profiles`;
    res.status(200).json(profiles);
});

router.get('/:id', auth_middleware, async (req, res) => {
    let id = parseInt(req.params.id);

    if (!Number.isInteger(id)) {
        respond(req, res, { error: 'Invalid id' }, null, 400);
        return;
    }

    let profiles = await sql`select * from profiles where id = ${id}`;

    if (profiles.length === 0) {
        respond(req, res, { error: 'No profile found' }, null, 404);
        return;
    }

    respond(req, res, media[0], 'profile');
});

// post request
router.post('/', auth_middleware, async (req, res) => {
    let body = req.body;

    if (
        !body ||
        !body.user_id ||
        !body.name ||
        !body.birthdate ||
        !body.photo
    ) {
        respond(req, res, { error: 'Invalid request' }, null, 400);
        return;
    }

    let { user_id, name, birthdate, photo } = body;

    // check if user exists
    let user_check = await sql`select 1 from users where id = ${user_id}`;
    if (user_check.length === 0) {
        respond(req, res, { error: 'User not found' }, null, 404);
        return;
    }

    // regex to check that birthdate follows the format YYYY-MM-DD
    let birthdate_regex = /^\d{4}-\d{2}-\d{2}$/;

    if (isNaN(Date.parse(birthdate)) && !birthdate.match(birthdate)) {
        respond(req, res, { error: 'Invalid birthdate' }, null, 400);
        return;
    }

    let profile_id = null;

    try {
        profile_id = await sql`
                            insert into profiles (user_id, name, birthdate, photo)
                            values (${user_id}, ${name}, ${birthdate}, ${photo})
                            returning id
                        `;
    } catch (error) {
        if (error.message == 'Cannot exceed 4 profiles per user.') {
            respond(
                req,
                res,
                { error: 'Cannot exceed 4 profiles per user.' },
                null,
                409
            );
            return;
        }
        respond(req, res, { error: 'Internal server error' }, null, 500);
        return;
    }

    respond(
        req,
        res,
        {
            message: 'Profile created successfully',
            user_id: user_id,
            profile_id: profile_id[0].id,
        },
        'profile'
    );
});

// put request
router.put('/:id', auth_middleware, async (req, res) => {
    let id = parseInt(req.params.id);
    let body = req.body;

    if (!Number.isInteger(id)) {
        respond(req, res, { error: 'Invalid id' }, null, 400);
        return;
    }

    if (!body && !body.name && !body.birthdate && !body.photo) {
        respond(req, res, { error: 'Invalid request' }, null, 400);
        return;
    }

    let profile = {
        name: body.name,
        birthdate: body.birthdate,
        photo: body.photo,
    };

    let keys = Object.keys(profile).filter((key) => profile[key] !== undefined);

    let birthdate_regex = /^\d{4}-\d{2}-\d{2}$/;
    if (
        profile.birthdate !== undefined &&
        isNaN(Date.parse(profile.birthdate)) &&
        !profile.birthdate.match(birthdate_regex)
    ) {
        respond(req, res, { error: 'Invalid birthdate' }, null, 400);
        return;
    }

    try {
        let status = await sql`
                    update profiles
                    set ${sql(profile, keys)}
                    where id = ${id}
                    returning 1
                `;
        if (status.length === 0) {
            respond(req, res, { error: 'Profile not found' }, null, 404);
            return;
        }
    } catch (error) {
        console.log(error);
        respond(req, res, { error: 'Internal server error' }, null, 500);
        return;
    }

    respond(
        req,
        res,
        { message: 'Profile updated successfully', id: id },
        'success'
    );
});

// delete request
router.delete('/:id', auth_middleware, async (req, res) => {
    let id = parseInt(req.params.id);
    if (!Number.isInteger(id)) {
        respond(req, res, { error: 'Invalid id' }, null, 400);
        return;
    }

    let profile_check = await sql`select 1 from profiles where id = ${id}`;

    if (profile_check.length === 0) {
        respond(req, res, { error: 'Profile not found' }, null, 404);
        return;
    }

    await sql`delete from profiles where id = ${id}`;

    respond(
        req,
        res,
        { message: 'Profile deleted successfully', id: id },
        'success'
    );
});

export default router;

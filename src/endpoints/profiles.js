import { Router } from 'express';
import { auth_middleware, require_admin } from '../auth/auth.middleware';
import { sql } from '../helpers/db.handler';
const respond = require('../helpers/response.js');

const router = Router();

// get requests
router.get('/', auth_middleware, require_admin, async (req, res) => {
    let profiles = await sql`select * from profiles`;
    res.status(200).json(profiles);
});

router.get('/:id', auth_middleware, require_admin, async (req, res) => {
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
router.post('/', auth_middleware, require_admin, async (req, res) => {
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
router.put('/:id', auth_middleware, require_admin, async (req, res) => {
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
router.delete('/:id', auth_middleware, require_admin, async (req, res) => {
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

// currently_watched requests

// get request
router.get(
    '/:id/currently_watched',
    auth_middleware,
    require_admin,
    async (req, res) => {
        let id = parseInt(req.params.id);

        if (!Number.isInteger(id)) {
            respond(req, res, { error: 'Invalid id' }, null, 400);
            return;
        }

        // check if profile exists
        let profile_check = await sql`select 1 from profiles where id = ${id}`;
        if (profile_check.length === 0) {
            respond(req, res, { error: 'Profile not found' }, null, 404);
            return;
        }

        let currently_watched = await sql`select 
                    media_id, progress_seconds, last_watched 
                    from currently_watched
                    where profile_id = ${id}
                    `;

        if (currently_watched.length === 0) {
            respond(
                req,
                res,
                { error: 'No currently watched media found' },
                null,
                404
            );
            return;
        }

        respond(req, res, currently_watched, 'currently_watched_media');
    }
);

// put request
router.put(
    '/:id/currently_watched/:media_id',
    auth_middleware,
    require_admin,
    async (req, res) => {
        let profile_id = parseInt(req.params.id);
        let media_id = parseInt(req.params.media_id);
        let body = req.body;

        if (!Number.isInteger(profile_id) || !Number.isInteger(media_id)) {
            respond(req, res, { error: 'Invalid id' }, null, 400);
            return;
        }

        if (!body || !body.progress_seconds) {
            respond(req, res, { error: 'Invalid request' }, null, 400);
            return;
        }

        let { progress_seconds, last_watched } = body;

        // if no last_watched is provided, use the current datetime
        if (last_watched !== undefined) {
            // last_watched should be a valid datetime in format YYYY-MM-DD HH:MM:SS
            let last_watched_regex = /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/;

            if (
                !last_watched.match(last_watched_regex) ||
                isNaN(Date.parse(last_watched))
            ) {
                respond(req, res, { error: 'Invalid request' }, null, 400);
                return;
            }
        } else {
            // this also has to follow the datetime regex
            last_watched = new Date()
                .toISOString()
                .slice(0, 19)
                .replace('T', ' ');
        }

        // progress_seconds should be a positive integer
        if (!Number.isInteger(progress_seconds) || progress_seconds < 0) {
            respond(req, res, { error: 'Invalid request' }, null, 400);
            return;
        }

        let profile_check =
            await sql`select 1 from profiles where id = ${profile_id}`;
        if (profile_check.length === 0) {
            respond(req, res, { error: 'Profile not found' }, null, 404);
            return;
        }

        let media_check = await sql`select 1 from media where id = ${media_id}`;
        if (media_check.length === 0) {
            respond(req, res, { error: 'Media not found' }, null, 404);
            return;
        }

        // check if media is already being watched
        let currently_watched_check =
            await sql`select 1 from currently_watched where profile_id = ${profile_id} and media_id = ${media_id}`;

        if (currently_watched_check.length === 0) {
            await sql`
                insert into currently_watched (profile_id, media_id, progress_seconds, last_watched)
                values (${profile_id}, ${media_id}, ${progress_seconds}, ${last_watched})
            `;
            respond(
                req,
                res,
                { message: 'Currently watched media added' },
                'success',
                201
            );
            return;
        }

        await sql`
            update currently_watched
            set progress_seconds = ${progress_seconds}, last_watched = ${last_watched}
            where profile_id = ${profile_id} and media_id = ${media_id}
            returning 1
        `;

        respond(
            req,
            res,
            { message: 'Currently watched media updated successfully' },
            'success'
        );
    }
);

export default router;

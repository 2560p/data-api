import { Router } from 'express';
import { auth_middleware, require_admin } from '../auth/auth.middleware.js';
import { sql } from '../helpers/db.handler';
const respond = require('../helpers/response.js');

const router = Router();

router.get('/', auth_middleware, async (req, res) => {
    let media = await sql`select * from media`;
    if (media.length === 0) {
        respond(req, res, { error: 'No media found' }, null, 404);
    }
    respond(req, res, media, 'media');
});

router.get('/films', auth_middleware, async (req, res) => {
    let films = await sql`select * from media where type = 'FILM'`;
    if (films.length === 0) {
        respond(req, res, { error: 'No films found' }, null, 404);
    }
    respond(req, res, films);
});

router.get('/series', auth_middleware, async (req, res) => {
    let series = await sql`select * from media where type = 'SERIES'`;
    if (series.length === 0) {
        respond(req, res, { error: 'No series found' }, null, 404);
    }
    respond(req, res, series);
});

router.get('/:id', auth_middleware, async (req, res) => {
    try {
        const mediaId = parseInt(req.params.id);

        if (Number.isInteger(mediaId)) {
            let media = await sql`select * from media where id = ${mediaId}`;

            if (media.length === 0) {
                respond(req, res, { error: 'Media not found' }, null, 404);
            } else {
                respond(req, res, media[0], 'media');
            }
        } else {
            respond(
                req,
                res,
                { error: 'Invalid ID. Please provide a valid integer ID.' },
                null,
                400
            );
        }
    } catch (error) {
        console.error(error);
        respond(req, res, { error: 'Internal Server Error' }, null, 500);
    }
});

router.post('/films', auth_middleware, async (req, res) => {
    let body = req.body;

    if (
        !body ||
        !body.title ||
        !body.description ||
        !body.poster ||
        !body.duration ||
        !body.location ||
        !body.rating ||
        !body.language_id ||
        !body.genre_id
    ) {
        respond(req, res, { error: 'Invalid request' }, null, 400);
        return;
    }

    let title = body.title;
    let description = body.description;
    let poster = body.poster;
    let duration = parseInt(body.duration);
    let location = body.location;
    let rating = parseInt(body.rating);
    let language_id = parseInt(body.language_id);
    let genre_id = parseInt(body.genre_id);

    if (
        isNaN(duration) ||
        isNaN(rating) ||
        isNaN(language_id) ||
        isNaN(genre_id)
    ) {
        respond(req, res, { error: 'Invalid request' }, null, 400);
        return;
    }

    let languages = await sql`select id from languages`;
    let genres = await sql`select id from genres`;

    if (
        languages.filter((language) => language.id === language_id).length === 0
    ) {
        respond(req, res, { error: 'Invalid language_id' }, null, 400);
        return;
    }

    if (genres.filter((genre) => genre.id === genre_id).length === 0) {
        respond(req, res, { error: 'Invalid genre_id' }, null, 400);
        return;
    }

    let id = null;
    try {
        id = await sql`
                    insert into media (title, description, poster, duration, location, rating, language_id, genre_id, type)
                    VALUES
                    (${title}, ${description}, ${poster}, ${duration}, ${location}, ${rating}, ${language_id}, ${genre_id}, 'FILM')
                    returning id`;
    } catch (error) {
        console.error(error);
        respond(req, res, { error: 'Internal Server Error' }, null, 500);
        return;
    }

    id = id[0].id;
    respond(
        req,
        res,
        { message: 'Film inserted successfully', id: id },
        'success',
        201
    );
});

router.post('/series', auth_middleware, async (req, res) => {
    let body = req.body;

    if (
        !body ||
        !body.title ||
        !body.description ||
        !body.poster ||
        !body.duration ||
        !body.location ||
        !body.rating ||
        !body.language_id ||
        !body.genre_id
    ) {
        respond(req, res, { error: 'Invalid request' }, null, 400);
        return;
    }

    let title = body.title;
    let description = body.description;
    let poster = body.poster;
    let duration = parseInt(body.duration);
    let location = body.location;
    let rating = parseInt(body.rating);
    let language_id = parseInt(body.language_id);
    let genre_id = parseInt(body.genre_id);

    if (
        isNaN(duration) ||
        isNaN(rating) ||
        isNaN(language_id) ||
        isNaN(genre_id)
    ) {
        respond(req, res, { error: 'Invalid request' }, null, 400);
        return;
    }

    let languages = await sql`select id from languages`;
    let genres = await sql`select id from genres`;

    if (
        languages.filter((language) => language.id === language_id).length === 0
    ) {
        respond(req, res, { error: 'Invalid language_id' }, null, 400);
        return;
    }

    if (genres.filter((genre) => genre.id === genre_id).length === 0) {
        respond(req, res, { error: 'Invalid genre_id' }, null, 400);
        return;
    }

    let id = null;
    try {
        id = await sql`
                    insert into media (title, description, poster, duration, location, rating, language_id, genre_id, type)
                    VALUES
                    (${title}, ${description}, ${poster}, ${duration}, ${location}, ${rating}, ${language_id}, ${genre_id}, 'SERIES')
                    returning id`;
    } catch (error) {
        console.error(error);
        respond(req, res, { error: 'Internal Server Error' }, null, 500);
        return;
    }

    id = id[0].id;
    respond(
        req,
        res,
        { message: 'Series inserted successfully', id: id },
        'success',
        201
    );
});

export default router;

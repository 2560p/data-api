import { Router } from 'express';
import { auth_middleware, require_admin } from '../auth/auth.middleware.js';
import { sql } from '../helpers/db.handler';
const respond = require('../helpers/response.js');

const router = Router();

// get requests
router.get('/', auth_middleware, async (req, res) => {
    let media = await sql`select * from media`;

    if (media.length === 0) {
        respond(req, res, { error: 'No media found' }, null, 404);
        return;
    }

    respond(req, res, media, 'media');
});

router.get('/:id', auth_middleware, async (req, res) => {
    let id = parseInt(req.params.id);

    if (!Number.isInteger(id)) {
        respond(req, res, { error: 'Invalid id' }, null, 400);
        return;
    }

    let media = await sql`select * from media where id = ${id}`;

    if (media.length === 0) {
        respond(req, res, { error: 'No media found' }, null, 404);
        return;
    }

    respond(req, res, media[0], 'media');
});

router.get('/films', auth_middleware, async (req, res) => {
    let films = await sql`select * from media where type = 'FILM'`;

    if (films.length === 0) {
        respond(req, res, { error: 'No films found' }, null, 404);
        return;
    }

    respond(req, res, films);
});

router.get('/series', auth_middleware, async (req, res) => {
    let series = await sql`select * from media where type = 'SERIES'`;

    if (series.length === 0) {
        respond(req, res, { error: 'No series found' }, null, 404);
        return;
    }

    respond(req, res, series);
});

// post requests
router.post('/films', auth_middleware, require_admin, async (req, res) => {
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
    let duration = body.duration;
    let location = body.location;
    let rating = body.rating;
    let language_id = body.language_id;
    let genre_id = body.genre_id;

    if (
        isNaN(duration) ||
        isNaN(rating) ||
        isNaN(language_id) ||
        isNaN(genre_id)
    ) {
        respond(req, res, { error: 'Invalid request' }, null, 400);
        return;
    }

    duration = parseInt(duration);
    rating = parseInt(rating);
    language_id = parseInt(language_id);
    genre_id = parseInt(genre_id);

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

router.post('/series', auth_middleware, require_admin, async (req, res) => {
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

// put request
router.put('/:id', auth_middleware, require_admin, async (req, res) => {
    let body = req.body;
    let id = parseInt(req.params.id);

    if (!body) {
        respond(req, res, { error: 'Invalid request' }, null, 400);
        return;
    }

    if (!Number.isInteger(id)) {
        respond(req, res, { error: 'Invalid id' }, null, 400);
        return;
    }

    let film = {
        title: body.title,
        description: body.description,
        poster: body.poster,
        duration: body.duration,
        location: body.location,
        rating: body.rating,
        language_id: body.language_id,
        genre_id: body.genre_id,
    };

    let keys = Object.keys(film).filter((key) => film[key] !== undefined);

    if (
        (keys.includes('duration') && isNaN(film.duration)) ||
        (keys.includes('rating') && isNaN(film.rating)) ||
        (keys.includes('language_id') && isNaN(film.language_id)) ||
        (keys.includes('genre_id') && isNaN(film.genre_id))
    ) {
        respond(req, res, { error: 'Invalid request' }, null, 400);
        return;
    }

    if (keys.includes('language_id')) {
        let languages = await sql`select id from languages`;
        if (
            languages.filter(
                (language) => language.id === parseInt(film.language_id)
            ).length === 0
        ) {
            respond(req, res, { error: 'Invalid language_id' }, null, 400);
            return;
        }
    }

    if (keys.includes('genre_id')) {
        let genres = await sql`select id from genres`;
        if (
            genres.filter((genre) => genre.id === parseInt(film.genre_id))
                .length === 0
        ) {
            respond(req, res, { error: 'Invalid genre_id' }, null, 400);
            return;
        }
    }

    try {
        let update = await sql`
                        update media
                        set ${sql(film, keys)}
                        where id = ${id}
                        returning id`;
        if (update.length === 0) {
            respond(req, res, { error: 'Film not found' }, null, 404);
            return;
        }
    } catch (error) {
        console.error(error);
        respond(req, res, { error: 'Internal Server Error' }, null, 500);
        return;
    }

    respond(
        req,
        res,
        { message: 'Media updated successfully' },
        'success',
        200
    );
});

// delete request
router.delete('/:id', auth_middleware, require_admin, async (req, res) => {
    let id = parseInt(req.params.id);
    if (!Number.isInteger(id)) {
        respond(req, res, { error: 'Invalid id' }, null, 400);
        return;
    }

    try {
        let deleted = await sql`
                        delete from media
                        where id = ${id}
                        returning id`;
        if (deleted.length === 0) {
            respond(req, res, { error: 'Media not found' }, null, 404);
            return;
        }
    } catch (error) {
        console.error(error);
        respond(req, res, { error: 'Internal Server Error' }, null, 500);
        return;
    }

    respond(
        req,
        res,
        { message: 'Media deleted successfully' },
        'success',
        200
    );
});

export default router;

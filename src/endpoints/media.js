import { Router } from 'express';
import { auth_middleware, require_admin } from '../auth/auth.middleware.js';
import { sql } from '../helpers/db.handler';
const respond = require('../helpers/response.js');

const router = Router();

router.get('/', auth_middleware, async (req, res) => {
    let media = await sql`select * from media`;
    respond(req, res, media);
});

router.get('/films', auth_middleware, async (req, res) => {
    let films = await sql`select * from media where media_type = 'FILM'`;
    respond(req, res, films);
});

router.get('/series', auth_middleware, async (req, res) => {
    let series = await sql`select * from media where media_type = 'SERIES'`;
    respond(req, res, series);
});

router.get('/:id', auth_middleware, async (req, res) => {
    try {
        const mediaId = parseInt(req.params.id);

        if (Number.isInteger(mediaId)) {
            let media = await sql`select * from media where id = ${mediaId}`;

            if (media.length === 0) {
                res.status(404).json({ error: 'Media not found' });
            } else {
                res.status(200).json(media[0]);
            }
        } else {
            res.status(400).json({
                error: 'Invalid ID. Please provide a valid integer ID.',
            });
        }
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// add a new film
router.post('/films', auth_middleware, async (req, res) => {
    try {
        let body = req.body;

        if (
            !body ||
            !body.title ||
            !body.genre ||
            !body.language ||
            !body.description ||
            !body.poster ||
            !body.duration ||
            !body.location ||
            !body.rating ||
            !body.age
        ) {
            res.status(400).send('Invalid request');
            return;
        }

        let title = body.title;
        let genre = body.genre;
        let language = body.language;
        let description = body.description;
        let poster = body.poster;
        let duration = body.duration;
        let location = body.location;
        let rating = body.rating;
        let age = body.age;

        let id = await sql`
        INSERT INTO media (title, genre, language, media_type, description, poster, duration, location, rating, age) 
        VALUES 
        (${title}, ${genre}, ${language}, 'FILM', ${description}, ${poster}, ${duration}, ${location}, ${rating}, ${age})
        returning id`;
        id = id[0].id;
        res.status(201).json({ message: 'Film inserted successfully', id: id });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

//insert series
router.post('/series', auth_middleware, async (req, res) => {
    try {
        const newSeries = req.body;
        await sql`
        INSERT INTO media (title, genre, language, media_type, description, poster, duration, location, rating, age) 
        VALUES 
        ('yes', 'maybe', 'possibly', 'SERIES', 'perhaps', 'no', 5, 'sure', 7, '12')`;
        res.status(201).json({
            message: 'Series inserted successfully',
            data: newSeries,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

export default router;

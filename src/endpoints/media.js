import { Router } from 'express';
import auth_middleware from '../auth/auth.middleware';
import { sql } from '../helpers/db.handler';

const router = Router();

router.get('/', auth_middleware, async (req, res) => {
    let media = await sql`select * from media`;
    res.status(200).json(media);
});

router.get('/films', auth_middleware, async (req, res) => {
    let films = await sql`select * from media where media_type = 'FILM'`;
    res.status(200).json(films);
});

router.get('/series', auth_middleware, async (req, res) => {
    let films = await sql`select * from media where media_type = 'SERIES'`;
    res.status(200).json(films);
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
            res.status(400).json({ error: 'Invalid ID. Please provide a valid integer ID.' });
        }
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

router.post('/films', auth_middleware, async (req, res) => {
    try {
        const newFilm = req.body;
        await sql`
        INSERT INTO media (title, genre, language, media_type, description, poster, duration, location, rating, age) 
        VALUES 
        ('a', 'b', 'c', 'FILM', 'd', 'e', 5, 'f', 7, '12')`;
        res.status(201).json({ message: 'Film inserted successfully', data: newFilm });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

router.post('/series', auth_middleware, async (req, res) => {
    try {
        const newSeries = req.body;
        await sql`
        INSERT INTO media (title, genre, language, media_type, description, poster, duration, location, rating, age) 
        VALUES 
        ('yes', 'maybe', 'possibly', 'SERIES', 'perhaps', 'no', 5, 'sure', 7, '12')`;
        res.status(201).json({ message: 'Series inserted successfully', data: newSeries });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

export default router;
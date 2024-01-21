import { Router } from 'express';
import auth_middleware from '../auth/auth.middleware';
import { sql } from '../helpers/db.handler';

const router = Router();

// most viewed
router.get('/mostViewed', auth_middleware, async (req, res) => {
    try {
        let { year, month } = req.query;

        if (!year || !month || isNaN(year) || isNaN(month)) {
            res.status(400).json({ error: 'Invalid request parameters' });
            return;
        }

        let stats = await sql`
            SELECT * FROM public.get_sorted_movies_most_viewed(${year}, ${month})
        `;
        
        res.status(200).json(stats);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// least viewed
router.get('/leastViewed', auth_middleware, async (req, res) => {
    try {
        let { year, month } = req.query;

        if (!year || !month || isNaN(year) || isNaN(month)) {
            res.status(400).json({ error: 'Invalid request parameters' });
            return;
        }

        let stats = await sql`
            SELECT * FROM public.get_sorted_movies_least_viewed(${year}, ${month})
        `;
        
        res.status(200).json(stats);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// most liked
router.get('/mostLiked', auth_middleware, async (req, res) => {
    try {
        let { year, month } = req.query;

        if (!year || !month || isNaN(year) || isNaN(month)) {
            res.status(400).json({ error: 'Invalid request parameters' });
            return;
        }

        let stats = await sql`
            SELECT * FROM public.get_sorted_movies_most_liked(${year}, ${month})
        `;
        
        res.status(200).json(stats);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// least liked
router.get('/leastLiked', auth_middleware, async (req, res) => {
    try {
        let { year, month } = req.query;

        if (!year || !month || isNaN(year) || isNaN(month)) {
            res.status(400).json({ error: 'Invalid request parameters' });
            return;
        }

        let stats = await sql`
            SELECT * FROM public.get_sorted_movies_least_liked(${year}, ${month})
        `;
        
        res.status(200).json(stats);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

export default router;

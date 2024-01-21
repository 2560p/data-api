import { Router } from 'express';
import auth_middleware from '../auth/auth.middleware';
import { sql } from '../helpers/db.handler';

const router = Router();

router.get('/', auth_middleware, async (req, res) => {
    let profiles = await sql`select * from profiles`;
    res.status(200).json(profiles);
});

export default router;
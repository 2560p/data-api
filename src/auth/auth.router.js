import auth_user from './auth.user.js';
import auth_admin from './auth.admin.js';
import { Router } from 'express';

const router = Router();

// auth
router.use('/user', auth_user);
router.use('/admin', auth_admin);

export default router;

import { Router } from 'express';
import { LogController } from '../controllers/log.controller';
import { authenticateJWT, authorizeRoles } from '../middlewares/auth.middleware';
import { UserRole } from '../constants/roles.enum';

const router = Router();

// Only ADMIN can access system audit logs
router.get('/', authenticateJWT, authorizeRoles(UserRole.ADMIN), LogController.getLogs);

export default router;
import { Router } from "express";
import auth_middleware from "./auth/auth.middleware";

const router = Router();

router.get("/", auth_middleware, (req, res) => {
    res.send("very protected route");
});

export default router;

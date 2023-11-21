import e, { Router } from "express";

const router = Router();

router.get("/", (req, res) => {
    res.send("Users are here!");
});

export default router;
